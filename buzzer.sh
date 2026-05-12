################################################
####  Buzzer test script
################################################
path=$1
log_file=$2
sample=$3
rm -rf $log_file

root_path=$(pwd)
csv_file=${root_path}/$log_file 
help_file=${root_path}/help.tmp  
cd $path

declare -i buzzer_err=0

echo -e "--- Test make ---" | tee -a $csv_file 
#### Building test : make clean
make clean  | tee -a $csv_file 
buzzer_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $buzzer_check_flag -ne 0 ]; then
    buzzer_err=1
    echo "Fail : make clean failed." | tee -a $csv_file 
    echo "FAIL" | tee -a $csv_file 
    exit 
fi

#### Building test : make
make  | tee -a $csv_file  
buzzer_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $buzzer_check_flag -ne 0 ]; then
    buzzer_err=1
    echo "Fail : make failed." | tee -a $csv_file 
    echo "FAIL" | tee -a $csv_file 
    exit 
fi

echo "-----------------" | tee -a $csv_file  

function check_sound() {
    while true; do
        read -p "Do you hear buzzer sound? (y/n)" yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
   done
}

#### Default test 
echo "$path/$sample" >> $csv_file
./$sample  > $help_file 
./$sample  | tee -a $csv_file

# Check help files
buzzer_e=$(cat $csv_file | grep -e "-e")
if [ -z "$buzzer_e" ]; then
	buzzer_err=1
	echo "Fail : help() is error." | tee -a $csv_file 
	echo "FAIL" | tee -a $csv_file 
	exit
fi
 
check_sound
sound_check_flag=$?
if [ "$sound_check_flag" -eq 0 ]; then
    buzzer_err=1
    echo "Fail : Hear beep sound before setting." | tee -a $csv_file 
else
    echo "Pass : No sound" | tee -a $csv_file 
fi

#### Enable test
echo "$path/$sample  -e " >> $csv_file
./$sample -e  | tee -a $csv_file 
check_sound
sound_check_flag=$?
if [ "$sound_check_flag" -eq 0 ]; then
    echo "Pass : Hear beep sound." | tee -a $csv_file 
else
    buzzer_err=1
    echo "Fail : No sound" | tee -a $csv_file 
fi

#### Disable test
echo "$path/$sample  -d " >> $csv_file
./$sample -d  | tee -a $csv_file 
check_sound
sound_check_flag=$?
if [ "$sound_check_flag" -eq 0 ]; then
     buzzer_err=1
    echo "Fail : Hear beep sound." | tee -a $csv_file 
else
    echo "Pass : No sound" | tee -a $csv_file 
fi

#### Test result
if [ "$buzzer_err" -eq 0 ]; then
    echo "PASS" | tee -a $csv_file 
else
    echo "FAIL" | tee -a $csv_file 
fi
