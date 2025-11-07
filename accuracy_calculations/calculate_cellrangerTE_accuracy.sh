#!/bin/sh -l
#SBATCH -t 12:0:0
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu=10G
#SBATCH -J assess_cellranger
#SBATCH -e %x-%j.err
#SBATCH -o %x-%j.out
#SBATCH --export=ALL


usage(){
    echo "
    Usage: sbatch $0 [cellranger output directory] 
                     [T2T TEsubfam simulated counts]
" >&2
    exit 1
}

if [ -z "$2" ];then
    usage
fi

DIR="$1"
TRUTH="$2"

LIBID=$(basename $DIR)
LIBID="${LIBID}_cellranger"
BC="${DIR}/outs/filtered_feature_bc_matrix/barcodes.tsv.gz"
FEAT="${DIR}/outs/filtered_feature_bc_matrix/features.tsv.gz"
MTX="${DIR}/outs/filtered_feature_bc_matrix/matrix.mtx.gz"

gunzip -cf "${BC}" | awk -v OFS="," '{print $0,NR}' | sort -k2,2 -t "," > "${LIBID}_bc.csv" &
gunzip -cf "${FEAT}" | awk -F "	" -v OFS="," '{print $2,NR}' | sort -k2,2 -t "," > "${LIBID}_feat.csv" &

wait

if [ ! -d "processed" ]; then
    mkdir processed
fi

gunzip -cf "${MTX}" | sed '1,3d;s/ /,/g' | sort -k2,2 -S 2G -T $PWD -t "," | join -t "," -j 2 - "${LIBID}_bc.csv" | sort -k2,2 -S 2G -T $PWD -t "," | join -t "," -j 2 - "${LIBID}_feat.csv" | awk -F "," -v OFS="	" '{print $4 ";" $5,$3}' | sort -k1,1 -S 5G -T $PWD | groupBy -g 1 -c 2 -o sum > "processed/${LIBID}_subfam_counts.txt"

if [ $? -ne 0 ];then
    echo "Error in annotating matrix" >&2
else
    rm ${LIBID}_{bc,feat}.csv
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

echo "Done" >&2
