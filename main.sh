CSV_folder="csv"
root_path=$(pwd)
mode_file=${root_path}/../$CSV_folder/mode_info.tmp

## Array of test items.
declare -a ItemArray

#chmod 777 to all *.sh
chmod 777 *.sh

#### mkdir csv dir
if [[ ! -d ../csv ]]; then
    mkdir ../csv
fi

bash ./start.sh
#delete tmp files
for f in *.tmp; do
	if [ -s "$f" ]; then
		rm "$f"
 	fi
done

#### amd
bash ./amd.sh

#Set LCM button test
lcmbtn=0    #1:button test, 0: no button

## list menu
echo "0. Show driver mode setting"
echo "1. Set user mode"
echo "2. Set driver mode"
echo "3. All test"
echo "4. Generate All_Total page"
items_array[0]="Show_mode"
items_array[1]="Set_user_mode"
items_array[2]="Set_driver_Mode"
items_array[3]="auto1"
items_array[4]="All_Total"

default_idx=5
menu_idx=$default_idx

##### Get all sample name to list all test items.
# Define exclude directory in sample_code
EXCLUDE="include|scbutil|slot|csv"

# 使用 readarray 存入陣列

# -maxdepth 1: 只看第一層
# -not -name ".": 排除代表當前目錄的點號
cd ../sample_code
readarray -d '' sample_folders < <(find . -maxdepth 1 -type d ! -name "." | grep -vE "$EXCLUDE" | sort | tr '\n' '\0')

# 測試：印出陣列內容
#echo "找到的資料夾數量: ${#sample_folders[@]}"
for dir in "${sample_folders[@]}"; do
    #echo "資料夾名稱: $dir"
    name=$(echo $dir | cut -d"/" -f 2)
    echo "$menu_idx. $name"
    items_array[$menu_idx]=$name
    ##echo "${items_array[$menu_idx]}"
    menu_idx=$(($menu_idx+1))
done

##echo "${#items_array[@]}"
read choice

function show_mode(){
	# Delete old file.
	if [ -f "$mode_file" ]; then
			rm $mode_file
	fi

	for ((i=$default_idx; i<"${#items_array[@]}"; i++)); do
			cd ${items_array["$i"]}
			ver=$(ls | head -n 10 | tail -1)
			cd $ver
			awk -v name="${items_array["$i"]}" '/main_param/ {
							getline;
							#print substr($0, 15, 2)
							target = substr($0, 15, 2);
							#print target
							gsub(/[^0-9]/, "", target);

							if (target != "") {
								num = target + 0;
								if(num == 0) {
									print name": user mode"
								}else if(num == 1) {
									print name": driver mode"
								}else {
									print name":" num
								}
						}
				}' param.h | tee -a $mode_file
		cd ../../
	done
}

function set_mode() {
	mode=$1
	for ((i=$default_idx; i<"${#items_array[@]}"; i++)); do
			cd ${items_array["$i"]}
			ver=$(ls | head -n 10 | tail -1)
			cd $ver
			awk -v driver="$mode" '/main_param_bin\[\]/{
			print; getline;
			$0=substr($0,1,15) driver substr($0,17);
			print;
			next
		}1' param.h > temp
		mv temp param.h
		cd ../../
	done
}

function run_function() {

	# Delete old csv file.
	if [ -f "../"$CSV_folder"/${items_array["$1"]}.csv" ]; then
		rm ../"$CSV_folder"/${items_array["$1"]}.csv
	fi

	cd ${items_array["$1"]}
	ver=$(ls | head -n 10 | tail -1)
	cd ..
	##echo $ver
	echo "----------- Test ${items_array[$1]} ---------------------"
	if [[ "${items_array[$1]}" == "fan" || "${items_array[$1]}" == "temp" || "${items_array[$1]}" == "voltage" || "${items_array[$1]}" == "psu" ]]; then
        # pwd
		${root_path}/hwmnt.sh ${items_array["$1"]}/$ver ../"$CSV_folder"/${items_array["$1"]}.csv ${items_array["$1"]}

    	# Check status of sensors
    	pass_cnt=$(cat "../"$CSV_folder"/${items_array["$1"]}.csv" | grep "PASS" | wc -l)
    	if [ $pass_cnt -eq 0 ]; then
    		return
    	fi

    	## Add external tests. (fan control and power cord unplugged.)
    	if [ "${items_array[$1]}" == "fan" ];then
    		${root_path}/fanctrl.sh ${items_array["$1"]}/$ver ../"$CSV_folder"/${items_array["$1"]}.csv ${items_array["$1"]}
    	elif [ "${items_array[$1]}" == "psu" ]; then
    		${root_path}/psuex.sh ${items_array["$1"]}/$ver ../"$CSV_folder"/${items_array["$1"]}.csv ${items_array["$1"]}
    	fi

    else
    	# pwd
    	## 0: no button test, 1: test button
    	if [ "${items_array[$1]}" == "lcmcom" ];then
    		${root_path}/"${items_array[$1]}".sh ${items_array["$1"]}/$ver ../"$CSV_folder"/"${items_array[$1]}".csv "${items_array[$1]}" $lcmbtn
    	else
    		${root_path}/"${items_array[$1]}".sh ${items_array["$1"]}/$ver ../"$CSV_folder"/"${items_array[$1]}".csv "${items_array[$1]}"
    	fi
	fi
}

if [ "$choice" -lt "${#items_array[@]}" ]; then

	#echo $choice

	if [ "$choice" -eq "0" ]; then
		show_mode
	elif [ "$choice" -eq "1" ]; then
		set_mode 0
	elif [ "$choice" -eq "2" ]; then
		set_mode 1
	elif [ "$choice" -eq "3" ]; then
		for ((i=$default_idx; i<"${#items_array[@]}"; i++)); do
			run_function $i
		done
	elif [ "$choice" -eq "4" ]; then
			# Delete old csv file.
			if [ -f "../"$CSV_folder"/All_Total.csv" ]; then
				rm ../"$CSV_folder"/All_Total.csv
			fi
		${root_path}/All_Total.sh ../$CSV_folder
	else
		run_function $choice
	fi
fi
