#!/bin/sh -l
#SBATCH -t 12:0:0
#SBATCH --mem-per-cpu=4G
#SBATCH --cpus-per-task=10
#SBATCH -J scTE_build
#SBATCH -e %x-%j.err
#SBATCH -o %x-%j.out
#SBATCH --export=ALL

LOG="T2T_scTE_build.log"
if [ -f "${LOG}" ]; then
    rm ${LOG}
fi

GENE="T2T_gene_scTE.gtf"
if [ ! -f "${GENE}" ]; then
    echo "Please obtain and put the ${GENE} file in the current folder" >&2
    exit 1
fi

TE="T2T_TE_scTE.bed"
if [ ! -f "${TE}" ]; then
    echo "Please obtain and put the ${TE} file in the current folder" >&2
    exit 1
fi

if ! command -v scTE_build &>/dev/null
then
    echo "scTE_build could not be found. Please ensure it is installed and in PATH variable" >&2
    exit 1
fi

scTE_build -gene ${GENE} -te ${TE} -m nointron -o T2T >> ${LOG}

if [ $? -ne 0 ]; then
    echo "Error with scTE run. See ${LOG} for details" >&2
    exit 1
else
    echo "Done"
fi

