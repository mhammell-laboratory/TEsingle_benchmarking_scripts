#!/bin/sh -l
#SBATCH --mem-per-cpu=30G
#SBATCH --cpus-per-task=16
#SBATCH --partition=fn_medium
#SBATCH -t 5-0:0:0
#SBATCH -J CellRangerTE
#SBATCH -e %x-%j.err
#SBATCH -o %x-%j.out
#SBATCH --export=ALL

CORES=16
TOTMEM=470 # Allow 10Gb leeway

if [ -z "$1" ]; then
    echo "sbatch $0 [Cellranger databases] [R2]" >&2
    echo "Assumes I1 and R1 files in the same folder as R2" >&2
    exit 1
fi

GENOMEDIR="$1"
INPUT="$2"
UMI=$(echo ${INPUT} | sed 's/_R2/_R1/')
IDX=$(echo ${INPUT} | sed 's/_R2/_I1/')

SAMPLE=$(basename ${INPUT} \.gz)
SAMPLE=$(basename ${SAMPLE} \.fastq)
SAMPLE=$(echo ${SAMPLE} | sed 's/_R2//')
SAMPLE=$(echo ${SAMPLE} | sed 's/\./-/g')

if [ ! -d "fq_${SAMPLE}" ]; then
    mkdir "fq_${SAMPLE}"
fi

cd "fq_${SAMPLE}"
ln -sf "../${INPUT}" ${SAMPLE}_S1_L001_R2_001.fastq.gz
ln -sf "../${UMI}" ${SAMPLE}_S1_L001_R1_001.fastq.gz
ln -sf "../${IDX}" ${SAMPLE}_S1_L001_I1_001.fastq.gz
cd ..

CMD="cellranger count --id=${SAMPLE}_CRTE --jobmode=local --localcores=${CORES} --localmem=${TOTMEM} --transcriptome=${GENOMEDIR} --fastqs=fq_${SAMPLE} --sample=${SAMPLE} --include-introns=true --chemistry=auto --create-bam=true"

${CMD}

if [ ! -f "${SAMPLE}/outs/molecule_info.h5" ]; then
    echo "Warning: Quantification not complete" >&2
    exit 1;
fi

if [ ! -f "${SAMPLE}/outs/metrics_summary.csv" ]; then
    echo "Warning: Pipestance not complete" >&2
    exit 1;
fi

if [ -d "${SAMPLE}/SC_RNA_COUNTER_CS" ]; then
    rm -r "${SAMPLE}/SC_RNA_COUNTER_CS/"
fi
    
rm -r "fq_${SAMPLE}"

echo "CellRanger count complete for $SAMPLE" >&2
