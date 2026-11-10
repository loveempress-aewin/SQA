#!/bin/bash

# Initialize a counter
count=1

# Loop through all arguments passed to this script
for param in "$@"; do
    echo "Argument ${count} : ${param}"
    ((count++))
done

path=$1
log_file=$2
sample=$3
rm -rf $log_file
#### /root/L_1949/ccauto/hwmnt.sh temp/v1.00 ../csv/temp.csv temp
# echo -e "1:[$path]\n2:[${log_file}]\n3:sample:[${sample}]\n4:[$4]" ####dev mode

##echo $path

root_path=$(pwd)
csv_file=${root_path}/$log_file
label_file=${root_path}/label.tmp
cd $path

echo -e "--- Test make ---" | tee -a $csv_file
#### Building test : make clean
make clean  | tee -a $csv_file
hwmnt_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $hwmnt_check_flag -ne 0 ]; then
    echo "Fail : make clean failed." | tee -a $csv_file
    echo "FAIL" | tee -a $csv_file
    exit
fi

#### Building test : make
make  | tee -a $csv_file
hwmnt_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $hwmnt_check_flag -ne 0 ]; then
    echo "Fail : make failed." | tee -a $csv_file
    echo "FAIL" | tee -a $csv_file
    exit
fi

echo "-----------------" | tee -a $csv_file

echo "$path/$sample"  |  tee -a $csv_file
./$sample  | tee -a $csv_file

echo "$path/$sample -r " | tee -a $csv_file
./$sample -r  | tee -a $csv_file

echo -e "\n$path/$sample -c " | tee -a $csv_file
./$sample -c  | tee -a $csv_file

#############################
### Check labels
#############################
##write label file
./$sample -r   | cut -d":" -f 1 > $label_file

# Temperature Label
SIO_temp_cpu1_label=("CPU0 Temp." "Inlet1 Temp." "Outlet1 Temp.")
SIO_temp_cpu2_label=("CPU0 Temp."  "CPU1 Temp." "Inlet1 Temp." "Outlet1 Temp.")
BMC_temp_cpu1_label=("CPU0 Temp." "Inlet1 Temp." "Outlet1 Temp.")
BMC_temp_cpu2_label=("CPU0 Temp."  "CPU1 Temp." "Inlet1 Temp." "Outlet1 Temp.")
# Voltage
SIO_voltage_cpu1_label=("CPU0 VCORE" "+12V" "+5V" "+3.3V" "VBAT")
SIO_voltage_cpu2_label=("CPU0 VCORE" "CPU1 VCORE" "+12V" "+5V" "+3.3V" "VBAT")
BMC_voltage_intel_cpu1_label=("CPU0 VCORE" "CPU0 VCCIO" "CPU0 VDDQ ABCD" "CPU0 VDDQ EFGH" "+12V" "+5V" "+3.3V" "VBAT" "PCH 1.8V" "PCH PVNN" "PCH 1.05V" "BMC 1.15V")
BMC_voltage_intel_cpu2_label=("CPU0 VCORE" "CPU0 VCCIO" "CPU0 VDDQ ABCD" "CPU0 VDDQ EFGH"  "CPU1 VCORE" "CPU1 VCCIO" "CPU1 VDDQ JKLM" "CPU1 VDDQ NPRT" "+12V" "+5V" "+3.3V" "VBAT" "PCH 1.8V" "PCH PVNN" "PCH 1.05V" "BMC 1.15V")
BMC_voltage_amd_cpu1_label=("VDDCR CPU P0" "VDDCR SOC P0" "VDDQ ABCD P0" "VDDQ EFGH P0" "+12V" "+5V" "+3.3V" "VBAT")
BMC_voltage_amd_cpu2_label=("VDDCR CPU P0" "VDDCR SOC P0" "VDDQ ABCD P0" "VDDQ EFGH P0" "VDDCR CPU P1" "VDDCR SOC P1" "VDDQ ABCD P1" "VDDQ EFGH P1" "+12V" "+5V" "+3.3V" "VBAT")
#### fan label
SIO_fan_cpu1_label=("CPU0 Fan" "SYSFAN1 1" "SYSFAN2 1" "SYSFAN3 1" "SYSFAN4 1")
SIO_fan_cpu2_label=("CPU0 Fan" "CPU1 Fan" "SYSFAN1 1" "SYSFAN2 1" "SYSFAN3 1" "SYSFAN4 1")
BMC_fan_cpu1_label=("CPU0 Fan" "SYSFAN1 1" "SYSFAN2 1" "SYSFAN3 1" "SYSFAN4 1")
BMC_fan_cpu2_label=("CPU0 Fan" "CPU1 Fan" "SYSFAN1 1" "SYSFAN2 1" "SYSFAN3 1" "SYSFAN4 1")
#### fan
SIO_psu_cpu1_label=("PSU0 Status" "PSU0 Vin" "PSU0 +12V" "PSU0 Fan" "PSU0 Temp." "PSU1 Status" "PSU1 Vin" "PSU1 +12V" "PSU1 Fan" "PSU1 Temp.")
SIO_psu_cpu2_label=("PSU0 Status" "PSU0 Vin" "PSU0 +12V" "PSU0 Fan" "PSU0 Temp." "PSU1 Status" "PSU1 Vin" "PSU1 +12V" "PSU1 Fan" "PSU1 Temp.")
BMC_psu_cpu1_label=("PSU0 Status" "PSU0 Vin" "PSU0 +12V" "PSU0 Fan" "PSU0 Temp." "PSU1 Status" "PSU1 Vin" "PSU1 +12V" "PSU1 Fan" "PSU1 Temp.")
BMC_psu_cpu2_label=("PSU0 Status" "PSU0 Vin" "PSU0 +12V" "PSU0 Fan" "PSU0 Temp." "PSU1 Status" "PSU1 Vin" "PSU1 +12V" "PSU1 Fan" "PSU1 Temp.")

