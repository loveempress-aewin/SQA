################################################
####  PSU module test script
################################################
number=$1

path="sample_code/psu/"
log_file="csv/psu.csv"

if [ "$number" -gt 1 ]; then
    echo "Power index is 0 or 1."
    exit 1
fi

root_path=$(pwd)
csv_file=${root_path}/$log_file
psumo_file=${root_path}/psumo.tmp   

cd $path
ver=$(ls | head -n 10 | tail -1)
cd $ver

declare -i psumo_err=0

echo -e "--- Test make ---" | tee -a $csv_file 
#### Building test : make clean
make clean  | tee -a $csv_file 
psumo_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $psumo_check_flag -ne 0 ]; then
    psumo_err=1
    echo "Fail : make clean failed." | tee -a $csv_file 
    echo "FAIL" | tee -a $csv_file 
    exit 
fi

#### Building test : make
make  | tee -a $csv_file  
psuex_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $psumo_check_flag -ne 0 ]; then
    psumo_err=1
    echo "Fail : make failed." | tee -a $csv_file 
    echo "FAIL" | tee -a $csv_file 
    exit 
fi

echo "-----------------" | tee -a $csv_file  


echo -e "\n------- Unplug PSU$number Module Test ------------" | tee -a $csv_file 

### Test module status
echo "./psu -r" | tee -a $csv_file 
./psu -r | tee -a  $csv_file	     
./psu -r > $psumo_file
psu_status=$(cat $psumo_file | grep "Module has been removed or the device has failed" | grep "PSU$number" | wc -l)
if [ "$psu_status" -ne 1 ]; then
    psumo_err=1
    echo "Fail : Unplugged module test of PSU$number." | tee -a  $csv_file
else
    echo "Pass : Unplugged module test of PSU$number." | tee -a  $csv_file
fi

#### Test result
if [ "$psumo_err" -eq 0 ]; then
    echo "PSU$number PASS" | tee -a $csv_file 
else
    echo "PSU$number FAIL" | tee -a $csv_file 
fi
