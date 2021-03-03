#! /bin/ksh -l

export ENSEMBLE_oifs=1
for e in 13
do
  for i in {90..100}
  do
    echo "        ====================================================="
    echo "        Removing sinuosity folder for  $(printf "%03g" i)"
    echo "        ====================================================="
    ls Experiment_${e}/E$(printf "%03g" i)/outdata/oifs/sinuosity/
    # rm -rf Experiment_${e}/E$(printf "%03g" i)/outdata/oifs/sinuosity/
  done
done
