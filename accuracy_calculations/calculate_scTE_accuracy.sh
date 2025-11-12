#!/bin/sh -l
#SBATCH -t 12:0:0
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu=10G
#SBATCH -J assess_scTE
#SBATCH -e %x-%j.err
#SBATCH -o %x-%j.out
#SBATCH --export=ALL

if [ -z "$1" ]; then
    echo "
    Usage: sbatch $0 [scTE csv output] 
                     [T2T TEsubfam simulated counts]
" >&2
    exit 1
fi

SCRIPTDIR=$(dirname $0)
SCRIPT="${SCRIPTDIR}/src/process_scTE_results.pl"
TELIST="${SCRIPTDIR}/src/T2T_scTE_subfamID.txt"

FILE="$1"
BASE=$(basename ${FILE} \.csv)
TRUTH="$2"

perl "${SCRIPT}" "${FILE}" > "${BASE}_all.tmp"

if [ $? -ne 0 ]; then
    echo "Error with conversion script" >&2
    exit 1
fi

sed 's/;/	/' ${BASE}_all.tmp | sort -k2,2 -S 8G -T $PWD | join -t "	" -1 1 -2 2 ${TELIST} - | awk -v OFS="	" '{print $2 ";" $1 ":TE",$3}' > ${BASE}_TE.tmp &
sed 's/;/	/' ${BASE}_all.tmp | sort -k2,2 -S 8G -T $PWD| join -t "	" -v 2 -1 1 -2 2 ${TELIST} - | awk -v OFS="	" '{print $2 ";" $1,$3}' > ${BASE}_gene.tmp &

wait

if [ ! -d "processed" ]; then
    mkdir processed
fi

cat ${BASE}_gene.tmp ${BASE}_TE.tmp | sort -k1,1 -T $PWD -S 18G | groupBy -g 1 -c 2 -o sum > processed/${BASE}_subfam_counts.txt

if [ $? -ne 0 ]; then
    echo "Error with generating output" >&2
else
    rm ${BASE}_all.tmp ${BASE}_TE.tmp ${BASE}_gene.tmp
fi

SCRIPT="${SCRIPTDIR}/src/multijoin"

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

