#!/bin/ksh

in=/p/largedata/hhb19/jstreffi/runtime/oifsamip
out=/p/project/chhb19/jstreffi/postprocessing/PAMIP
wd=`pwd`

##############################
#     EP-FLUX plotting       #
##############################

#cd $in
#ncl /p/project/chhb19/jstreffi/postprocessing/ncl-plot-scripts/epflux.ncl res="159" exp1="11" exp2="16"
#ncl /p/project/chhb19/jstreffi/postprocessing/ncl-plot-scripts/epflux.ncl res="511" exp1="11" exp2="16"
#ncl /p/project/chhb19/jstreffi/postprocessing/ncl-plot-scripts/epflux.ncl res="1279" exp1="11" exp2="16"




##############################
#     SEVF calculation       #
##############################

res='T1279'
#for res in {T159,T511}
#do
	if [ $res == T1279 ]; then
		start=101
		end=180
	elif [ $res == T511 ]; then
		start=201
		end=300
	elif [ $res == T159 ]; then
		start=599
		end=600
	fi
	
	for e in 11 16
	do
		for i in {${start}..${end}}
		do
			for task in VTEM; do #'VTEM' 'SEVF'
				if [ $task == SEVF ]; then
					echo "   ====================================================="
					echo "   Calculating SEVF for $res E$(printf "%03g" i) "
					echo "   ====================================================="
					cd $in/$res/Experiment_${e}/E$(printf "%03g" i)/outdata/oifs/bandpass
					pwd
					ls
					ncl ${wd}/sevf.ncl
				elif [ $task == VTEM ]; then
					echo "   ====================================================="
					echo "   Calculating VTEM for $res E$(printf "%03g" i) "
					echo "   ====================================================="
					ncl "expm=$i" "e=$e" 'res="T1279"' ./tem_dynvar_openifs_prim_nowap.ncl
				fi
			done
		done
	done
#done
