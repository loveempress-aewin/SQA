################################################
####  bypass test script
################################################
####+ /root/LINUX-1949/ccauto/bypass.sh bypass/v1.00 ../csv/bypass.csv bypass
path=$1
log_file=$2
sample=$3
rm -rf $log_file

root_path=$(pwd) #### samplecode
csv_file=${root_path}/$log_file
bypass_file=${root_path}/../csv/bypass.tmp
nicee_path="nicee"

declare -i bypass_err=0

cd $path ####  cd bypass/v1.00

# Get bypass number in motherboard.
cd ../../$nicee_path
ver=$(ls | head -n 10 | tail -1)
cd $ver

echo -e "--- Test make ---"
#### Building test : make clean
make clean  | tee -a $csv_file
bypass_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $bypass_check_flag -ne 0 ]; then
    bypass_err=1
    echo "Fail : make clean failed." | tee -a $csv_file
    echo "FAIL" | tee -a $csv_file
    exit 1
fi

#### Building test : make
make
bypass_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $bypass_check_flag -ne 0 ]; then
    wdt_err=1
    echo "Fail : make failed." | tee -a $csv_file
    echo "FAIL" | tee -a $csv_file
    exit 1
fi

echo "-----------------" | tee -a $csv_file

./nicee -show 0 > $bypass_file
bypass_mb_no=$(cat $bypass_file |  grep "bypass" | cut -d"=" -f 2 |  cut -d" " -f 2)
echo "Pair number of Mother board : $bypass_mb_no"

if [ -z $bypass_mb_no ]; then
	bypass_err=1
	echo "Bypass number of mother board is empty."  | tee -a $csv_file
	echo "FAIL" | tee -a $csv_file
	exit 1
fi

if [ "$bypass_mb_no" = "No" ]; then
    bypass_mb_number=0
else
    bypass_mb_number=$bypass_mb_no
fi

./nicee -show 1 > $bypass_file
bypass_slot1_no=$(cat $bypass_file |  grep "bypass" | cut -d"=" -f 2 |  cut -d" " -f 2)
echo "Pair number of slot#1 : $bypass_slot1_no"

if [ -z $bypass_slot1_no ]; then
	wdt_err=1
	echo "Bypass number of slot #1 is empty."| tee -a $csv_file
	echo "FAIL" | tee -a $csv_file
	exit
fi

if [ "$bypass_slot1_no" = "No" ]; then
    bypass_slot1_number=0
else
    bypass_slot1_number=$bypass_slot1_no
fi

./nicee -show 2 > $bypass_file
bypass_slot2_no=$(cat $bypass_file |  grep "bypass" | cut -d"=" -f 2 |  cut -d" " -f 2)
echo "Pair number of slot#2 : $bypass_slot2_no"

if [ -z $bypass_slot2_no ]; then
	wdt_err=1
	echo "Bypass number of slot #2 is empty."| tee -a $csv_file
	echo "FAIL" | tee -a $csv_file
	exit
fi

if [ "$bypass_slot2_no" = "No" ]; then
    bypass_slot2_number=0
else
    bypass_slot2_number=$bypass_slot2_no
fi

cd ../../$path ####goto bypass

# echo -e "--- Test make ---" | tee -a $csv_file
echo -e "--- Test make ---" > $csv_file ##temp : overwright
#### Building test : make clean
make clean  | tee -a $csv_file
bypass_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $bypass_check_flag -ne 0 ]; then
    bypass_err=1
    echo "Fail : make clean failed." | tee -a $csv_file
    echo "FAIL" | tee -a $csv_file
    exit
fi

#### Building test : make
make  | tee -a $csv_file
bypass_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $bypass_check_flag -ne 0 ]; then
    wdt_err=1
    echo "Fail : make failed." | tee -a $csv_file
    echo "FAIL" | tee -a $csv_file
    exit
fi

echo "-----------------" | tee -a $csv_file
echo "$path/$sample" >> $csv_file

