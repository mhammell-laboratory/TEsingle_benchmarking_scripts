#!/bin/sh
#SBATCH -t 12:0:0
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu=10G
#SBATCH -J assess_SoloTE
#SBATCH -e %x-%j.err
#SBATCH -o %x-%j.out
#SBATCH --export=ALL

usage(){
    echo "
    Usage: sbatch $0 [T2T SoloTE conversion file]
                     [SoloTE output directory]
                     [T2T TEsubfam simulated counts]
" >&2
    exit 1
}

if [ -z "$3" ];then
    usage
fi

KEY="$1"
DIR="$2"
TRUTH="$3"

LIBID=$(basename $DIR _SoloTE_output)
DIR="${DIR}/${LIBID}_legacytes_MATRIX"
LIBID="SoloTE_${LIBID}"
BC="${DIR}/barcodes.tsv"
FEAT="${DIR}/features.tsv"
MTX="${DIR}/matrix.mtx"

SCRIPTDIR=$(dirname $0)


gunzip -cf "${BC}" | awk -v OFS="," '{print $0 "-1",NR}' | sort -k2,2 -t "," > "${LIBID}_bc.csv" &
gunzip -cf "${FEAT}" | awk -F "	" -v OFS="," '$1~/^SoloTE/{print $1 ":TE",NR};$1!~/^SoloTE/{print $2,NR}' | sed 's/^SoloTE|//' | sort -k2,2 -t "," > "${LIBID}_feat.csv" &

wait

gunzip -cf "${MTX}" | sed '1,3d;s/ /,/g' | sort -k2,2 -S 2G -T $PWD -t "," | join -t "," -j 2 - "${LIBID}_bc.csv" | sort -k2,2 -S 2G -T $PWD -t "," | join -t "," -j 2 - "${LIBID}_feat.csv" | awk -F "," -v OFS="	" '{print $4 ";" $5,$3}' | sort -k1,1 -S 5G -T $PWD | sort -k1,1 > "${LIBID}.tmp"

if [ $? -ne 0 ];then
    echo "Error in annotating matrix" >&2
else
    rm ${LIBID}_{bc,feat}.csv
fi

if [ ! -d "processed" ]; then
    mkdir processed
fi

grep -e "|" "${LIBID}.tmp" | sed 's/;/	/;s/:TE//' | sort -k2,2 | join -t "	" -1 1 -2 2 ${KEY} - | awk -v OFS="	" '{print $3 ";" $2 ":TE",$4}' > ${LIBID}_inst.tmp

grep -v -e "|" ${LIBID}.tmp | sed 's/:.*:TE	/:TE	/' | cat - ${LIBID}_inst.tmp | sort -k1,1 | sed 's/_dup[0-9]*:TE/:TE/' | sort -k1,1 -S 2G | groupBy -g 1 -c 2 -o sum > processed/${LIBID}_subfam_counts.txt

if [ $? -ne 0 ]; then
    echo "Error with cleaning SoloTE output" >&2
    exit 1
else
    rm ${LIBID}.tmp ${LIBID}_inst.tmp
fi

SCRIPT="${SCRIPTDIR}/src/multijoin"
BASE="${LIBID}"

${SCRIPT} -k 1 -v 2 -h ${TRUTH} processed/${BASE}_subfam_counts.txt > ${BASE}_subfam_comparison.txt

if [ ! -d "comparison" ]; then
    mkdir comparison
fi

SCRIPT="${SCRIPTDIR}/src/compare_run_to_simulated_truth.pl"

perl ${SCRIPT} ${BASE}_subfam_comparison.txt > comparison/${BASE}_subfam_comparison_results.txt
rm ${BASE}_subfam_comparison.txt

if [ ! -d "summary" ]; then
    mkdir summary
fi

SCRIPT="${SCRIPTDIR}/src/make_accuracy_summary.pl"

perl ${SCRIPT} comparison/${BASE}_subfam_comparison_results.txt > summary/${BASE}_subfam_comparison_summary.txt

echo "Done"
