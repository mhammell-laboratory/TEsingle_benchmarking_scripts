#!/bin/sh -l
#SBATCH -t 12:0:0
#SBATCH --mem-per-cpu=7G
#SBATCH --cpus-per-task=10
#SBATCH -J CR_mkref
#SBATCH -e %x-%j.err
#SBATCH -o %x-%j.out
#SBATCH --export=ALL

if [ -z "$1" ]; then
    echo "sbatch/sh $0 [output folder name]" >&2
    exit 1
fi

FOLDER="$1"

LOG="hg38_CR_db_generation.log"
if [ -f "${LOG}" ]; then
    rm ${LOG}
fi

FASTA="GRCh38_primary_assembly.fa"
if [ ! -f "${FASTA}" ]; then
    if ! command -v curl &>/dev/null
    then
        if ! command -v wget &>dev/null
           then
            echo "Please install either curl or wget to enable downloading files" >&2
            exit 1
        else
            wget -O ${FASTA}.gz "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_46/GRCh38.primary_assembly.genome.fa.gz" 2>>${LOG}
        fi
    else
        curl -o ${FASTA}.gz "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_46/GRCh38.primary_assembly.genome.fa.gz" 2>>${LOG}
    fi
    gunzip ${FASTA}.gz
fi

GTF="hg38_geneTE_forCellRangerTE.gtf"
if [ ! -f "${GTF}" ]; then
    echo "Please obtain and put the ${GTF} file in the current folder" >&2
    exit 1
fi

if ! command -v cellranger &>/dev/null
then
    echo "cellranger could not be found. Please ensure it is installed and in the PATH variable" >&2

cellranger mkref --genome="${GENOME}" --fasta="${FASTA}" --genes="${GTF}" --nthreads 10 2>&1 >>${LOG}

if [ $? -ne 0 ]; then
    echo "Error with CellRanger run. See ${LOG} for details" >&2
    exit 1
else
    echo "Done"
fi
