#!/bin/bash
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


  echo "   ====================================================="
  echo "   Calculating ens mean for Experiment $e", Var $var
  echo "   ====================================================="
  mkdir $dir/$res/Experiment_${e}/ensemble_mean
  for p in $var
  do
    printf "     Working on paramter ${p}\n"
    cdo -O ensmean $dir/$res/Experiment_${e}/E[0-1][0-9][0-9]/outdata/oifs/seasonal_mean/${p}_seasmean.nc $dir/$res/Experiment_${e}/ensemble_mean/${p}_ensmean.nc
    if [ $p == "U" ]; then
      cdo -O ensmean $dir/$res/Experiment_${e}/E[0-1][0-9][0-9]/outdata/oifs/seasonal_mean/${p}_seasmean_nh.nc $dir/$res/Experiment_${e}/ensemble_mean/${p}_ensmean_nh.nc
    fi
  done
