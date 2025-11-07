#!/bin/sh -l
#SBATCH -t 12:0:0
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu=7G
#SBATCH -J STAR_genomeGen
#SBATCH -e %x-%j.err
#SBATCH -o %x-%j.out
#SBATCH --export=ALL

if [ -z "$1" ]; then
    echo "Usage: sbatch/sh $0 [output folder]" >&2
    exit 1
fi

FOLDER="$1"

if [ ! -d "${FOLDER}" ]; then
    mkdir ${FOLDER}
fi

cd ${FOLDER}

LOG="T2T_STAR_index_generation.log"
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

GTF="T2T_geneTE_forSTAR.gtf"
if [ ! -f "${GTF}" ]; then
    echo "Please obtain and put the ${GTF} file in the current folder" >&2
    exit 1
fi
    
if ! command -v STAR &>/dev/null
then
    echo "STAR could not be found. Please ensure it is installed and in the PATH variable" >&2
    exit 1
fi

CMD="STAR --runMode genomeGenerate --limitGenomeGenerateRAM 39000000000 --runThreadN 10"

CMD="${CMD} --genomeDir ${FOLDER}  --genomeFastaFiles ${FASTA}"

CMD="${CMD} --sjdbGTFfile ${GTF} --sjdbOverhang 100"

${CMD} 2>>${LOG}

if [ $? -ne 0 ]; then
    echo "Error with STAR run. See ${LOG} for details" >&2
    exit 1
else
    echo "Done"
fi
