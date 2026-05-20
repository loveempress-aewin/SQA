################################################
####  LCM comport test script
################################################
path=$1
log_file=$2
sample=$3
btntest=$4
rm -rf $log_file

root_path=$(pwd)
csv_file=${root_path}/$log_file
help_file=${root_path}/help.tmp
cd $path

declare -i lcmcom_err=0

echo -e "--- Test make ---" | tee -a $csv_file
#### Building test : make clean
make clean  | tee -a $csv_file
lcmcom_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $lcmcom_check_flag -ne 0 ]; then
    lcmcom_err=1
    echo "Fail : make clean failed." | tee -a $csv_file
    echo "FAIL" | tee -a $csv_file
    exit
fi

#### Building test : make
make  >>  $csv_file 2>&1
lcmcom_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $lcmcom_check_flag -ne 0 ]; then
    lcmcom_err=1
    echo "Fail : make failed." | tee -a $csv_file
    echo "FAIL" | tee -a $csv_file
    exit
fi

echo "-----------------" | tee -a $csv_file

function check_lcmcom() {
    while true; do
        read -p "Is the LCM module working correct? (y/n)" yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
   done
}

#### Default
echo "./$path/$sample" | tee -a $csv_file
./$sample  | tee -a $csv_file

# Check help files
lcmcom_e=$(cat $csv_file | grep -e "-e")
if [ -z "$lcmcom_e" ]; then
	lcmcom_err=1
	echo "Fail : help() is error." | tee -a $csv_file
	echo "FAIL" | tee -a $csv_file
	exit
fi

#### Disable backlight test
echo -e "\n--- Test backlight ---" | tee -a $csv_file
echo "$path/$sample -d " | tee -a $csv_file
./$sample -d  | tee -a $csv_file
check_lcmcom
lcmcom_check_flag=$?
if [ "$lcmcom_check_flag" -eq 0 ]; then
    echo "Pass : backlight is dark." | tee -a $csv_file
else
    lcmcom_err=1
    echo "Fail : backlight is bright." | tee -a $csv_file
fi

#### Enable backlight test
echo "$path/$sample -e " | tee -a $csv_file
./$sample -e  | tee -a $csv_file
check_lcmcom
lcmcom_check_flag=$?
if [ "$lcmcom_check_flag" -eq 0 ]; then
    echo "Pass : backlight is bright." | tee -a $csv_file
else
    lcmcom_err=1
    echo "Fail : backlight is dark." | tee -a $csv_file
fi

#### display test
echo -e "\n--- Test screen ---" | tee -a $csv_file
echo "$path/$sample -t "  | tee -a $csv_file
./$sample -t  | tee -a $csv_file
check_lcmcom
lcmcom_check_flag=$?
if [ "$lcmcom_check_flag" -eq 0 ]; then
    echo "Pass : full screen test." | tee -a $csv_file
else
    lcmcom_err=1
    echo "Fail : error display." | tee -a $csv_file
fi

#### clear display test
echo -e "\n--- Test clear screen ---" | tee -a $csv_file
echo "$path/$sample -c " | tee -a $csv_file
./$sample -c  | tee -a $csv_file
check_lcmcom
lcmcom_check_flag=$?
if [ "$lcmcom_check_flag" -eq 0 ]; then
    echo "Pass : display is empty." | tee -a $csv_file
else
    lcmcom_err=1
    echo "Fail : error display." | tee -a $csv_file
fi

#### line display test
# Get line number
declare -a arr
./lcmcom > $help_file
line=$(tail -3 $help_file  | cut -d"~" -f 2 | grep -oE '[0-9]+' | head -1)

echo -e "\n--- Test line writing ---" | tee -a $csv_file
for ((i=0;i<$line;i++))
do
     j=$(($i+1))
    arr[i]=$(yes $j | tr -d '\n' | head -c 10)
    echo "$path/$sample $j ${arr[$i]}" | tee -a  $csv_file
    ./$sample $j ${arr[$i]}  | tee -a $csv_file
done
check_lcmcom
lcmcom_check_flag=$?
if [ "$lcmcom_check_flag" -eq 0 ]; then
    echo "Pass : display is correct." | tee -a $csv_file
else
    lcmcom_err=1
    echo "Fail : error display." | tee -a $csv_file
fi

#### button test
if [ $btntest -eq 1 ]; then
    echo -e "\n--- Test buttons ---" | tee -a $csv_file
    echo "$path/$sample -b " | tee -a $csv_file
    ./$sample -b  | tee -a $csv_file
    check_lcmcom
    lcmcom_check_flag=$?
    if [ "$lcmcom_check_flag" -eq 0 ]; then
        echo "Pass." | tee -a $csv_file
    else
        lcmcom_err=1
        echo "Fail." | tee -a $csv_file
    fi
fi

#### Test result
if [ "$lcmcom_err" -eq 0 ]; then
    echo "PASS" | tee -a $csv_file
else
    echo "FAIL" | tee -a $csv_file
fi
