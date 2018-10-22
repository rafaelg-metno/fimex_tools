ptrn="/lustre/storeB/project/nwp/alertness/eps/AROME-Arctic/@YYYY@/@MM@/@DD@/@HH@/mbr@EEE@"
cnfg="/lustre/storeB/users/rafaelk/fimex_tools/AromeGribReaderConfig.xml"
outp="/lustre/storeB/users/rafaelk/HarmonEPS/aa_eps"

set -x
./make_netcdf_files.sh 2018092000 2018092000 $ptrn -c $cnfg -d $outp -e -E -m 5 
set +x

