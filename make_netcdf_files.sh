#!/bin/bash

# Default values
fcint=3
prefix="fc"
config="AromeGribReaderConfig.xml"
template=""
suffix=""
output=""
output_dir="./"
prog_length_in=66
llint=1
skip_first=0
eps=0
merge_eps=0
eps_members=10
vrb="all"
wdir="./mnf_tmp"
sfx=1
atm=1
debug=0

set -- $(getopt I:i:c:p:s:o:d:l:e::E::m:v:w:h:f:a:D:: "$@")
while [ $# -gt 0 ]; do
  case "$1" in
    (-I) fcint=$2; shift;;
    (-i) llint=$2; shift;;
    (-c) config=$2; shift;;
    (-p) prefix=$2; shift;;
    (-s) suffix=$2; shift;;
    (-l) prog_length_in=$2; shift;;
    (-o) output=$2; shift;;
    (-d) output_dir=$2; shift;;
    (-S) skip_first=1; shift;;
    (-e) eps=1;;
    (-E) merge_eps=1;;
    (-m) eps_members=$2; shift;;
    (-v) vrb="$2"; shift;;
    (-w) wdir=$2; shift;;
    (-f) sfx=$2; shift;;
    (-a) atm=$2; shift;;
    (-D) debug=1;;  
    (-h)
	echo ""
	echo "Usage: $0 DTG-START DTG-END ARCHIVE-PATTERN [-I FCINT] [-l FORECAST-LENGTH]";
	echo ""
	echo "Without EPS:"
  	echo "$0 2015041500 2015041506 /work/mifata/harmonie/AM25_oper/archive/@YYYY@/@MM@/@DD@/@HH@";
	echo ""
	echo "With EPS:"
  	echo "$0 2015041500 2015041506 /work/mifata/harmonie/AM25_oper/archive/@YYYY@/@MM@/@DD@/@HH@/@EEE@";
	echo "";
	echo "";	
	echo "-I forecast intervall (default: 3)";
        echo "-i forecast length (default: 1)";
        echo "-c config file (default: ./AromeGribReaderConfig.xml)";
        echo "-p prefix";
        echo "-s suffix";
        echo "-l prognostic length (default 66)";
        echo "-o output file (default: ${prefix}@YYYY@@MM@@DD@@HH@${suffix}.nc)";
        echo "-d output folder (default: ./)";
        echo "-S skip first (default: false)";
	echo "-e EPS (default: false)";
        echo "-E merge EPS data into single file (default: false)";
        echo "-m eps-members (default: 10)";
        echo "-v variables to extract (default: all - comma separated list)";
        echo "-w working directory for temporary files (default: ./mnf_tmp)";
        echo "-f include surface files (default: true)";
        echo "-a include atmosphere files (default: true)";
        echo "-D Debug mode (without cleanup) (default: false)";	
	exit 1;;
    (--) shift; break;;
    (-*) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
    (*)  break;;
    
  esac
  shift
done

if [ "$#" -ne "3" ]; then
  echo "Usage: $0 DTG-START DTG-END ARCHIVE-PATTERN [-I FCINT] [-l FORECAST-LENGTH]";
  echo ""
  echo "Without EPS:"
  echo "$0 2015041500 2015041506 /work/mifata/harmonie/AM25_oper/archive/@YYYY@/@MM@/@DD@/@HH@";
  echo ""
  echo "With EPS:"
  echo "$0 2015041500 2015041506 /work/mifata/harmonie/AM25_oper/archive/@YYYY@/@MM@/@DD@/@HH@/@EEE@";
  echo ""  
  exit 1
else
  startDTG=$1
  endDTG=$2
  pattern=$3
fi

# Default output file and folder
# test and remove [ "$output_dir" == "" ] && output_dir="./"
[ "$output" == "" ] && output="${prefix}@YYYY@@MM@@DD@@HH@${suffix}"
if [ $eps -ne 1 ]; then
  $eps_members=0
fi
if [ "$vrb" == "all" ]; then
  vrbtmp="";
else
  #vrbtmp=$vrb
  vrbtmp=`echo $vrb | sed -e "s#,# #g"`
fi

echo ""
echo $startDTG $endDTG $pattern
echo ""
echo "Forecast Intervall: $fcint"
echo "Forecast length: $llint" 
echo "Output-format: $output"
echo "Output-directory: $output_dir"
echo "Prognostic length: $prog_length_in"
echo "Config: $config"
[ "$skip_first" -eq 1 ] && echo "Skipping first forecast step"
[ "$eps" -eq 1 ] && echo "EPS run with $eps_members members"
[ "$merge_eps" -eq 1 ] && echo "Mergin EPS into single files."
[ "$atm" -eq 1 ] && echo "Including atmosphere files."
[ "$sfx" -eq 1 ] && echo "Including surface files."
echo "Extracting variables: $vrb -> $vrbtmp"
echo "Working directory: $wdir"
[ "$debug" -eq 1 ] && echo "Debug-mode."
echo ""


cwd=$(pwd)
dtg=$startDTG
# Loop over DTG
while [ "$dtg" -le "$endDTG" ]; do

  yyyy=`echo $dtg | cut -c1-4`
  yy=`echo $dtg | cut -c3-4`
  mm=`echo $dtg | cut -c5-6`
  dd=`echo $dtg | cut -c7-8`
  hh=`echo $dtg | cut -c9-10`
  dtgtmp="${yy}-${mm}-${dd} ${hh}:00"

  # Setting secondary run times 03Z, 09Z, 15Z and 21Z to a prognostic length
  # of the forecast intervall
  prog_length=$prog_length_in
  case $hh in 
     "03"|"09"|"15"|"21")
       prog_length=$fcint
     ;;
  esac
  
  #Setting eps variables
  mbr=0
  
  # Loop over ensemlbe members for indexing. Only one loop in case of eps=0
  while [ "$mbr" -lt "$eps_members" ]; do

    mbrtmp=$(printf "%03d" "$mbr")
	
    if [ $eps -eq 1 ]; then
      echo "Current member $mbrtmp"
    fi
 
    # Parse pattern, output, output-dir and temporary working directory from template to proper format
    subpattern=`echo $pattern | sed -e "s#@YYYY@#${yyyy}#g" -e "s#@YY@#${yy}#g" -e "s#@MM@#${mm}#g" -e "s#@DD@#${dd}#g" -e "s#@HH@#${hh}#g" -e "s#@EEE@#${mbrtmp}#g"`
    subw_dir=`echo $wdir | sed -e "s#@YYYY@#${yyyy}#g" -e "s#@YY@#${yy}#g" -e "s#@MM@#${mm}#g" -e "s#@DD@#${dd}#g" -e "s#@HH@#${hh}#g"`  
    suboutput=`echo "$output" | sed -e "s#@YYYY@#${yyyy}#g" -e "s#@YY@#${yy}#g" -e "s#@MM@#${mm}#g" -e "s#@DD@#${dd}#g" -e "s#@HH@#${hh}#g"`
    suboutput_dir=`echo $output_dir | sed -e "s#@YYYY@#${yyyy}#g" -e "s#@YY@#${yy}#g" -e "s#@MM@#${mm}#g" -e "s#@DD@#${dd}#g" -e "s#@HH@#${hh}#g"`
 
    # Create output directory if not existent and navigate there
    if [ ! -d "$suboutput_dir" ]; then
      mkdir -p "$suboutput_dir"
    fi
    cd $suboutput_dir
    suboutput_dir=$(pwd) # Storing directory as absolute path
    
    # Create temporary working directory
    cd $cwd
    if [ ! -d "$subw_dir" ]; then
      mkdir -p "$subw_dir"
    fi
    cd $subw_dir
    subw_dir=$(pwd) # Storing directory as absolute path

    # Controll of set variables
    echo "Pattern: $pattern -> $subpattern";
    echo "Wdir: $wdir -> $subw_dir";
    echo "Output: $output -> $suboutput";
    echo "Output_dir: $output_dir -> $suboutput_dir";

    echo "Creating symbolic links for $dtgtmp - $mbrtmp"
    if [ $atm -eq 1 ]; then
      # Loop through files and generating soft links to grib files
      for f in `ls -1 $subpattern/${prefix}??????????+???grib${suffix}`; do
        ff=`echo $f | awk -F + '{print $2}' | cut -c1-3`
        do=1
      
        if [ "$ff" == "000" ]; then
          ff=0
          [ "$skip_first" -eq 1 ] && do=0
        else
          ff=`echo $ff | sed 's/^0*//'`
        fi

        if [ "$do" -eq 1 ]; then
          if [ "$ff" -le "$prog_length" ]; then
            # Linking to grib messages.
            #set -x
            ln -s $f $suboutput.$ff.mbr$mbrtmp.grb
            #set +x
          else
            echo "$ff > $prog_length No proseccing done!"
          fi
        fi
      done
    fi
    if [ $sfx -eq 1 ]; then
      # Loop through files and generating soft links to grib files
      for f in `ls -1 $subpattern/${prefix}??????????+???grib_sfx${suffix}`; do
        ff=`echo $f | awk -F + '{print $2}' | cut -c1-3`
        do=1
      
        if [ "$ff" == "000" ]; then
          ff=0
          [ "$skip_first" -eq 1 ] && do=0
        else
          ff=`echo $ff | sed 's/^0*//'`
        fi
         if [ "$do" -eq 1 ]; then
          if [ "$ff" -le "$prog_length" ]; then
            # Linking to grib messages.
            #set -x
            ln -s $f $suboutput.$ff.sfx.mbr$mbrtmp.grb
            #set +x
          else
            echo "$ff > $prog_length No proseccing done!"
          fi
        fi
      done
    fi
    mbr=$((mbr+=1))
    cd $cwd
    echo "";
  done
  

  # Setup file for eps merged run
  if [ $eps -eq 1 -a $merge_eps -eq 1 ]; then

    suboutput=`echo "$output.nc" | sed -e "s#@YYYY@#${yyyy}#g" -e "s#@YY@#${yy}#g" -e "s#@MM@#${mm}#g" -e "s#@DD@#${dd}#g" -e "s#@HH@#${hh}#g"`
    echo "Output: $output -> $suboutput";

    setup_file="$suboutput_dir/setup$dtg.cfg"
    echo "setup_file: $setup_file"
    
    echo "# config file for program fimex" >> $setup_file
    echo "[input]" >> $setup_file
    echo "file=glob:$subw_dir/*.grb" >> $setup_file
    echo "config=$config" >> $setup_file
    echo "type=grib" >> $setup_file
    mbr=0
    while [ "$mbr" -le "$eps_members" ]; do
      mbrtmp=$(printf "%03d" "$mbr")
      echo "optional=memberName:mbr$mbrtmp" >> $setup_file
      mbr=$((mbr+=1))
    done

    echo "[extract]" >> $setup_file
    for variable in $vrbtmp; do
     echo "selectVariables=$variable" >> $setup_file
    done

    echo "[output]" >> $setup_file
    echo "file=$suboutput_dir/$suboutput" >> $setup_file
    echo "type=nc4" >> $setup_file

    echo "Converting..."
    set -x
    fimex -c $setup_file
    set +x
    echo ""

  # Setup file for eps run 
  elif [ $eps -eq 1 -a $merge_eps -ne 1 ]; then
    
    mbr=0
    while [ "$mbr" -lt "$eps_members" ]; do
      mbrtmp=$(printf "%03d" "$mbr")
      
      suboutput=`echo "$output-mbr$mbrtmp.nc" | sed -e "s#@YYYY@#${yyyy}#g" -e "s#@YY@#${yy}#g" -e "s#@MM@#${mm}#g" -e "s#@DD@#${dd}#g" -e "s#@HH@#${hh}#g"`
      echo "Output: $output -> $suboutput";

      setup_file="$suboutput_dir/setup$dtg-mbr$mbrtmp.cfg"
      echo "setup_file: $setup_file"
      
      echo "# config file for program fimex" >> $setup_file
      echo "[input]" >> $setup_file
      echo "file=glob:$subw_dir/*mbr$mbrtmp.grb" >> $setup_file
      echo "config=$config" >> $setup_file
      echo "type=grib" >> $setup_file      

      echo "[extract]" >> $setup_file
      for variable in $vrbtmp; do
        echo "selectVariables=$variable" >> $setup_file
      done

      echo "[output]" >> $setup_file
      echo "file=$suboutput_dir/$suboutput" >> $setup_file
      echo "type=nc4" >> $setup_file
	
      echo "Converting..."
      set -x
      fimex -c $setup_file
      set +x
      echo ""

      mbr=$((mbr+=1))
    done

  # Setup file for other runs
  else

    suboutput=`echo "$output.nc" | sed -e "s#@YYYY@#${yyyy}#g" -e "s#@YY@#${yy}#g" -e "s#@MM@#${mm}#g" -e "s#@DD@#${dd}#g" -e "s#@HH@#${hh}#g"`
    echo "Output: $output -> $suboutput";

    setup_file="$suboutput_dir/setup$dtg.cfg"
    echo "setup_file: $setup_file"
    
    echo "# config file for program fimex" >> $setup_file
    echo "[input]" >> $setup_file
    echo "file=glob:$subw_dir/*.grb" >> $setup_file
    echo "config=$config" >> $setup_file
    echo "type=grib" >> $setup_file
    
    echo "[extract]" >> $setup_file
    for variable in $vrbtmp; do
     echo "selectVariables=$variable" >> $setup_file
    done

    echo "[output]" >> $setup_file
    echo "file=$suboutput_dir/$suboutput" >> $setup_file
    echo "type=nc4" >> $setup_file

    echo "Converting..."
    set -x
    fimex -c $setup_file
    set +x
    echo ""
  
  fi
      
  dtg=`date -u --date "$dtgtmp $fcint hours" +%Y%m%d%H`
done

if [ $debug -eq 0 ]; then
  # Cleaning up
  echo "Cleaning up..."
  rm -r $subw_dir
  rm $suboutput_dir/setup*cfg
fi
cd $cwd