# Define the label input file
# INFILE=$label_file ####你有病吧 硬要在一個變數來裝變數 意義是傻== 太無聊?
INFILE=$(cat ${label_file}) ####fix bug ==
printf "\n===contents=====\n%s\n==============\n\n" "${INFILE}"

############################################
## Make label array string
############################################
# Get CPU number
cpu_count=$(lscpu | grep Socket | cut -d":" -f 2)

# Detect BMC driver
[ -e "/dev/ipmi0" ]
bmc_flag=$?
if [ $bmc_flag -eq 0  ]; then
    label_str="BMC"
else
    label_str="SIO"
fi

label_str=$label_str"_"$sample"_"

# Voltage : AMD or Intel
if [ "$sample" = "voltage" ]; then
    if [ $bmc_flag -eq 0  ]; then
        cpu_intel=$(lscpu | grep "Model name" | cut -d":" -f 2 | grep Intel | wc -l)
        if [ "$cpu_intel" -gt 0 ]; then
            label_str=$label_str"_intel_"
        else
            label_str=$label_str"_amd_"
        fi
    fi
fi

if [ $cpu_count -eq 2 ]; then
    label_str=$label_str"cpu2"
else
    label_str=$label_str"cpu1"
fi

label_str=$label_str"_label"

##echo $label_str
#######################################
### End
#######################################

declare -n label_array=$label_str

function check_label() {
    for item in "${label_array[@]}"
    do
       ###echo "$item"
        if [ "$item" = "$1" ]; then
                return 0
        fi
    done

    return 1
}

declare -i label_err=0

# Read the input file line by line
while read -r line
do
    ###printf '%s\n' "$line"
    check_label "$line"
    lable_check_flag=$?

    ###echo $lable_check_flag
    if [ "$lable_check_flag" -eq 1 ]; then
        label_err=1
    fi
done < "$INFILE"

##echo $label_err
if [ "$label_err" -eq 0 ]; then
    echo "Label PASS" | tee -a $csv_file
else
    echo "Label FAIL" | tee -a $csv_file
fi

## Delete label.tmp file
rm $label_file
