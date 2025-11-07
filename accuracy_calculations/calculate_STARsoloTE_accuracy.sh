#!/bin/sh -l
#SBATCH -t 12:0:0
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu=10G
#SBATCH -J assess_STARsoloTE
#SBATCH -e %x-%j.err
#SBATCH -o %x-%j.out
#SBATCH --export=ALL

usage(){
    echo "
    Usage: sbatch $0 [STARsolo directory]
                     [T2T TElocus simulated counts]
                     [T2T TEsubfam simulated counts]
" >&2
    exit 1
}

if [ -z "$3" ];then
    usage
fi

SCRIPTDIR=$(dirname $0)
DIR="$1"
LOCUSTRUTH="$2"
SUBFAMTRUTH="$3"

LIBID=$(basename $DIR)
LIBID="${BASE}_STARsoloTE_EM"
DIR="${DIR}/Solo.out/GeneFull"

BC="${DIR}/raw/barcodes.tsv"
FEAT="${DIR}/raw/features.tsv"
MTX="${DIR}/raw/UniqueAndMult-EM.mtx"

awk -v OFS="," '{print $0 "-1",NR}' "${BC}" | sort -k2,2 -t "," > "${LIBID}_bc.csv" &
awk -F "	" -v OFS="," '$1==$2{print $1,NR};$1!=$2{print $1 ":TE",NR}' "${FEAT}" | sort -k2,2 -t "," > "${LIBID}_feat.csv" &

wait

if [ ! -d "processed" ]; then
    mkdir processed
fi

sed '1,3d;s/ /,/g' "${MTX}" | grep -v -e "-nan" | sort -k2,2 -S 2G -T $PWD -t "," | join -t "," -j 2 - "${LIBID}_bc.csv" | sort -k2,2 -S 2G -T $PWD -t "," | join -t "," -j 2 - "${LIBID}_feat.csv" | awk -F "," -v OFS="	" '{print $4 ";" $5,$3}' | sort -k1,1 -S 5G -T $PWD > "processed/${LIBID}_locus_counts.txt"

if [ $? -ne 0 ];then
    echo "Error in annotating matrix" >&2
else
    echo "Done with instance" >&2
    rm ${LIBID}_{bc,feat}.csv
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
