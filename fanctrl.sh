################################################
####  fan ctrl test script
################################################
path=$1
log_file=$2
sample=$3

root_path=$(pwd)
csv_file=${root_path}/$log_file
fanctrl_file=${root_path}/../fanctrl.tmp
cd $path

FANCRTL_RANGE=1000
WAIT_TIME=2

declare -i fanctrl_err=0

echo -e "--- Test make ---" | tee -a $csv_file
#### Building test : make clean
make clean  | tee -a $csv_file
fanctrl_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $fanctrl_check_flag -ne 0 ]; then
    fanctrl_err=1
    echo "Fail : make clean failed." | tee -a $csv_file
    echo "FAIL" | tee -a $csv_file
    exit
fi

#### Building test : make
make  | tee -a $csv_file
fanctrl_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $fanctrl_check_flag -ne 0 ]; then
    fanctrl_err=1
    echo "Fail : make failed." | tee -a $csv_file
    echo "FAIL" | tee -a $csv_file
    exit
fi

echo "-----------------" | tee -a $csv_file

echo -e "\n$path/$sample" >> $csv_file
./$sample  | tee -a $csv_file

# Check help files
fanctrl_r=$(cat $csv_file | grep -e "-r")
if [ -z "$fanctrl_r" ]; then
	fanctrl_err=1
	echo "Fail : help() is error." | tee -a $csv_file
	echo "FAIL" | tee -a $csv_file
	exit
fi

./$sample > $fanctrl_file
fan_set_flag=$(cat $fanctrl_file | grep "fan -s" |  wc -l)
if [ "$fan_set_flag" -eq 0 ]; then
    echo "No FanCtrl" | tee -a  $csv_file
    exit 0
fi



##### Run ./fan
#### Analyze index and duty cycle
declare -i start_idx=0
declare -i end_idx=0

#### Analyze index range
fan_number=$(cat $fanctrl_file | grep "fan number" | cut -d"(" -f 2)
start_idx=$(echo $fan_number  | cut -d"~" -f 1)
end_idx=$(echo $fan_number | cut -d"~" -f 2 | cut -d")" -f 1)
echo "start idx : $start_idx, end idx:$end_idx"

#### Analyze duty cycle range
fan_cycle=$(cat $fanctrl_file | grep "duty cycle" | cut -d"(" -f 2)
low_cycle=$(echo $fan_cycle  | cut -d"~" -f 1)
high_cycle=$(echo $fan_cycle | cut -d"~" -f 2 | cut -d")" -f 1)
echo "Low duty cycle : $low_cycle, high duty cycle:$high_cycle"

default_cycle=30

for ((i=$start_idx;i<=$end_idx;i++))
do
    # Set low cycle value.
    echo "------------  Set fan $i duty cycle-----------------"  | tee -a $csv_file
    echo "./fan -s $i $low_cycle" | tee -a $csv_file
    ./fan -s $i $low_cycle | tee -a  $csv_file

    sleep $WAIT_TIME
    # Read low cycle value.
    echo "./fan -r" | tee -a $csv_file
     ./fan -r | tee -a  $csv_file
    fan_number=$(cat $fanctrl_file | grep "fan number" | cut -d"(" -f 2)
    low_speed=$(./fan -r | sed -n "$i{p;q}" | cut -d":" -f 2 | cut -d" " -f 2)

    # Set high cycle value.
    echo "------------  Set fan $i duty cycle-----------------"  | tee -a $csv_file
    echo "./fan -s $i $high_cycle" | tee -a $csv_file
    ./fan -s $i $high_cycle | tee -a  $csv_file

    sleep $WAIT_TIME
    # Read high cycle value.
    echo "./fan -r" | tee -a $csv_file
     ./fan -r | tee -a  $csv_file
    fan_number=$(cat $fanctrl_file | grep "fan number" | cut -d"(" -f 2)
    high_speed=$(./fan -r | sed -n "$i{p;q}" | cut -d":" -f 2 | cut -d" " -f 2)

    ##echo $low_speed
    ##echo $high_speed

    if [ "$low_speed" = "N/A" ]; then
	     low_speed=0
    fi

    if [ "$high_speed" = "N/A" ]; then
        high_speed=0
    fi

    diff_cycle=$(($high_speed - $low_speed))

    if [ "$diff_cycle" -lt "$FANCRTL_RANGE" ]; then
	    fanctrl_err=1
    fi

    # Set default cycle value.
    echo "------------  Set fan $i duty cycle-----------------"  | tee -a $csv_file
    echo "./fan -s $i $default_cycle" | tee -a $csv_file
    ./fan -s $i $default_cycle | tee -a  $csv_file

done

#### Test result
if [ "$fanctrl_err" -eq 0 ]; then
    echo "FanCtrl PASS" | tee -a $csv_file
else
    echo "FanCtrl FAIL" | tee -a $csv_file
fi
