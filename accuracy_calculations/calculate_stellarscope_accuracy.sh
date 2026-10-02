#!/bin/sh
#SBATCH -t 12:0:0
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu=10G
#SBATCH -J assess_stellarscope
#SBATCH -e %x-%j.err
#SBATCH -o %x-%j.out
#SBATCH --export=ALL

usage(){
    echo "
    Usage: sbatch $0 [stellarscope features tsv]
    	   	     [stellarscope barcodes tsv]
		     [stellarscope count matrix]]
                     [stellarscope simulated counts]
" >&2
    exit 1
}

if [ -z "$4" ];then
    usage
fi

FEAT="$1"
BC="$2"
MTX="$3"
TRUTH="$4"

LIBID=$(basename ${MTX} | sed 's/\-TE_counts\.mtx//')
LIBID=$(basename $DIR _stellarscope_output)


if [ ! -d "processed" ]; then
    mkdir processed
fi

gunzip -cf "${BC}" | awk -v OFS="," '{print $0 "-1",NR}' | sort -k2,2 -t "," > "${LIBID}_bc.csv" &
gunzip -cf "${FEAT}" | awk -F " " -v OFS="," '{print $1 ":TE",NR}' | sort -k2,2 -t "," > "${LIBID}_feat.csv" &

wait

gunzip -cf "${MTX}" | sed '1,3d;s/ /,/g' | sort -k2,2 -S 2G -T $PWD -t "," | join -t "," -j 2 - "${LIBID}_bc.csv" | sort -k2,2 -S 2G -T $PWD -t "," | join -t "," -j 2 - "${LIBID}_feat.csv" | awk -F "," -v OFS="      " '{print $4 ";" $5,$3}' | sort -k1,1 -S 5G -T $PWD > "processed/${LIBID}_inst_counts.txt"

if [ $? -ne 0 ];then
    echo "Error in annotating matrix" >&2
else
    rm ${LIBID}_{bc,feat}.csv
fi

SCRIPT="${SCRIPTDIR}/src/multijoin"
BASE="${LIBID}"

${SCRIPT} -k 1 -v 2 -h ${TRUTH} processed/${BASE}_inst_counts.txt > ${BASE}_inst_comparison.txt

if [ $? -ne 0 ]; then
    echo "Error with joining results" >&2
    exit 1
fi

if [ ! -d "comparison" ]; then
    mkdir comparison
fi

SCRIPT="${SCRIPTDIR}/src/compare_run_to_simulated_truth.pl"

perl ${SCRIPT} ${BASE}_inst_comparison.txt > comparison/${BASE}_inst_comparison_results.txt
rm ${BASE}_inst_comparison.txt

if [ ! -d "summary" ]; then
    mkdir summary
fi

SCRIPT="${SCRIPTDIR}/src/make_accuracy_summary.pl"

perl ${SCRIPT} comparison/${BASE}_inst_comparison_results.txt > summary/${BASE}_inst_comparison_summary.txt

echo "Done"
