#!/bin/sh -l
#SBATCH -t 12:0:0
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu=10G
#SBATCH -J assess_MATES
#SBATCH -e %x-%j.err
#SBATCH -o %x-%j.out
#SBATCH --export=ALL

usage(){
    echo "
    Usage: sbatch $0 [MATES output directory]
                     [T2T MATES2instance file]
                     [T2T TElocus simulated counts]
                     [T2T TEsubfam simulated counts]
" >&2
    exit 1
}

if [ -z "$4" ];then
    usage
fi

SCRIPTDIR=$(dirname $0)
DIR="$1"
CONV="$2"
LOCUSTRUTH="$3"
SUBFAMTRUTH="$4"

LIBID=$(basename $DIR)
BASE="${LIBID}_MATES_exclusive"
MTX="${DIR}/result/${LIBID}/TE_MTX.csv"

if [ ! -d "processed" ]; then
    mkdir processed
fi

SCRIPT="${SCRIPTDIR}/src/process_MATES_output.pl"

perl "${SCRIPT}" "${MTX}" > "processed/${BASE}_subfam_counts.txt"

if [ $? -ne 0 ]; then
    echo "Error with extracting MATES subfamily output" >&2
    exit 1
else
    echo "Subfamily results processed"
fi

BC="${DIR}/10X_locus/Unique/${LIBID}/barcodes.csv"
FEAT="${DIR}/10X_locus/Unique/${LIBID}/features.csv"
MTX="${DIR}/10X_locus/Unique/${LIBID}/matrix.mtx"

sed '1d' ${BC} | awk -v OFS="	" '{print NR,$0 "-1"}' | sort -k1,1 -S 8G -T $PWD > ${BASE}_bc.tmp &
sed '1d' ${FEAT} | awk -v OFS="	" '{print NR,$0}' | sort -k2,2 | join -t "	" -1 2 -2 1 - ${CONV} | cut -f 2-3 | sort -k1,1 > ${BASE}_feat.tmp &

wait

sed '1,3d;s/ /	/g;' ${MTX} | sort -k1,1 -S 8G -T $PWD | join -t "	" -j 1 ${BASE}_feat.tmp - | cut -f 2- | sort -k2,2 -S 8G -T $PWD | join -t "	" -1 1 -2 2 ${BASE}_bc.tmp - | awk -v OFS="	" '{print $2 ";" $3,$4}' > ${BASE}_uniq.tmp 

if [ $? -ne 0 ]; then
    echo "Error with extracting unique matrix output" >&2
    exit 1
else
    rm ${BASE}_bc.tmp ${BASE}_feat.tmp
fi

BC="${DIR}/10X_locus/Multi/${LIBID}/barcodes.csv"
FEAT="${DIR}/10X_locus/Multi/${LIBID}/features.csv"
MTX="${DIR}/10X_locus/Multi/${LIBID}/matrix.mtx"

sed '1d' ${BC} | awk -v OFS="	" '{print NR,$0 "-1"}' | sort -k1,1 -S 8G -T $PWD > ${BASE}_bc.tmp &
sed '1d' ${FEAT} | awk -v OFS="	" '{print NR,$0}' | sort -k2,2 | join -t "	" -1 2 -2 1 - ${CONV} | cut -f 2-3 | sort -k1,1 > ${BASE}_feat.tmp &

wait

sed '1,3d;s/ /	/g;' ${MTX} | sort -k1,1 -S 8G -T $PWD | join -t "	" -j 1 ${BASE}_feat.tmp - | cut -f 2- | sort -k2,2 -S 8G -T $PWD | join -t "	" -1 1 -2 2 ${BASE}_bc.tmp - | awk -v OFS="	" '{print $2 ";" $3,$4}' > ${BASE}_multi.tmp 

if [ $? -ne 0 ]; then
    echo "Error with extracting multi matrix output" >&2
    exit 1
else
    rm ${BASE}_bc.tmp ${BASE}_feat.tmp
fi

cat ${BASE}_{uniq,multi}.tmp | sort -k1,1 -S 18G -T $PWD | groupBy -g 1 -c 2 -o sum > "processed/${BASE}_locus_counts.txt"

if [ $? -ne 0 ]; then
    echo "Error with generating combined output" >&2
    exit 1
else
    rm ${BASE}_uniq.tmp ${BASE}_multi.tmp
fi

SCRIPT="${SCRIPTDIR}/src/multijoin"

${SCRIPT} -k 1 -v 2 -h ${SUBFAMTRUTH} processed/${BASE}_subfam_counts.txt > ${BASE}_subfam_comparison.txt &
${SCRIPT} -k 1 -v 2 -h ${LOCUSTRUTH} processed/${BASE}_locus_counts.txt > ${BASE}_locus_comparison.txt &

wait

if [ $? -ne 0 ]; then
    echo "Error with joining results" >&2
    exit 1
fi

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
