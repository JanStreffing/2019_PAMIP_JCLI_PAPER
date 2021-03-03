#!/bin/ksh
#SBATCH --job-name=OPP
#SBATCH -p shared
#SBATCH --time=08:00:00
#SBATCH -A ba1035

e=$1
start=$2
end=$3
res=$4
var=$5
dir=$6

for i in {${start}..${end}}
do
	echo "   ====================================================="
	echo "   exec E$(printf "%03g" i) for MiLES blocking analysis "
	echo "   ====================================================="
	cd /p/project/chhb19/jstreffi/software/MiLES_b
	./wrapper_miles.sh namelist/namelist.tmpl ${res} $(printf "%03g" ${i}) ${e}
done


