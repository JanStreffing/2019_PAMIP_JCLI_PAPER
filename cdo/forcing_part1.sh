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
	for p in $var
	do
		rm -rf ${p}_cat.nc
		printf "     Working on paramter ${p}\n"
		if [[ $res == 'T159' || $res == 'T511' ]]
		then
			if [ $var == T2M ] ||  [ $var == MSL ] || [ $var == z500 ] 
			then
				cdo monmean  -remapcon,r320x160 -seltimestep,244/1703 -inttime,2000-04-01,06:00:00,6hour ../00001/${p}_00001.nc ${p}_monmean.nc
			else
                                cdo monmean  -remapcon,r320x160 -seltimestep,3/14 ../00001/${p}_00001.nc ${p}_monmean.nc
			fi
		else
			for l in {2..7}
			do
				printf "      Leg number ${l}\n"
				cdo -s cat ../$(printf "%05g" l)/${p}_$(printf "%05g" l).nc ${p}_cat.nc
			done
                        if [ $var == T2M ] ||  [ $var == MSL ] || [ $var == z500 ]
			then
				cdo monmean -seltimestep,1/1459 -inttime,2000-06-01,06:00:00,6hour -remapcon,r320x160 ${p}_cat.nc ${p}_monmean.nc
			else
				cdo monmean -remapcon,r320x160 ${p}_cat.nc ${p}_monmean.nc
			fi
		fi
		if [ $var == SF ]
		then
			cdo -mulc,334000 -sellonlatbox,-180,180,0,90 -ifthen /p/project/chhb19/jstreffi/obs/hadisst2/sic_march_mask.nc ${p}_monmean.nc ${p}_monmean_masked.nc 
		else
			cdo -sellonlatbox,-180,180,0,90 -ifthen /p/project/chhb19/jstreffi/obs/hadisst2/sic_march_mask.nc ${p}_monmean.nc ${p}_monmean_masked.nc
		fi	
		rm -rf ${p}_cat.nc ${p}_monmean.nc

	done
	pwd
done


