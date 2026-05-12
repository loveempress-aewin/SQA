################################################
####  WDT test script
################################################
path=$1
log_file=$2
sample=$3
rm -rf $log_file

root_path=$(pwd)
csv_file=${root_path}/$log_file 
help_file=${root_path}/../help.tmp  
cd $path

declare -i wdt_err=0

echo -e "--- Test make ---" | tee -a $csv_file 
#### Building test : make clean
make clean  | tee -a $csv_file 
wdt_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $wdt_check_flag -ne 0 ]; then
    wdt_err=1
    echo "Fail : make clean failed." | tee -a $csv_file 
    echo "FAIL" | tee -a $csv_file 
    exit 1
fi

#### Building test : make
make  | tee -a $csv_file  
wdt_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $wdt_check_flag -ne 0 ]; then
    wdt_err=1
    echo "Fail : make failed." | tee -a $csv_file 
    echo "FAIL" | tee -a $csv_file 
    exit 1
fi

echo "-----------------" | tee -a $csv_file  

##### Run ./wdt
#### Analyze WDT's mode and maxmum setting value  
echo "$path/$sample" >> $csv_file
pwd
./$sample  > $help_file 
./$sample  | tee -a $csv_file 

# Check help files
wdt_r=$(cat $help_file | grep -e "-r")
if [ -z "$wdt_r" ]; then
	wdt_err=1
	echo "Fail : help() is error." | tee -a $csv_file 
	echo "FAIL" | tee -a $csv_file 
	exit
fi

test_time=30
sleep_sec=1
test_min=5
sleep_min=70
reset_sec=10
##reset_min=1

 
#set time test
echo "$path/$sample -s $test_time" | tee -a $csv_file 
./wdt -s $test_time | tee -a $csv_file 
sleep $sleep_sec
echo "$path/$sample -r"  | tee -a $csv_file 
./wdt -r  | tee -a $csv_file 
remaining=$(./wdt -r | cut -d":" -f 2 | cut -d" " -f 2)
##echo $remaining
if [[ "$remaining" -eq 0  ||  "$remaining" -eq "$test_time" ]]; then
    echo "Fail : wdt setting" | tee -a $csv_file
    echo "FAIL" | tee -a $csv_file 
    wdt_err=1
    exit 1
else
    echo "Pass : wdt setting"  | tee -a $csv_file
fi

#set minute time test
min_flag=$(cat $help_file | grep "\-m" | wc -l)
##echo $min_flag
if [ "$min_flag" -ne 0 ]; then
    echo "$path/$sample -m $test_min" | tee -a $csv_file 
    ./wdt -m $test_min | tee -a $csv_file 
    sleep $sleep_min
    echo "$path/$sample -r"  | tee -a $csv_file 
    ./wdt -r  | tee -a $csv_file 
    remaining=$(./wdt -r | cut -d":" -f 2 | cut -d" " -f 2)
    echo $remaining
    if [[ "$remaining" -eq 0  ||  "$remaining" -eq "$test_min" ]]; then
        echo "Fail : wdt setting" | tee -a $csv_file
        echo "FAIL" | tee -a $csv_file 
        wdt_err=1
        exit 1
    else
        echo "Pass : wdt setting"  | tee -a $csv_file
    fi
fi

#get setting time test
#rt_flag=$(cat $help_file | grep "\-rt" | wc -l)
##echo $rt_flag
#if [ "$rt_flag" -ne 0 ]; then
#    echo "$path/$sample -rt"  | tee -a $csv_file
#     ./wdt -rt |  tee -a $csv_file
#    remaining=$(./wdt -rt | tail -1 | cut -d":" -f 2 | cut -d" " -f 2)
#    if [ "$remaining" != "$test_time" ]; then
#        echo "Fail : read wdt setting time" | tee -a $csv_file
#        echo "FAIL" | tee -a $csv_file 
#        wdt_err=1
#        exit 1
#    else
#         echo "Pass : read wdt setting time"  | tee -a $csv_file
#    fi
#fi

## Stop wdt test
echo "$path/$sample -s 0"  | tee -a $csv_file 
./wdt -s 0  | tee -a $csv_file 
sleep $sleep_sec
echo "$path/$sample -r"  | tee -a $csv_file 
./wdt -r  | tee -a $csv_file 
remaining=$(./wdt -r | cut -d":" -f 2 | cut -d" " -f 2)
##echo $remaining
if [[ "$remaining" -ne 0 && "$remaining" -ne "$test_time" ]]; then
    echo "Fail : stop wdt" | tee -a $csv_file 
    echo "FAIL" | tee -a $csv_file 
    wdt_err=1
else
    echo "Pass : stop wdt" | tee -a $csv_file 
fi

# Reset test (wdt.csv will be clear after reboot  )
echo "Please add PASS or FAIL on last line of wdt.csv"
echo "$path/$sample -s $reset_sec" | tee -a $csv_file 
./wdt -s $reset_sec | tee -a $csv_file 
sync
sync
sync

#### Test result
#if [ "$led_err" -eq 0 ]; then
#    echo "PASS" | tee -a $csv_file 
#else
#    echo "FAIL" | tee -a $csv_file 
#fi
