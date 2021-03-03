#!/bin/bash

dir='/p/largedata/hhb19/jstreffi/runtime/oifsamip'

#res='T1279'
for res in T159 T511 T1279
do
	if [ $res == T1279 ]; then
		start=101
		end=130
	elif [ $res == T511 ]; then
		start=201
		end=264
	elif [ $res == T159 ]; then
		start=301
		end=600
	fi
	
	for e in 16
	do
		#./sevf_resfix.sh  $e $start $end $res placeholder $dir
		for var in pch
		do
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
	done
done
