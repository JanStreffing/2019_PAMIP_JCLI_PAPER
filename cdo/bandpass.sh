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
	echo "   ======================================================================"
	echo "   Applying 2 to 8 day band pass filter on 6hourly U V VO for E$(printf "%03g" i)"
	echo "   ======================================================================"
	rm -rf $dir/$res/Experiment_${e}/E$(printf "%03g" i)/outdata/oifs/bandpass
	mkdir $dir/$res/Experiment_${e}/E$(printf "%03g" i)/outdata/oifs/bandpass
	cd $dir/$res/Experiment_${e}/E$(printf "%03g" i)/outdata/oifs/bandpass
	pwd
	if [[ $res == 'T159' || $res == 'T511' ]]
	then
		/p/project/chhb19/jstreffi/software/miniconda3/envs/pyn_env_py2/bin/cdo -P 8 -sellonlatbox,-180,180,0,90 -seltimestep,697/1244 ../00001/6h_VO_00001.nc VO_bpf_prep &
		/p/project/chhb19/jstreffi/software/miniconda3/envs/pyn_env_py2/bin/cdo -P 8 -sellonlatbox,-180,180,0,90 -seltimestep,697/1244 ../00001/6h_V_00001.nc V_bpf_prep &
		/p/project/chhb19/jstreffi/software/miniconda3/envs/pyn_env_py2/bin/cdo -P 8 -sellonlatbox,-180,180,0,90 -seltimestep,697/1244 ../00001/6h_U_00001.nc U_bpf_prep &
		wait


	else
		for l in {4..7}
		do
			printf "      Leg number ${l}\n"
			cdo -s cat ../$(printf "%05g" l)/6h_VO_$(printf "%05g" l).nc VO_cat.nc &
			cdo -s cat ../$(printf "%05g" l)/6h_V_$(printf "%05g" l).nc V_cat.nc &
			cdo -s cat ../$(printf "%05g" l)/6h_U_$(printf "%05g" l).nc U_cat.nc &
			wait
		done
		/p/project/chhb19/jstreffi/software/miniconda3/envs/pyn_env_py2/bin/cdo -P 8 -sellonlatbox,-180,180,0,90 -seltimestep,208/756 VO_cat.nc VO_bpf_prep &
		/p/project/chhb19/jstreffi/software/miniconda3/envs/pyn_env_py2/bin/cdo -P 8 -sellonlatbox,-180,180,0,90 -seltimestep,208/756 V_cat.nc V_bpf_prep &
		/p/project/chhb19/jstreffi/software/miniconda3/envs/pyn_env_py2/bin/cdo -P 8 -sellonlatbox,-180,180,0,90 -seltimestep,208/756 U_cat.nc U_bpf_prep &
		wait
	fi

	export var=VO
	ncl /p/project/chhb19/jstreffi/postprocessing/ncl-plot-scripts/bandpass.ncl &
	export var=V
	ncl /p/project/chhb19/jstreffi/postprocessing/ncl-plot-scripts/bandpass.ncl &
	export var=U
	ncl /p/project/chhb19/jstreffi/postprocessing/ncl-plot-scripts/bandpass.ncl &
	wait
	rm *bpf_prep

	cdo -setreftime,2000-4-1 -settaxis,2000-11-22,00:00:00,6hour U_bpf.nc U_bpf_time.nc &
	cdo -setreftime,2000-4-1 -settaxis,2000-11-22,00:00:00,6hour V_bpf.nc V_bpf_time.nc &
	cdo -setreftime,2000-4-1 -settaxis,2000-11-22,00:00:00,6hour VO_bpf.nc VO_bpf_time.nc &
	wait

	cdo -seltimestep,37/516 VO_bpf_time.nc VO_bpf &
	cdo -seltimestep,37/516 V_bpf_time.nc V_bpf &
	cdo -seltimestep,37/516 U_bpf_time.nc U_bpf &
	wait

	cdo timstd VO_bpf VO_std &
	cdo timstd V_bpf V_std &
	cdo timstd U_bpf U_std &
	wait

	cdo -timmean -mul U_bpf VO_bpf COV_U_VO.nc &
	cdo -timmean -mul V_bpf VO_bpf COV_V_VO.nc &
	wait

	cdo merge COV_U_VO.nc COV_V_VO.nc EV.nc &
	cdo sqr COV_U_VO.nc COV_U_VO2.nc &
	cdo -chname,V,U -sqr COV_V_VO.nc COV_V_VO2.nc &
	wait

	cdo -sqrt -add COV_U_VO2.nc COV_V_VO2.nc Magnitude.nc

	rm COV* *_bpf_time.nc *bpf.nc
done

