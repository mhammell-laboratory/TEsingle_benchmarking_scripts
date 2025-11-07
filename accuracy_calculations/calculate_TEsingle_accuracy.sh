#!/bin/sh -l
#SBATCH -t 12:0:0
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu=10G
#SBATCH -J assess_TEsingle
#SBATCH -e %x-%j.err
#SBATCH -o %x-%j.out
#SBATCH --export=ALL

usage(){
    echo "
    Usage: sbatch $0 [mtx file]
                     [T2T TElocus simulated counts]
                     [T2T TEsubfam simulated counts]
      Assumes annots and cbcs files in same directory
" >&2
    exit 1
}

if [ -z "$3" ];then
    usage
fi

SCRIPTDIR=$(dirname $0)
MTX="$1"
LOCUSTRUTH="$2"
SUBFAMTRUTH="$3"

PREFIX=$(echo ${MTX} | sed 's/\.gz//')
PREFIX=$(echo ${PREFIX} | sed 's/\.mtx//')
LIBID=$(basename ${PREFIX})
BC="${PREFIX}.cbcs.gz"
if [ ! -f "${BC}" ]; then
    BC="${PREFIX}.cbcs"
    if [ ! -f "${BC}" ]; then
	echo "Barcode file (${BC}) or its gzipped version not found" >&2
	exit 1
    fi
fi
FEAT="${PREFIX}.annots.gz"
if [ ! -f "${FEAT}" ]; then
    FEAT="${PREFIX}.annots"
    if [ ! -f "${FEAT}" ]; then
	echo "Feature file (${FEAT}) or its gzipped version not found" >&2
	exit 1
    fi
fi

gunzip -cf "${BC}" | awk -v OFS="," '{print $0 "-1",NR}' | sort -k2,2 -t "," > "${LIBID}_bc.csv" &
gunzip -cf "${FEAT}" | sed 's/\"//g' | awk -v OFS="," '{print $0,NR}' | sed 's/:..*,/:TE,/' | sort -k2,2 -t "," > "${LIBID}_feat.csv" &

wait

if [ ! -d "processed" ]; then
    mkdir processed
fi

gunzip -cf "${MTX}" | sed '1,3d;s/ /,/g' | sort -k2,2 -S 2G -T $PWD -t "," | join -t "," -j 2 - "${LIBID}_bc.csv" | sort -k2,2 -S 2G -T $PWD -t "," | join -t "," -j 2 - "${LIBID}_feat.csv" | awk -F "," -v OFS="	" '{print $5 ";" $4,$3}' | sort -k1,1 -S 5G -T $PWD | groupBy -g 1 -c 2 -o sum > "processed/${LIBID}_locus_counts.txt"

if [ $? -ne 0 ];then
    echo "Error in annotating matrix" >&2
else
    rm ${LIBID}_{feat,bc}.csv
    echo "Done with instance" >&2
fi

sed 's/_dup[0-9]*//' "processed/${LIBID}_locus_counts.txt" | sort -k1,1 -S 5G -T $PWD | groupBy -g 1 -c 2 -o sum > "processed/${LIBID}_subfam_counts.txt"

if [ $? -ne 0 ]; then
    echo "Error in aggregating locus results" >&2
    exit 1
else
    echo "Done with locus aggregation" >&2
fi

SCRIPT="${SCRIPTDIR}/src/multijoin"
BASE="${LIBID}"

${SCRIPT} -k 1 -v 2 -h ${SUBFAMTRUTH} processed/${BASE}_subfam_counts.txt > ${BASE}_subfam_comparison.txt &
${SCRIPT} -k 1 -v 2 -h ${LOCUSTRUTH} processed/${BASE}_locus_counts.txt > ${BASE}_locus_comparison.txt &

wait

if [ ! -d "comparison" ]; then
    mkdir comparison
fi

SCRIPT="${SCRIPTDIR}/src/compare_run_to_simulated_truth.pl"

perl ${SCRIPT} ${BASE}_subfam_comparison.txt > comparison/${BASE}_subfam_comparison_results.txt &
perl ${SCRIPT} ${BASE}_locus_comparison.txt > comparison/${BASE}_locus_comparison_results.txt &

wait

rm ${BASE}_subfam_comparison.txt
rm ${BASE}_locus_comparison.txt

if [ ! -d "summary" ]; then
    mkdir summary
fi

SCRIPT="${SCRIPTDIR}/src/make_accuracy_summary.pl"

perl ${SCRIPT} comparison/${BASE}_subfam_comparison_results.txt > summary/${BASE}_subfam_comparison_summary.txt &
perl ${SCRIPT} comparison/${BASE}_locus_comparison_results.txt > summary/${BASE}_locus_comparison_summary.txt &

wait

echo "Done"

