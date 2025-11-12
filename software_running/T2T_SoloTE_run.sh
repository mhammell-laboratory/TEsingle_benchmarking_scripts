#!/bin/sh -l
#SBATCH -J SoloTE_run
#SBATCH -e %x-%j.err
#SBATCH -o %x-%j.out
#SBATCH --partition=fn_medium
#SBATCH --export=ALL
#SBATCH --mem-per-cpu=50G
#SBATCH --cpus-per-task=10
#SBATCH -t 5-0:0:0

THREADS=10  
MAXNUM=100
ANCHOR=200
MISMATCH=999
MISMATCH_LMAX="0.04"

if [ -z "$6" ]; then
    echo "Usage; sbatch $0 [STAR index] [white list] [R1] [R2] [SoloTE python script] [SoloTE TE BED]" >&2
    exit 1
fi

GENOME="$1"
WHITELIST="$2"
UMI="$3"
INPUT="$4"
PROG="$5"
TE="$6"

CURRDIR=$PWD

FILEBASE=`basename $INPUT`
UMIBASE=`basename $UMI`
BASE=`basename $FILEBASE \.gz`
BASE=`basename $BASE \.fastq`
BASE=`basename $BASE \.fq`
BASE=`basename $BASE _R2`
OUTDIR="${CURRDIR}/${BASE}_SoloTEprep"

if [ ! -d "$OUTDIR" ]; then
    mkdir $OUTDIR
fi

ln -s "$INPUT" "${CURRDIR}/${FILEBASE}"
ln -s "$UMI" "${CURRDIR}/${UMIBASE}"

cd $OUTDIR

CMD="STAR --genomeLoad NoSharedMemory --outSAMunmapped None --outFilterType BySJout --outSAMstrandField intronMotif --alignSJoverhangMin 8 --alignSJDBoverhangMin 1 --alignIntronMin 20 --alignIntronMax 1000000 --alignMatesGapMax 1000000 --sjdbScore 1"

CMD="$CMD --soloType CB_UMI_Simple --soloCBmatchWLtype 1MM_multi_Nbase_pseudocounts --outSAMattributes NH HI AS nM CR CY UR UY CB UB GX GN sS sQ sM --soloFeatures GeneFull --clipAdapterType CellRanger4 --outFilterScoreMin 30 --soloCellFilter EmptyDrops_CR 3000 0.99 10 45000 90000 500 0.01 20000 0.01 10000"

CMD="$CMD --genomeDir $GENOME --readFilesIn ${CURRDIR}/${FILEBASE} ${CURRDIR}/${UMIBASE} --outFilterMultimapNmax $MAXNUM --winAnchorMultimapNmax $ANCHOR --runThreadN $THREADS --outFilterMismatchNmax $MISMATCH --outFilterMismatchNoverReadLmax $MISMATCH_LMAX"

CMD="$CMD --soloCBwhitelist $WHITELIST --soloMultiMappers Uniform"

GZIP=`basename $FILE1 \.gz`

if [ "$GZIP" != "$FILEBASE" ]; then
    CMD="$CMD --readFilesCommand 'zcat'"
fi

CMD="$CMD --outSAMtype BAM SortedByCoordinate --outSAMheaderHD @HD VN:1.4 --limitBAMsortRAM 195000000000"

CMD="$CMD --soloUMIfiltering MultiGeneUMI_CR --soloUMIdedup 1MM_CR"

CMD="$CMD --soloUMIlen 12"

CMD="$CMD --outSAMmultNmax 1"

${CMD}

if [ $? -ne 0 ]; then
    echo "Error encountered during STAR mapping" >&2
    exit 1
else
    mv Log.final.out "${BASE}_STAR_mapping.log"
    mv Aligned.*.bam "${BASE}_STAR_10x.bam"
    find . -type d -exec chmod a+rx {} +
    echo "Mapping completed" >&2
fi

cd ..


BAM="${OUTDIR}/${BASE}_STAR_10x.bam"
BASE=$(basename ${BAM} _STAR_10x\.bam)
BASE="${BASE}_SoloTE"
LOG="${BASE}.log"

CMD="python ${PROG} -b ${BAM} -t 10 -d SoloTE_runs -a ${TE} -o ${BASE} 2>&1 >> ${LOG}"

${CMD}

if [ $? -ne 0 ]; then
    echo "Error with soloTE" >&2
    exit 1
else
    echo "Done"
fi
