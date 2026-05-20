################################################
####  PSU excetion test script
################################################
path=$1
log_file=$2
sample=$3

root_path=$(pwd)
csv_file=${root_path}/$log_file
psuex_file=${root_path}/../psuex.tmp
cd $path

declare -i psuex_err=0

echo -e "--- Test make ---" | tee -a $csv_file
#### Building test : make clean
make clean  | tee -a $csv_file
psuex_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $psuex_check_flag -ne 0 ]; then
    psuex_err=1
    echo "Fail : make clean failed." | tee -a $csv_file
    echo "FAIL" | tee -a $csv_file
    exit
fi

#### Building test : make
make  | tee -a $csv_file
psuex_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $psuex_check_flag -ne 0 ]; then
    psuex_err=1
    echo "Fail : make failed." | tee -a $csv_file
    echo "FAIL" | tee -a $csv_file
    exit
fi

echo "-----------------" | tee -a $csv_file


echo -e "\n------- Unplug PSU Power Cord Test ------------" | tee -a $csv_file

## Check PSU module
./psu -r > $psuex_file
psu0_lines=$(cat $psuex_file | grep "PSU0" | wc -l)
psu1_lines=$(cat $psuex_file | grep "PSU1" | wc -l)

if [[ "$psu0_lines" -eq 0 && "$psu1_lines" -eq 1 ]]; then
    psuex_err=1
    echo "Fail : PSU error." | tee -a $csv_file
    echo "FAIL" | tee -a $csv_file
    exit
fi

if [ "$psu0_lines" -eq 1 ]; then
    echo "No module PSU0" | tee -a  $csv_file
    exit
fi

if [ "$psu1_lines" -eq 1 ]; then
    echo "No module PSU1"  | tee -a  $csv_file
    exit
fi

function check_power_status() {
    while true; do
        read -p "Is the power has been unplugged? (y/n)" yn < /dev/tty
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
   done
}

### Test unplugged status of psu0
echo "Please unplug the first power cord and key \"yes\"."
check_power_status
psu_check_flag=$?

if [  "$psu_check_flag" -eq 0 ]; then
     echo "./psu -r" | tee -a $csv_file
    ./psu -r | tee -a  $csv_file
    ./psu -r > $psuex_file
    psu_status=$(cat $psuex_file | grep "Power is unplugged" | grep "PSU0" | wc -l)
    if [ "$psu_status" -ne 1 ]; then
        psuex_err=1
        echo "Fail : Unplugged power test of PSU0." | tee -a  $csv_file
    else
        echo "Pass : Unplugged power test of PSU0." | tee -a  $csv_file
    fi
else
    echo "Quit."
    psuex_err=1
    exit 1
fi

echo "Please plug the first power cord."

### Test unplugged status of psu1
echo "Please unplug the second power cord and key \"yes\"."
check_power_status
psu_check_flag=$?

if [  "$psu_check_flag" -eq 0 ]; then
     echo "./psu -r" | tee -a $csv_file
    ./psu -r | tee -a  $csv_file
    ./psu -r > $psuex_file
    psu_status=$(cat $psuex_file | grep "Power is unplugged" | grep "PSU1" | wc -l)
    if [ "$psu_status" -ne 1 ]; then
        psuex_err=1
        echo "Fail : Unplugged power test of PSU1." | tee -a  $csv_file
    else
        echo "Pass : Unplugged power test of PSU1." | tee -a  $csv_file
    fi
else
    echo "Quit."
    psuex_err=1
    exit 1
fi

#### Test result
if [ "$psuex_err" -eq 0 ]; then
    echo "PSUEx PASS" | tee -a $csv_file
else
    echo "PSUEx FAIL" | tee -a $csv_file
fi
