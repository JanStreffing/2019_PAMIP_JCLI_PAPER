#!/bin/ksh
#SBATCH --job-name=OPP
#SBATCH -p shared
#SBATCH --time=08:00:00
#SBATCH -A ba1035

e=$1
start=$2
end=$3
res=$4
p=$5
dir=$6


echo "   ====================================================="
echo "   Splitting Experiment $e", Variable $p into seasonal
echo "   ====================================================="

for i in `seq $2 $3`
do
	echo Experiment_$e/E$(printf "%03d" i)/outdata/oifs/seasonal_mean/${p}_seasmean.nc
	cdo splitseas $dir/$res/Experiment_$e/E$(printf "%03d" i)/outdata/oifs/seasonal_mean/${p}_seasmean.nc $dir/$res/Experiment_$e/E$(printf "%03d" i)/outdata/oifs/seasonal_mean/${p}_
done
cdo splitseas $dir/$res/Experiment_$e/ensemble_mean/${p}_ensmean.nc $dir/$res/Experiment_$e/ensemble_mean/${p}_ensmean_
if [ $p == 'U' ]; then
	cdo splitseas $dir/$res/Experiment_$e/ensemble_mean/${p}_ensmean_nh.nc $dir/$res/Experiment_$e/ensemble_mean/${p}_ensmean_nh_
fi
