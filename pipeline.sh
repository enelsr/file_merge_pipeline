#!/bin/bash

if [ ! -f dataset/v62_AADR_1240K.bed ]; then
    echo "Dataset not found. Downloading v62_AADR_1240K in PLINK format..."

    # Go into the dataset directory
    cd dataset

    # Download the zip file from Dropbox
    wget "https://www.dropbox.com/scl/fi/ft3ncsn1rcs0akwo69jyv/v62_AADR_1240K.zip?rlkey=kco3uznr7onougbpnay6qxr5i&st=twl0s2o4&dl=1" -O v62_AADR_1240K.zip

    # Check if the download was successful
    if [ $? -eq 0 ]; then
        echo "Download complete. Unzipping..."

        # Unzip the file
        unzip v62_AADR_1240K.zip

        # Check if unzip was successful
        if [ $? -eq 0 ]; then
            echo "Unzipping complete. Cleaning up..."
            # Remove the zip file
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
if [ ! -f bin/terraseq ]; then
    echo "terraseq not found. Downloading terraseq..."

    # Change to the 'bin' directory
    cd bin

    # Download the latest release of terraseq
    wget https://github.com/enelsr/terraseq/releases/latest/download/terraseq

    # Check if the download was successful
    if [ $? -eq 0 ]; then
        # Make the downloaded file executable
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

read -p "Enter your dna file name (file in dna_file folder): " FILENAME

read -p "Enter format of your file (23andme, myheritage, ftdnav1, ftdnav2, ancestry): " FORMAT

read -p "Enter the familyid of your output file: " FAM

# Align the DNA file using terraseq
./bin/terraseq align --alignFile dataset/v62_AADR_1240K.bim --inFile dna_file/$FILENAME --inFormat $FORMAT --outFile dna_file/temp.txt --outFormat 23andme --flip

# Run plink to convert the file to binary format
echo "Converting file to plink ..."
plink --23file dna_file/temp.txt --make-bed --out dna_file/temp

# Change the Family ID (FID) in the .fam file for the first line
awk -v fam="$FAM" 'NR==1 {$1=fam} {print}' dna_file/temp.fam > temp1.fam && mv temp1.fam dna_file/temp.fam

output_filename="${FAM}_1240K"

echo "Merging ..."
plink --bfile dna_file/temp --bmerge dataset/v62_AADR_1240K --out output/$output_filename

rm dna_file/temp*

echo "Pipeline finished!"
