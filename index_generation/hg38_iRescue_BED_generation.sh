#!/bin/sh

if [ -z "$1" ]; then
    echo "Usage: $0 [hg38_TEsingle_TE.gtf]" >&2
    exit 1
fi

GTF="$1"
OUTINST="hg38_iRescue_TElocus.bed"
OUTSUBFAM="hg38_iRescue_TEsubfam.bed"

gunzip -cf ${GTF} | sed 's/gene_id \"//;s/\".*$//' | awk -v OFS="       " '{print $1,$4-1,$5,$9,"0",$7}' | sort -k1,1 -k2,3n > ${OUTSUBFAM} &
gunzip -cf ${GTF} | sed 's/gene_id.*transcript_id \"//;s/\".*$//' | awk -v OFS="        " '{print $1,$4-1,$5,$9,"0",$7}' | sort -k1,1 -k2,3n > ${OUTINST} &

wait

echo "Done"
