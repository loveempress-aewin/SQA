################################################
####  nicee test script
################################################
####+ /root/big_strcu/ccauto/nicee.sh nicee/v1.00 ../csv/nicee.csv nicee
. $(pwd)/../ccauto/config.cfg
if(( $# < 3 ));then exit 33;fi
path=$1
log_file=$2
love_back="../csv/"
sample=$3
rm -rf $log_file

root_path=$(pwd) # + root_path=/root/big_strcu/samplecode
# . ${root_path}/../ccauto/config.cfg
csv_file=${root_path}/$log_file
nicee_file=${root_path}/../csv/nicee.tmp
mb_param=${root_path}/${love_back}nicee_mb_param.txt
# slot_param=${root_path/${love_back}/nicee_slot_param.txt
slot_param=${root_path}/../ccauto/nicee_slot_param.txt
if [[ -z ${slot_param} ]];then
    echo 'slot_param is empty';exit 33;
else
    echo "slot_param : ${slot_param}"|xxd
    echo "slot_param : ${slot_param}"|cat -A
fi
cd $path

declare -i nicee_err=0

echo -e "--- Test make ---" | tee -a $csv_file
#### Building test : make clean
make clean  | tee -a $csv_file
nicee_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $nicee_check_flag -ne 0 ]; then
    nicee_err=1
    echo "Fail : make clean failed." | tee -a $csv_file
    echo "FAIL" | tee -a $csv_file
    exit 1
fi

#### Building test : make
make  | tee -a $csv_file
nicee_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $nicee_check_flag -ne 0 ]; then
    nicee_err=1
    echo "Fail : make failed." | tee -a $csv_file
    echo "FAIL" | tee -a $csv_file
    exit 1
fi

echo "-----------------" | tee -a $csv_file

echo "$path/$sample" >> $csv_file
# Get slot number.
./nicee > $nicee_file
./nicee | tee -a $csv_file

# Check help files
nicee_show=$(cat $nicee_file | grep -e "-show")
if [ -z "$nicee_show" ]; then
	nicee_err=1
	echo "Fail : help() is error." | tee -a $csv_file
	echo "FAIL" | tee -a $csv_file
	exit 1
fi

# nicee_number=$(cat $nicee_file | grep "slot" | cut -d"~" -f 3)
# if [ -z $nicee_number ]; then
#     nicee_number=0
# fi

# nicee_number=$(cat $nicee_file | grep "bypass circuits"| awk -F"=" '{print $2+0}')
nicee_number=${NICEE_NUM_SLOT}
# if (( ${nicee_num_slot} ))
ERROR_mesage="================\nERROR : U need add [NICEE_NUM_SLOT]\n================\n"
if [[ ! "${nicee_number}" =~ ^[0-9]+$ ]];then echo -e "${ERROR_mesage}"; exit 99;fi
# Reset slot number
##nicee_number=2

echo "Please verify that your SLOT is this number. If it is not, please select N and reconfigure the settings file."
echo "slot number : $nicee_number"
function love_input_my(){
    echo -n "Continue? [Y/n] (auto-yes in 5s): "
    if read -t 5 -r answer; then
        # user typed something
        answer="${answer:-Y}"          # if user just pressed enter → default Y
    else
        # timeout hit
        echo ""                        # newline after the prompt
        answer="Y"
        echo "No input detected, defaulting to YES"
    fi

case "${answer^^}" in              # ^^ converts to uppercase
    Y|YES)
        echo "Proceeding..."
        ;;
    N|NO)
        echo "Aborted."
        exit 0
        ;;
    *)
        echo "Invalid input, defaulting to YES"
        love_input_my
        ;;
esac
}
love_input_my


# All Labels array
mb_labels=("Module Number" "Number of LAN ports" "Number of LAN2 ports" "Number of LAN3 ports" "H/W version" "Number of bypass" "Number of SKU")
slot_labels=("Module Number" "Number of LAN ports" "PCIe Length" "H/W version" "Number of bypass")

declare -a nicee_mb_data_array
declare -a nicee_mb_param_array
declare -a nicee_slot_data_array
declare -A nicee_slot_param_array
declare -A nicee_slot_counts_array
declare -i slot_id=0

# Read MB parameter setting
len=${#mb_labels[@]}
# for (( i = 0; i < len; i++)); do
#     nicee_mb_param_array[i]=$(cat $mb_param | grep "${mb_labels[i]}" | cut -d"=" -f 2 | tr -d " ")
#     echo "nicee_mb_param[$i] : ${nicee_mb_param_array[i]}"
# done

echo -e "\n------ Mother Board ------------ "  | tee -a $csv_file
# Read MB data from eeprom
./nicee -show 0  | tee -a $csv_file
./nicee -show 0 > $nicee_file
# for (( i = 0; i < len; i++)); do
#     nicee_mb_data_array[i]=$(cat $nicee_file | grep "${mb_labels[i]}" | cut -d"=" -f 2 | tr -d " ")
#     #echo "param: ${nicee_mb_param_array[i]}"
#     #echo "data : ${nicee_mb_data_array[i]}"
#     if [ "${nicee_mb_param_array[i]}" != "${nicee_mb_data_array[i]}" ]; then
#        nicee_err=1
#        echo "Fail:${mb_labels[i]} = ${nicee_mb_param_array[i]}"
#     fi
# done

./nicee -show 0
./nicee -show 0 > ${mb_param}
# let love_flag=0;
read -p "Please verify (Y or N) : " love_flag
case $love_flag in
    Y | y)
        echo "mother board : PASS" |tee -a $csv_file ;;
    N | n)
        echo "mother board : FAIL" | tee -a $csv_file
        nicee_err=1;
        ;;
    *)
        nicee_err=1
esac

while read -r line
do
    printf '%s\n' "while -> line:$line" ####dev-mode
    # skip space line.
    #[[ -z "$line" ]] && continue
    slot_id=$((slot_id + 1))
    read -a elements <<< "$line"
    index=0
    for item in "${elements[@]}"; do
        echo "nicee_slot_param_array[$slot_id,$index]"
        nicee_slot_param_array["$slot_id,$index"]=$item
        index=$((index + 1))
    done
    nicee_slot_counts_array[$slot_id]=$index
done < "$slot_param"
# exit 1
# Read nicee data of net card
len=${#slot_labels[@]}
if [ "$nicee_number" -ne 0 ]; then
    for (( i = 1; i <= $nicee_number; i++)); do
        echo -e "\n------ Slot$i ------------ "  | tee -a $csv_file
        ./nicee -show $i  | tee -a $csv_file
        ./nicee -show $i > $nicee_file
        if [ ! -s $nicee_file ]; then
            nicee_err=1
            echo "Fail:slot$i is empty."  | tee -a $csv_file
        else
            for (( j = 0; j < ${nicee_slot_counts_array[$i]}; j++)); do
                nicee_slot_data_array[j]=$(cat $nicee_file | grep "${slot_labels[j]}" |  cut -d"=" -f 2 | tr -d ' ')
                # echo ${nicee_slot_param_array["$i,$j"]} ####dev mode
                # echo ${nicee_slot_data_array[j]}        ####dev mode
                if [ "${nicee_slot_param_array["$i,$j"]}" != "${nicee_slot_data_array[j]}" ]; then
                   nicee_err=1
                   echo "Fail:${slot_labels[j]} = ${nicee_slot_param_array["$i,$j"]}"|tee -a $csv_file
                fi
            done
        fi
    done
fi

#### Test result
if [ "$nicee_err" -eq 0 ]; then
    echo "PASS" | tee -a $csv_file
else
    echo "FAIL" | tee -a $csv_file
fi
