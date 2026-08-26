################################################
####  PSU excetion test script
################################################
path=$1
log_file=$2
sample=$3

root_path=$(pwd)
csv_file=${root_path}/$log_file
psuex_file=${root_path}/../csv/psuex.tmp
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

declare -i power_1=2;
declare -i power_2=8;
read -p "Please enter which port PSU0 is plugged into ->" power_1;
read -p "Please enter which port PSU1 is plugged into ->" power_2;

max_attempts=3
attempt=0
declare -i port1=0
declare -i port2=0
function F_input_power(){
    while [ $attempts -lt $max_attempts ]; do
        read -p "Please enter two port numbers (separated by space): " input1 input2

        # Check if both inputs are valid integers
        if [[ "$input1" =~ ^[0-9]+$ ]] && [[ "$input2" =~ ^[0-9]+$ ]]; then
            port1="$input1"
            port2="$input2"
            echo "Successfully recorded ports: Port $port1 and Port $port2"
            break
        else
            ((attempts++))
            remaining=$((max_attempts - attempts))
            echo "Invalid input! Please enter digits only. ($remaining attempt(s) remaining)"
        fi
    done

    # Exit if all attempts were exhausted
    if [ $attempts -eq $max_attempts ]; then
        echo "ERROR: Too many failed attempts. Exiting..." >&2
        exit 1
    fi

    # Continue script using $port1 and $port2...
}
F_input_power

function check_power_status() {
    while true; do
        read -p "Is the power has been unplugged? (y/n)" yn < /dev/tty
        case $yn in
            [Yy]* )
                return 0
                    ;;
            [Nn]* )
                return 1;;
            * ) echo "Please answer yes or no.";;
        esac
   done
}

### Test unplugged status of psu0
echo "Please unplug the first power cord and key \"yes\"."
check_power_status
psu_check_flag=$?

if [  "$psu_check_flag" -eq 0 ]; then
    ./web_power_switch.sh ${power_1} OFF &&sleep 8;
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
    ./web_power_switch.sh ${power_1} ON && sleep 8;
    ./web_power_switch.sh ${power_2} OFF && sleep 8;
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

./web_power_switch.sh ${power_2} ON;
#### Test result
if [ "$psuex_err" -eq 0 ]; then
    echo "PSUEx PASS" | tee -a $csv_file
else
    echo "PSUEx FAIL" | tee -a $csv_file
fi
