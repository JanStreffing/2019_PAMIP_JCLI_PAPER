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
	echo "   prep forcing monthly mean values for E$(printf "%03g" i)"
	echo "   ====================================================="
	mkdir $dir/$res/Experiment_${e}/E$(printf "%03g" i)/outdata/oifs/forcing
	cd $dir/$res/Experiment_${e}/E$(printf "%03g" i)/outdata/oifs/forcing
	pwd
	cdo enssum SSR_monmean_masked.nc STR_monmean_masked.nc SSHF_monmean_masked.nc SLHF_monmean_masked.nc SF_monmean_masked.nc NET_SURF_forcing.nc
	cdo fldmean NET_SURF_forcing.nc NET_SURF_forcing_glob.nc
	cdo fldmean T2M_monmean_masked.nc T2M_forcing_glob.nc
done


