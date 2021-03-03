#!/bin/ksh
#SBATCH --job-name=OPP
#SBATCH -p shared
#SBATCH --time=08:00:00
#SBATCH -A ba1035

for r in T159 T511
do
  for e in 11 12 13 16
  do
    echo "   ====================================================="
    echo "   Processing Experiment $e"
    echo "   ====================================================="
    for p in V T U T2M MSL z500
    do
      cdo splitseas Experiment_$e/ensemble_mean/${p}_ensmean.nc Experiment_$e/ensemble_mean/${p}_ensmean_
    done
  done
done