all_slot=255
all_pairs=255
wait_secs=30 ####30 so fast==
timer_secs=10

# Read help
./bypass >> $csv_file
cat $csv_file

#Define in main.h
bypass_ee_str="Power off and power on are enabled"
bypass_dd_str="Power off and power on are disabled"
bypass_ed_str="Power off is enabled and power on is disabled"

# default setting
# 0: Invalide code
bypass_all_codes=("0" "ee" "dd" "ed")
#Save all setting before test.
declare -A bypass_default_arr

function check_bypass() {
    cmd=$1
    slot=$2
    pair=$3
    update=$4

    #echo "$cmd, $slot, $pair, $update"

    ./bypass -$cmd $slot $pair -$update  | tee -a $csv_file
    if [ "$update" = "u" ]; then
        ./bypass -rn $slot $pair  | tee -a $csv_file
        ./bypass -rn $slot $pair > $bypass_file
    else
        ./bypass -r $slot $pair  | tee -a $csv_file
        ./bypass -r $slot $pair > $bypass_file
    fi

    ## Check status
    if [ "$cmd" = "ee" ]; then
         status=$(cat $bypass_file | grep "$bypass_ee_str" | wc -l)
    elif [ "$cmd" = "dd" ]; then
        status=$(cat $bypass_file | grep "$bypass_dd_str" | wc -l)
    elif [ "$cmd" = "ed" ]; then
        status=$(cat $bypass_file | grep "$bypass_ed_str" | wc -l)
    else
        echo "command error: $cmd"  | tee -a $csv_file
    fi

    ## Check slot label
    if [ "$slot" -ne "$all_slot" ]; then
        if [ "$slot" -eq 0 ]; then
            status=$(cat $bypass_file | grep "Motherboard" | wc -l)
            if [ "$status" -eq 0 ];then
                echo "motherboard label failed." | tee -a $csv_file
                bypass_err=1
            fi
        else
            status=$(cat $bypass_file | grep "Slot #$slot" | wc -l)
            if [ "$status" -eq 0 ];then
                echo "slot label failed." | tee -a $csv_file
                bypass_err=1
            fi
        fi
    fi

    ## Check pair number
    if [ "$pair" -ne "$all_pairs" ]; then
        status=$(cat $bypass_file | grep "pair #$pair" | wc -l)
        if [ "$status" -eq 0 ]; then
             echo "pair number label failed." | tee -a $csv_file
             bypass_err=1
        fi
    fi

   ## Check current or update
    if [ "$update" = "u" ]; then
        status=$(cat $bypass_file | grep "default" | wc -l)
        if [ "$status" -eq 0 ];then
            echo "Default settingt label failed." | tee -a $csv_file
            bypass_err=1
        fi
    else
        status=$(cat $bypass_file | grep "current" | wc -l)
        if [ "$status" -eq 0 ];then
            echo "Current setting label failed." | tee -a $csv_file
            bypass_err=1
        fi
    fi
}

