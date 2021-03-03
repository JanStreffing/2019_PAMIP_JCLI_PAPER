#!/bin/bash

dir='/p/largedata/hhb19/jstreffi/runtime/oifsamip'

for res in  'T159' 'T511' 'T1279'
do
	if [ $res == T1279 ]; then
		start=101
		end=200
	elif [ $res == T511 ]; then
		start=201
		end=300
	elif [ $res == T159 ]; then
		start=301
		end=600
	fi
	
	for e in 11 16
	do
		break
		for var in HR_T2M #HR_PRECIP T2M MSL U T z500 Z
		do
			if [ "$var" == "z500" ]
			then
				printf "z500_cat.sh"
				./z500_cat.sh $e $start $end $res $var $dir
			fi
			if [ "$var" == "HR_T2M" ]
			then
				printf "extremes for $var"
				./extreme.sh $e $start $end $res $var $dir
			fi
			if [ "$var" == "HR_PRECIP" ]
			then
				printf "extremes for $var"
				./extreme.sh $e $start $end $res $var $dir &
			fi
			echo $res, $start, $end
			./djfm_mean.sh $e $start $end $res $var $dir
			./monmean.sh $e $start $end $res $var $dir
			./monmean_mid_lat.sh $e $start $end $res $var $dir
			./seasmean.sh $e $start $end $res $var $dir
			#./fix_monthly.sh $e $start $end $res $var $dir
			#./fix_layers.sh $e $start $end $res $var $dir
		done
		#./forcing_part1.sh $e $start $end $res SSR $dir
		#./forcing_part1.sh $e $start $end $res STR $dir
		#./forcing_part1.sh $e $start $end $res SSHF $dir
		#./forcing_part1.sh $e $start $end $res SLHF $dir
		#./forcing_part1.sh $e $start $end $res SF $dir
		#./forcing_part1.sh $e $start $end $res T2M $dir
		#./forcing_part2.sh $e $start $end $res placeholder $dir
		#./bandpass.sh $e $start $end $res placeholder $dir
	done

	for e in 11 16
	do
		./sevf_resfix.sh  $e $start $end $res placeholder $dir
		for var in U T T2M z500 MSL epf pch HR_T2M HR_PRECIP synact
		do
			break
			if [ "$var" == "synact" ]
			then
				printf "synact_PAMIP.job"
				./synact_PAMIP.job $e $start $end $res $var $dir
				#./post_data_oifs_synact_stddev.job $e $start $end $res $var $dir
			elif [ "$var" == "nao" ]
			then
				printf "post_data_oifs_nao.job"
				./post_data_oifs_nao.job $e $start $end $res $var $dir
			elif [ "$var" == "pch" ]
			then
				printf "post_data_oifs_pch.job"
				./post_data_oifs_pch.job $e $start $end $res $var $dir
			elif [ "$var" == "epf" ]
			then
				printf "epflux_cat.job"
				./epflux_cat.job $e $start $end $res $var $dir
			else
				printf "ensmean.sh"
				./ensmean.sh $e $start $end $res $var $dir
				./split_to_seasons.sh $e $start $end $res $var $dir
			fi
		done
		if [ "$e" == "11" ]
		then
			./sinuosity.job $e $start $end $res $var $dir
			./MiLES_prep.sh $e $start $end $res placeholder $dir
			./MiLES_exec.sh $e $start $end $res $var $dir
		elif [ "$e" == "16" ]
		then
			./sinuosity2.job $e $start $end $res $var $dir
			./MiLES_prep.sh $e $start $end $res placeholder $dir
			./MiLES_exec_b.sh $e $start $end $res $var $dir
		fi
	done
done
