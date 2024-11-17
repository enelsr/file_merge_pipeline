#!/bin/bash

function choose_from_menu() {
    local prompt="$1" outvar="$2"
    shift
    shift
    local options=("$@") cur=0 count=${#options[@]} index=0
    local esc=$(echo -en "\033")
    printf "$prompt\n"
    COLOR_OFF='\033[0m'
    BICYAN='\033[1;96m'
    
    while true
    do
        # List all options
        index=0
        for o in "${options[@]}"
        do
            if [ "$index" == "$cur" ]
            then echo -e " ${BICYAN}> $o${COLOR_OFF}"
            else echo -e "   $o"
            fi
            index=$(( $index + 1 ))
        done
        read -s -n3 key # Wait for user input
        case $key in
            $esc[A) # Up arrow
                cur=$(( $cur - 1 ))
                if [ "$cur" -lt 0 ]; then
                    cur=0
                fi ;;
            $esc[B) # Down arrow
                cur=$(( $cur + 1 ))
                if [ "$cur" -ge "$count" ]; then
                    cur=$(( $count - 1 ))
                fi ;;
            '') break ;;
            *) ;;
        esac
        echo -en "\033[${count}A" # Go up to re-render
    done
    printf "${COLOR_OFF}"
    printf -v $outvar "${options[$cur]}"
}

# Check and download dataset if needed
if [ ! -f dataset/v62_AADR_1240K.bed ]; then
    echo "Dataset not found. Downloading v62_AADR_1240K in PLINK format..."
    cd dataset
    wget "https://www.dropbox.com/scl/fi/ft3ncsn1rcs0akwo69jyv/v62_AADR_1240K.zip?rlkey=kco3uznr7onougbpnay6qxr5i&st=twl0s2o4&dl=1" -O v62_AADR_1240K.zip
    if [ $? -eq 0 ]; then
        echo "Download complete. Unzipping..."
        unzip v62_AADR_1240K.zip
        if [ $? -eq 0 ]; then
            echo "Unzipping complete. Cleaning up..."
            rm v62_AADR_1240K.zip
            cd ..
        else
            echo "Error: Unzipping failed."
            exit 1
        fi
    else
        echo "Error: Download failed."
        exit 1
    fi
else
    echo "Dataset already exists. Skipping download."
fi

# Check and download terraseq if needed
if [ ! -f bin/terraseq ]; then
    echo "terraseq not found. Downloading terraseq..."
    cd bin
    wget https://github.com/enelsr/terraseq/releases/latest/download/terraseq
    if [ $? -eq 0 ]; then
        chmod +x terraseq
        echo "terraseq downloaded and made executable."
        cd ..
    else
        echo "Error: Download failed."
        exit 1
    fi
else
    echo "terraseq is already installed. Skipping download."
fi

# Check and download plink if needed
if [ ! -f bin/plink ]; then
    echo "plink not found. downloading ..."
    cd bin
    wget https://s3.amazonaws.com/plink1-assets/plink_linux_x86_64_20231211.zip
    unzip plink_linux_x86_64_20231211.zip
    if [ $? -eq 0 ]; then
        chmod +x plink
        echo "plink downloaded and made executable."
        cd ..
    else
        echo "Error: Download failed."
        exit 1
    fi
else
    echo "plink is already installed. Skipping download."
fi

# Get input file name
echo ""
read -p "Enter your dna file name (file in dna_file folder): " FILENAME

# Format selection menu
format_options=(
    "23andme"
    "myheritage"
    "ftdnav1"
    "ftdnav2"
    "ancestry"
    "Quit"
)
echo ""
choose_from_menu "Please select your DNA file format:" FORMAT "${format_options[@]}"
case $FORMAT in
    "Quit")
        echo "Exiting..."
        exit
        ;;
esac

# Get family ID
echo ""
read -p "Enter the familyid of your output file: " FAM

# Process the DNA file
echo "Aligning DNA file..."
./bin/terraseq align --alignFile dataset/v62_AADR_1240K.bim --inFile dna_file/$FILENAME --inFormat $FORMAT --outFile dna_file/temp.txt --outFormat 23andme --flip

echo "Converting file to plink ..."
./bin/plink --23file dna_file/temp.txt --make-bed --out dna_file/temp

# Change the Family ID
awk -v fam="$FAM" 'NR==1 {$1=fam} {print}' dna_file/temp.fam > temp1.fam && mv temp1.fam dna_file/temp.fam
output_filename="${FAM}_1240K"

echo "Merging ..."
./bin/plink --bfile dna_file/temp --bmerge dataset/v62_AADR_1240K --out output/$output_filename

# Clean up temporary files
rm dna_file/temp*

echo "Pipeline finished!"