function bypass_current_module() {
    mod_slot=$1
    mod_number=$2
    #Set all bypass to ed
    if [ "$mod_slot" -eq 0 ]; then
        echo -e "\n------ Disable all bypass(dd) on mother board  ------------ "  | tee -a $csv_file
    else
        echo -e "\n------ Disable all bypass(dd) on slot #$mod_slot  ------------ "  | tee -a $csv_file
    fi
    for (( i = 1; i <= $mod_number; i++)); do
        check_bypass "dd" $mod_slot $i "nu"
    done

    sleep $wait_secs
    # Get UP ports
    before_up_ports=$(ip -br link | grep "UP " | wc -l)
    ip -br link  | tee -a $csv_file

    #Check ee
    if [ "$mod_slot" -eq 0 ]; then
        echo -e "\n------ Enable all bypass(ee) on mother board  ------------ "  | tee -a $csv_file
    else
        echo -e "\n------ Enable all bypass(ee) on slot #$mod_slot  ------------ "  | tee -a $csv_file
    fi
    for (( i = 1; i <= $mod_number; i++)); do
        check_bypass "ee" $mod_slot $i "nu"
    done

    # Check number of UP ports
    sleep $wait_secs
    ip -br link  | tee -a $csv_file
    after_up_ports=$(ip -br link | grep "UP " | wc -l)
    diff_up_ports=$(( before_up_ports -  after_up_ports))
    correct_up_ports=$(( 2*$mod_number ))
    if [ "$diff_up_ports" -ne "$correct_up_ports" ]; then
        bypass_err=1
        echo "Fail : Link up number is error on ee test. "  | tee -a $csv_file
    fi

    #Check ed
    if [ "$mod_slot" -eq 0 ]; then
        echo -e "\n------ Disable all power on bypass(ed) on mother board  ------------ "  | tee -a $csv_file
    else
        echo -e "\n------ Disable all power on bypass(ed) on slot #$mod_slot  ------------ "  | tee -a $csv_file
    fi
    for (( i = 1; i <= $mod_number; i++)); do
        check_bypass "ed" $mod_slot $i "nu"
    done

	# Check number of UP ports
    sleep $wait_secs
    ip -br link | tee -a $csv_file
    before_up_ports=$(ip -br link | grep "UP " | wc -l)
    diff_up_ports=$(( before_up_ports -  after_up_ports))
    correct_up_ports=$(( 2*$mod_number ))
    if [ "$diff_up_ports" -ne "$correct_up_ports" ]; then
        bypass_err=1
        echo "Fail :  Link up number is error on ed test. " | tee -a $csv_file
    fi

    #Check t(TIMER)
    if [ "$mod_slot" -eq 0 ]; then
        echo -e "\n------ Timer bypass(t) on mother board  ------------ "  | tee -a $csv_file
    else
        echo -e "\n------ Timer bypass(t) on slot #$mod_slot  ------------ "  | tee -a $csv_file
    fi
    for (( i = 1; i <= $mod_number; i++)); do
        ./bypass -t $mod_slot $i -nu $timer_secs  | tee -a $csv_file
    done

    # Check number of UP ports
    sleep $timer_secs
    sleep $wait_secs
    ip -br link | tee -a $csv_file
    after_up_ports=$(ip -br link | grep "UP " | wc -l)
    diff_up_ports=$(( before_up_ports -  after_up_ports))
    correct_up_ports=$(( 2*$mod_number ))
    if [ "$diff_up_ports" -ne "$correct_up_ports" ]; then
        bypass_err=1
        echo "Link up number is error on timer test. "  | tee -a $csv_file
    fi

}

function bypass_save_default_status() {
    code_slot=$1
    code_pair=$2

    # Check ee
    match=$(cat $bypass_file | grep "$bypass_ee_str" | wc -l)
    if [ "$match" -gt 0 ]; then
        bypass_default_arr["$code_slot,$code_pair"]=${bypass_all_codes[1]}
        return
    fi

    # Check dd
    match=$(cat $bypass_file  | grep "$bypass_dd_str" | wc -l)
    if [ "$match" -gt 0 ]; then
        bypass_default_arr["$code_slot,$code_pair"]=${bypass_all_codes[2]}
        #echo "slot$code_slot, pair$code_pair : ${bypass_all_codes[2]}"
        #echo "slot$code_slot, pair$code_pair : ${bypass_default_arr["$code_slot,$code_pair"]}"
        return
    fi

    # Check ed
    match=$(cat $bypass_file  | grep "$bypass_ed_str" | wc -l)
    if [ "$match" -gt 0 ]; then
        bypass_default_arr["$code_slot,$code_pair"]=${bypass_all_codes[3]}
        ##echo "slot$code_slot, pair$code_pair : ${bypass_all_codes[3]}"
        return
    fi

    bypass_default_arr["$code_slot,$code_pair"]=${bypass_all_codes[0]}
    echo "Failed: default bypass code is error. " | tee -a $csv_file
}

