#!/bin/sh -l
#SBATCH -t 12:0:0
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu=10G
#SBATCH -J assess_iRescue
#SBATCH -e %x-%j.err
#SBATCH -o %x-%j.out
#SBATCH --export=ALL

usage(){
    echo "
    Usage: sbatch $0 subfam 
                     [iRescue subfamily output directory]
                     [T2T TEsubfam simulated counts]

           sbatch $0 locus
                     [iRescue locus output directory]
                     [T2T TElocus simulated counts]
" >&2
    exit 1
}

if [ -z "$2" ];then
    usage
fi

SCRIPTDIR=$(dirname $0)
TYPE="$1"
DIR="$2"
TRUTH="$3"

LIBID=$(basename $DIR | sed 's/_iRescue.*$//;')
LIBID="${BASE}_iRescue_${TYPE}"
DIR="${DIR}/counts"

BC="${DIR}/barcodes.tsv.gz"
FEAT="${DIR}/features.tsv.gz"
MTX="${DIR}/matrix.mtx.gz"

gunzip -cf "${BC}" | awk -v OFS="," '{print $0 "-1",NR}' | sort -k2,2 -t "," > "${LIBID}_bc.csv" &
gunzip -cf "${FEAT}" | awk -F "	" -v OFS="," '$1==$2{print $1,NR};$1!=$2{print $1 ":TE",NR}' | sort -k2,2 -t "," > "${LIBID}_feat.csv" &

wait

if [ ! -d "processed" ]; then
    mkdir processed
fi

gunzip -cf "${MTX}" | sed '1,3d;s/ /,/g' | grep -v -e "-nan" | sort -k2,2 -S 2G -T $PWD -t "," | join -t "," -j 2 - "${LIBID}_bc.csv" | sort -k2,2 -S 2G -T $PWD -t "," | join -t "," -j 2 - "${LIBID}_feat.csv" | awk -F "," -v OFS="	" '{print $4 ";" $5,$3}' | sort -k1,1 -S 5G -T $PWD > "processed/${LIBID}_counts.txt"

if [ $? -ne 0 ];then
    echo "Error in annotating matrix" >&2
else
    echo "Done with ${TYPE} annotation" >&2
    rm ${LIBID}_{bc,feat}.csv
fi


SCRIPT="${SCRIPTDIR}/src/multijoin"
BASE="${LIBID}"

${SCRIPT} -k 1 -v 2 -h ${TRUTH} processed/${BASE}_counts.txt > ${BASE}_comparison.txt

if [ $? -ne 0 ]; then
    echo "Error with joining results" >&2
    exit 1
fi

if [ ! -d "comparison" ]; then
    mkdir comparison
fi

SCRIPT="${SCRIPTDIR}/src/compare_run_to_simulated_truth.pl"

perl ${SCRIPT} ${BASE}_comparison.txt > comparison/${BASE}_comparison_results.txt

rm ${BASE}_comparison.txt

if [ ! -d "summary" ]; then
    mkdir summary
fi

SCRIPT="${SCRIPTDIR}/src/make_accuracy_summary.pl"

perl ${SCRIPT} comparison/${BASE}_comparison_results.txt > summary/${BASE}_comparison_summary.txt

echo "Done"
