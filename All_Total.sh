################################################
####  Generate total report script
################################################
path=$1
root_path=$(pwd)
csv_file=${root_path}/$path/All_Total.csv
mode_file=${root_path}/$path/mode_info.tmp
ipmi_file=${root_path}/$path/ipmi_sdr.csv
com_file=${root_path}/$path/com_config.csv

if [ ! -d "$path" ]; then
    echo "Error: Directory $path does not exist."
    exit
elif [ -z "$(ls -A "$path")" ]; then
    echo "Error: Directory $path is empty."
    exit
fi

#echo $csv_file

item_label_arr=("buzzer.csv" "bypass.csv" "caseopen.csv" "fan.csv" "gpio.csv" "lcmcom.csv" "led.csv" "nicee.csv" "psu.csv" "temp.csv" "voltage.csv" "wdt.csv")
pass_number_arr=(1            1            1              3         1          1            1             1       3          2         2                  1)

echo "---- Information ----" | tee -a $csv_file
#1. BIOS Version
bios_ver=$(dmidecode -t 1 | grep "Version" | tr -d ' ' | cut -d':' -f2)
echo "BIOS version : $bios_ver" | tee -a $csv_file

echo "---- DMItable type 11 ----" >> $csv_file
#1-1 dmitable
v_dmitalbe=$(dmidecode -t 11)
echo -e "DMI information\n${v_dmitalbe}" >> $csv_file

echo "================ IPMI ================" >>${ipmi_file}
if ipmitool user list 1 >/dev/null 2>&1;then
    ipmi_sdr=$(ipmitool sdr)
    echo ${ipmi_sdr} >> ${ipmi_file}
else
    echo "no ipmi" >> ${ipmi_file}
fi

if setserial -a /dev/ttyS0 >/dev/null 2>&1;then
    # echo "yes setserial";
    #### TODO : need to clean history : com_config.csv (comport log)
    echo "/dev/ttyS0" >> ${com_file};
    setserial -a /dev/ttyS0 >> ${com_file}
    setserial -a /dev/ttyS1 >> ${com_file}
    setserial -a /dev/ttyS2 >> ${com_file}
else
    echo "ERROR";####TODO call install script
fi

#2. OS version
os_ver=$(cat /etc/os-release | grep "VERSION" | tr -d ' ')
echo "OS version : " | tee -a  $csv_file
echo "$os_ver" | tee -a  $csv_file

#3. Kernel version
kernel_ver=$(uname -r)
echo "Kernel version : $kernel_ver" | tee -a  $csv_file

#4 bmc version
if [ -e "/dev/ipmi0" ]; then
	MFG_ID=$(ipmitool raw 0x06 0x01 | awk '{print $11$12$13}')
	if [ "$MFG_ID"  ==  "0000cc" ]; then
		echo "AMI:"
	elif [ "$MFG_ID"  ==  "020202" ]; then
		BYO_VER=$(ipmitool raw 0x30 0x01 2>&1)
		if [[ $BYO_VER != *"Invalid"* ]]; then
			echo "BYO:"
		fi
	fi
fi

if [ -e "/dev/ipmi0" ]; then
	ver=$(ipmitool raw 0x1e 0x01 0x00 2>&1)
	echo "$ver" | awk '{
		print("BMC version :")
		name_end=0
		for (i=1; i<=NF; i++) {
			dec = strtonum("0x"$i)
			#echo $dec
			if (dec >=32 && dec <= 126) {
				printf("%c", dec)
			}else{
				if( name_end == 0 )
				{
					printf(" ")
					name_end=1
				}
				printf("%s.", dec)
			}
		}
}'  | tee -a $csv_file

fi

echo -e "\n\n---- Test mode ----" | tee -a $csv_file
cat $mode_file | tee -a $csv_file

echo -e "\n\n---- Test Result ----" | tee -a $csv_file

cd $path
for file in *.csv; do
	for ((i=0; i < ${#item_label_arr[@]}; i++)); do
	    #echo "索引 $i 的檔案名稱是: ${files[$i]}"
	    if [[ "${item_label_arr[$i]}" == "$file" ]]; then
	    	#echo "file:$file, pass count: ${pass_number_arr[$i]}"
	    	pass_cnt=$(cat $file | grep "PASS" | wc -l)
	    	name_no_ext="${file%.csv}"

	    	if [ "$pass_cnt" = "${pass_number_arr[$i]}" ]; then
	    		printf "%-12s: PASS\n" "$name_no_ext" | tee -a  $csv_file
	    		break
	    	else
	    		printf "%-12s: FAIL\n" "$name_no_ext" | tee -a  $csv_file
	    	fi
	    fi
	done
done
