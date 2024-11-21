#!/bin/bash

# Color Definitions
COLOR_RESET='\033[0m'
COLOR_GREEN='\033[0;32m'
COLOR_BLUE='\033[0;34m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
BICYAN='\033[1;96m'

function print_header() {
    echo -e "${COLOR_YELLOW}======================================${COLOR_RESET}"
}

function log_info() {
    echo -e "${COLOR_GREEN}[INFO]${COLOR_RESET} $1"
}

function log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1"
}

function log_warning() {
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $1"
}

trap 'echo ""
log_warning "Pipeline terminated by user." ; exit 1' SIGINT

function choose_dna_file() {
    local outvar="$1"
    local esc=$(echo -en "\033")
    COLOR_OFF='\033[0m'
    BICYAN='\033[1;96m'

    # Change to dna_file directory and get file list
    cd dna_file
    local files=($(ls))
    files+=("Quit")  # Add Quit option

    local cur=0 count=${#files[@]} index=0

    print_header
    echo ""
    printf "${COLOR_BLUE}Select the DNA file to process:${COLOR_RESET}\n"

    while true
    do
        # List all files
        index=0
        for f in "${files[@]}"
        do
            if [ "$index" == "$cur" ]
            then echo -e " ${BICYAN}> $f${COLOR_OFF}"
            else echo -e "   $f"
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
    echo ""
    # Return selected file or handle Quit
    if [ "${files[$cur]}" == "Quit" ]; then
        log_warning "Pipeline terminated by user."
        cd ..
        exit
    fi

    printf -v $outvar "${files[$cur]}"

    cd ..
}


function choose_from_menu() {
    local prompt="$1" outvar="$2"
    shift
    shift
    local options=("$@") cur=0 count=${#options[@]} index=0
    local esc=$(echo -en "\033")
    
    print_header
    echo ""
    printf "${COLOR_BLUE}$prompt${COLOR_RESET}\n"
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
    echo ""
    printf "${COLOR_OFF}"
    printf -v $outvar "${options[$cur]}"
}

function main() {
    clear

    dataset_options=(
        "1240K"
        "HO"
        "Quit"
    )
    echo ""
    choose_from_menu "Please select your dataset choice:" DATASET "${dataset_options[@]}"
    case $DATASET in
        "Quit")
            log_warning "Pipeline terminated by user."
            exit
            ;;
    esac

    # Get input file name
    choose_dna_file FILENAME
    # Format selection menu
    format_options=(
        "23andme"
        "myheritage"
        "ftdnav1"
        "ftdnav2"
        "ancestry"
        "Quit"
    )
    choose_from_menu "Please select your DNA file format:" FORMAT "${format_options[@]}"
    case $FORMAT in
        "Quit")
            log_warning "Pipeline terminated by user."
            exit
            ;;
    esac
    print_header
    echo ""
    echo -e "${COLOR_BLUE}Enter the family ID for your output file:\n  ${BICYAN}> \c"
    read FAM
    echo ""
    print_header

    # Dataset-specific download logic
    echo ""
    case $DATASET in
        "1240K")
        aadr="v62_AADR_1240K"
        alignfile="${aadr}.bim"
        if [ ! -f dataset/v62_AADR_1240K.bed ]; then
            log_info "Dataset not found. Downloading v62_AADR_1240K in PLINK format..."
            cd dataset
            wget "https://www.dropbox.com/scl/fi/ft3ncsn1rcs0akwo69jyv/v62_AADR_1240K.zip?rlkey=kco3uznr7onougbpnay6qxr5i&st=twl0s2o4&dl=1" -O v62_AADR_1240K.zip
            if [ $? -eq 0 ]; then
                log_info "Download complete. Unzipping..."
                unzip v62_AADR_1240K.zip
                if [ $? -eq 0 ]; then
                    log_info "Unzipping complete. Cleaning up..."
                    rm v62_AADR_1240K.zip
                    cd ..
                else
                    log_error "Unzipping failed."
                    exit 1
                fi
            else
                log_error "Download failed."
                exit 1
            fi
        else
            log_info "Dataset already exists. Skipping download."
        fi
        esac

    case $DATASET in
        "HO")
        aadr="v62_AADR_HO"
        alignfile="${aadr}.bim"
        if [ ! -f dataset/v62_AADR_HO.bed ]; then
            log_info "Dataset not found. Downloading v62_AADR_HO in PLINK format..."
            cd dataset
            wget "https://github.com/enelsr/poseidon-packages/releases/download/AADR/v62_AADR_HO.zip" -O v62_AADR_HO.zip
            if [ $? -eq 0 ]; then
                log_info "Download complete. Unzipping..."
                unzip v62_AADR_HO.zip
                if [ $? -eq 0 ]; then
                    log_info "Unzipping complete. Cleaning up..."
                    rm v62_AADR_HO.zip
                    cd ..
                else
                    log_error "Unzipping failed."
                    exit 1
                fi
            else
                log_error "Download failed."
                exit 1
            fi
        else
            log_info "Dataset already exists. Skipping download."
        fi
        esac

    # Check and download terraseq if needed
    if [ ! -f bin/terraseq ]; then
        log_info "terraseq not found. Downloading terraseq..."
        cd bin
        wget https://github.com/enelsr/terraseq/releases/latest/download/terraseq
        if [ $? -eq 0 ]; then
            chmod +x terraseq
            log_info "terraseq downloaded and made executable."
            cd ..
        else
            log_error "Download failed."
            exit 1
        fi
    else
        log_info "terraseq is already installed. Skipping download."
    fi

    # Check and download plink if needed
    if [ ! -f bin/plink ]; then
        log_info "plink not found. Downloading..."
        cd bin
        wget https://s3.amazonaws.com/plink1-assets/plink_linux_x86_64_20231211.zip
        unzip plink_linux_x86_64_20231211.zip
        if [ $? -eq 0 ]; then
            chmod +x plink
            log_info "plink downloaded and made executable."
            rm -f plink_linux_x86_64_20231211.zip toy.map toy.ped prettify
            cd ..
        else
            log_error "Download failed."
            exit 1
        fi
    else
        log_info "plink is already installed. Skipping download."
    fi

    output_filename="${FAM}_${DATASET}"

    echo ""
    print_header
    echo ""
    log_info "Using terraseq to convert & align file..."
    ./bin/terraseq align --alignFile dataset/$alignfile --inFile dna_file/$FILENAME --inFormat $FORMAT --outFile dna_file/temp.txt --flip

    echo ""
    print_header
    echo ""
    log_info "Converting file to PLINK format..."
    ./bin/plink --23file dna_file/temp.txt --make-bed --out dna_file/temp

    echo ""
    print_header
    echo ""
    log_info "Updating Family ID..."
    awk -v fam="$FAM" 'NR==1 {$1=fam} {print}' dna_file/temp.fam > temp1.fam && mv temp1.fam dna_file/temp.fam

    echo ""
    print_header
    echo ""
    log_info "Merging datasets..."
    ./bin/plink --bfile dna_file/temp --bmerge dataset/$aadr --out output/$output_filename
    echo ""
    print_header

    # Clean up temporary files
    echo ""
    rm dna_file/temp*
    log_info "Output dataset: /output/${output_filename}"
    echo -e "\n${COLOR_GREEN}[PIPELINE COMPLETED SUCCESSFULLY]${COLOR_RESET}"
}

main
