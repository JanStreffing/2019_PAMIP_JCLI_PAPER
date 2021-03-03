#!/bin/ksh
#SBATCH --job-name=OPP
#SBATCH -p shared
#SBATCH --time=08:00:00
#SBATCH -A ab0246



e=$1
start=$2
end=$3
res=$4
var=$5
dir=$6


cd $dir/$res/Experiment_$e
pwd
echo "   ====================================================="
echo "   Cat $var for Experiment $e"
echo "   ====================================================="

if [ $var == 'T2M' ]
then
	operator=daymin
else
	operator=daymax
fi

for i in {$2..$3}
do
	echo "   ====================================================="
	echo "   Cat $var for run E$(printf "%03g" i)"
	echo "   ====================================================="
	mkdir E$(printf "%03g" i)/outdata/oifs/extreme
	echo $dir/$res/Experiment_$e/E$(printf "%03g" i)/outdata/oifs/extreme
	cd E$(printf "%03g" i)/outdata/oifs/extreme

	rm -rf tmp

	if [[ $res == 'T159' || $res == 'T511' ]]
	then
		cdo -$operator -sellonlatbox,-180,180,75,90 -seltimestep,916/1519 ../00001/${var}_00001.nc ${var}_NP.nc
		cdo -$operator -sellonlatbox,-180,180,30,60 -seltimestep,916/1519 ../00001/${var}_00001.nc ${var}_NH.nc
		cdo -$operator -sellonlatbox,0,65,30,60 -seltimestep,916/1519 ../00001/${var}_00001.nc ${var}_EU.nc
		cdo -$operator -sellonlatbox,65,130,30,60 -seltimestep,916/1519 ../00001/${var}_00001.nc ${var}_AS.nc
		cdo -$operator -sellonlatbox,-125,-60,30,60 -seltimestep,916/1519 ../00001/${var}_00001.nc ${var}_NA.nc
	else
		rm -rf tmp
		for x in {4..7}
		do
			printf "      Leg number ${l}\n"
			cdo cat ../0000${x}/${var}_0000${x}.nc tmp 
		done
		cdo seltimestep,47/197 -$operator -sellonlatbox,-180,180,75,90  -inttime,2000-10-01,06:00:00,6hour tmp ${var}_NP.nc
		cdo seltimestep,47/197 -$operator -sellonlatbox,-180,180,30,60  -inttime,2000-10-01,06:00:00,6hour tmp ${var}_NH.nc
		cdo seltimestep,47/197 -$operator -sellonlatbox,0,65,30,60  -inttime,2000-10-01,06:00:00,6hour tmp ${var}_EU.nc
		cdo seltimestep,47/197 -$operator -sellonlatbox,65,130,30,60  -inttime,2000-10-01,06:00:00,6hour tmp ${var}_AS.nc
		cdo seltimestep,47/197 -$operator -sellonlatbox,-125,-60,30,60  -inttime,2000-10-01,06:00:00,6hour tmp ${var}_NA.nc
		rm tmp
	fi

	cd ../../../..
done
