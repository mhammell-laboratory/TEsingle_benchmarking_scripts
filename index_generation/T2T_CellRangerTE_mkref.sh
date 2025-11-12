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

LOG="T2T_CR_db_generation.log"
if [ -f "${LOG}" ]; then
    rm ${LOG}
fi

FASTA="T2T_CHM13v2.fa"
if [ ! -f "${FASTA}" ]; then
    if ! command -v curl &>/dev/null
    then
        if ! command -v wget &>dev/null
           then
            echo "Please install either curl or wget to enable downloading files" >&2
            exit 1
        else
            wget -O ${FASTA}.gz "https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/analysis_set/chm13v2.0.fa.gz" 2>>${LOG}
        fi
    else
        curl -o ${FASTA}.gz "https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/analysis_set/chm13v2.0.fa.gz" 2>>${LOG}
    fi
    gunzip ${FASTA}.gz
fi

GTF="T2T_geneTE_forCellRangerTE.gtf"
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