function bypass_default_module() {
    mod_slot=$1
    mod_number=$2

    #Save all default setting.
    if [ "$mod_slot" -eq 0 ]; then
        echo -e "\n------ Show all default setting on mother board  ------------ "  | tee -a $csv_file
    else
        echo -e "\n------ Show all default setting on slot$mod_slot  ------------ "  | tee -a $csv_file
    fi
    for (( i = 1; i <= $mod_number; i++)); do
        ./bypass -rn  $mod_slot $i | tee -a $csv_file
        ./bypass -rn  $mod_slot $i > $bypass_file
			bypass_save_default_status $mod_slot $i
    done

    #Check ee
    if [ "$mod_slot" -eq 0 ]; then
        echo -e "\n------ Enable all bypass(ee) default setting on mother board  ------------ "  | tee -a $csv_file
    else
        echo -e "\n------ Enable all bypass(ee) default setting on slot$mod_slot  ------------ "  | tee -a $csv_file
    fi
    for (( i = 1; i <= $mod_number; i++)); do
        check_bypass "ee" $mod_slot $i "u"
    done

    #Check dd
    if [ "$mod_slot" -eq 0 ]; then
        echo -e "\n------ Disable all bypass(dd) default setting on mother board  ------------ "  | tee -a $csv_file
    else
        echo -e "\n------ Disable all bypass(dd) default setting on slot$mod_slot  ------------ "  | tee -a $csv_file
    fi
    for (( i = 1; i <= $mod_number; i++)); do
        check_bypass "dd" $mod_slot $i "u"
    done

    #Check ed
    if [ "$mod_slot" -eq 0 ]; then
        echo -e "\n------ Disable all power on bypass(ed) default setting on mother board  ------------ "  | tee -a $csv_file
    else
        echo -e "\n------ Disable all power on bypass(ed) default setting on slot$mod_slot  ------------ "  | tee -a $csv_file
    fi
    for (( i = 1; i <= $mod_number; i++)); do
        check_bypass "ed" $mod_slot $i "u"
    done

    #Recover default setting
    if [ "$mod_slot" -eq 0 ]; then
        echo -e "\n------ Recovery all bypass default setting on mother board  ------------ "  | tee -a $csv_file
    else
        echo -e "\n------ Recovery all bypass default setting on slot$mod_slot  ------------ "  | tee -a $csv_file
    fi

    for (( i = 1; i <= $mod_number; i++)); do
        check_bypass ${bypass_default_arr["$mod_slot,$i"]} $mod_slot $i "u"
    done
}

## Test bypass of motherboard
if [ "$bypass_mb_number" -gt 0 ]; then
    echo -e "\n------ MCU version of Mother Board ------------ "  | tee -a $csv_file
    # Read version
    ./bypass -v 0 1 | tee -a $csv_file

    # check current functions.
    bypass_current_module 0 $bypass_mb_number

    # check default functions.
    bypass_default_module 0 $bypass_mb_number
fi

## Test bypass of slot 1
if [ "$bypass_slot1_number" -gt 0 ]; then
    echo -e "\n------ MCU version of slot #1 ------------ "  | tee -a $csv_file
    # Read version
    ./bypass -v 1 1 | tee -a $csv_file

    # check current functions.
    bypass_current_module 1 $bypass_slot1_number

    # check default functions.
    bypass_default_module 1 $bypass_slot1_number
fi

#bypass_slot2_number=0
## Test bypass of slot 2
if [ "$bypass_slot2_number" -gt 0 ]; then
    echo -e "\n------ MCU version of slot #2 ------------ "  | tee -a $csv_file
    # Read version
    ./bypass -v 1 2 | tee -a $csv_file

    # check current functions.
    bypass_current_module 2 $bypass_slot2_number

    # check default functions.
    bypass_default_module 2 $bypass_slot2_number
fi

#### Test result
if [ "$bypass_err" -eq 0 ]; then
    echo "PASS" | tee -a $csv_file
else
    echo "FAIL" | tee -a $csv_file
fi
