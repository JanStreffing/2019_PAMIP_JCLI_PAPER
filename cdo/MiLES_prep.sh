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
	echo "   prep E$(printf "%03g" i) for MiLES blocking analysis "
	echo "   ====================================================="
	cd $dir/$res/Experiment_${e}/E$(printf "%03g" i)/outdata/oifs/z500_6hourly
	pwd
	rm -rf zg50000_${res}_$(printf "%03g" ${i})_${e}_fullfile.nc
	cdo sellonlatbox,0,360,0,90 -remapbil,r144x73 -setname,zg -setunit,Pa z500_$(printf "%03g" ${i})_daily.nc temp2
	cdo seltimestep,1/214 temp2 1
	cdo seltimestep,215/365 temp2 2
	cdo -settaxis,2001-06-01,09:00:00,1day 1 3
	cdo cat 2 3 zg50000_${res}_$(printf "%03g" ${i})_${e}_fullfile.nc
	rm -f temp1 temp2 1 2 3
	mkdir  $dir/MILES/data/zg50000/${res}_$(printf "%03g" ${i})/
	mkdir  $dir/MILES/data/zg50000/${res}_$(printf "%03g" ${i})/${e}/
	ln -s $dir/$res/Experiment_${e}/E$(printf "%03g" i)/outdata/oifs/z500_6hourly/zg50000_${res}_$(printf "%03g" ${i})_${e}_fullfile.nc $dir/MILES/data/zg50000/${res}_$(printf "%03g" ${i})/${e}/zg50000_${res}_$(printf "%03g" ${i})_${e}_fullfile.nc
done


