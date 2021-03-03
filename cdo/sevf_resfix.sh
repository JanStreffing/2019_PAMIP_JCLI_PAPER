#!/bin/ksh
#SBATCH --job-name=B$1
#SBATCH -p batch
#SBATCH --time=08:00:00
#SBATCH -A chhb19

e=$1
start=$2
end=$3
res=$4
var=$5
dir=$6


for i in {${start}..${end}}
do
	cd $dir/$res/Experiment_$e/E$(printf "%03g" i)/outdata/oifs/bandpass/
	cdo remapcon,r320x80 sevf.nc sevf_rmp.nc
done

