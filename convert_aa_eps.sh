
#Path and pattern for grib files
# Without EPS:
# make_netcdf_files.sh 2015041500 2015041506 /path_to_archive/@YYYY@/@MM@/@DD@/@HH@
# With EPS:
# make_netcdf_files.sh 015041500 2015041506 /path_to_archive/@YYYY@/@MM@/@DD@/@HH@/@EEE@
#(year: @YYYY@, month: @MM@, day: @DD@, hour: @HH@, ensemble member: @EEE@)
ptrn="/lustre/storeA/users/rafaelk/PL20171127"

#Path to config file:
cnfg="/lustre/storeB/users/rafaelk/utils/fimex_tools/AromeEPSGribReaderConfigHIRLAM.xml"

#Path and pattern for output files 
#(year: @YYYY@, month: @MM@, day: @DD@, hour: @HH@, ensemble member: @EEE@)
outp="/lustre/storeB/users/rafaelk/utils/fimex_tools/"

dtg_start=2017112700		# -Start time
dtg_end=2017112700		# -Stop time
I=3 				# -I forecast intervall (default: 3)
p="fc"                  	# -p prefix (default: fc)
s="@,@_fp,@_sfx,@_full_sfx"	# -s suffix Provide suffixes as a comma separated list with leading '@' i.e. (@,@_fp,@_sfx).
l=66				# -l prognostic length (default 66)
o="fc@YYYY@@MM@@DD@@HH@.nc"	# -o output file (default: ${prefix}@YYYY@@MM@@DD@@HH@.nc)";
d="./"				# -d output folder (default: ./)
S=0				# -S skip first (default: false)
e=0				# -e EPS (default: false)
E=0				# -E merge EPS data into single file (default: false)
m=10				# -m eps-members (default: 10)
v="all"				# -v variables to extract (default: all - comma separated list)
w="./mnf_tmp"			# -w working directory for temporary files (default: ./mnf_tmp)
D=1				# -D Debug mode (without cleanup) (default: false)


set -x
./make_netcdf_files.sh $dtg_start $dtg_end $ptrn -I $I -p $p -s $s -l $l -o $o -d $d -S $S -e $e -E $E -m $m -v $v -w $w -D $D
set +x

