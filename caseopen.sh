################################################
####  Case open test script
################################################
path=$1
log_file=$2
sample=$3
rm -rf $log_file

root_path=$(pwd)
csv_file=${root_path}/$log_file
help_file=${root_path}/help.tmp
cd $path

declare -i caseopen_err=1
declare -i case_status=1

echo -e "--- Test make ---" | tee -a $csv_file
#### Building test : make clean
make clean  | tee -a $csv_file
caseopen_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $caseopen_check_flag -ne 0 ]; then
    caseopen_err=1
    echo "Fail : make clean failed." | tee -a $csv_file
    echo "FAIL" | tee -a $csv_file
    exit
fi

#### Building test : make
make  | tee -a $csv_file
caseopen_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $caseopen_check_flag -ne 0 ]; then
    caseopen_err=1
    echo "Fail : make failed." | tee -a $csv_file
    echo "FAIL" | tee -a $csv_file
    exit
fi

echo "-----------------" | tee -a $csv_file


case_status_close=0
case_status_open=2
case_status_error=1

case_open_str="Caseopen interrupt has been detected."
case_close_str="No caseopen interrupt."
case_error_str="error"

function check_case() {
    status=$(cat $csv_file | tail -1)
    if [ "$status" = "$case_open_str" ]; then
        case_status=$case_status_open
    elif [ "$status" = "$case_close_str" ]; then
        case_status=$case_status_close
    else
        case_status=$case_status_error
    fi

    #echo "case status: $case_status"
}

function wait_caseopen() {
    while true; do
        read -p "Is the case has been open? (y/n)" yn < /dev/tty
        case $yn in
            [Yy]* ) return 0;;
##            [Nn]* ) return 1;;
            * ) echo "Please answer yes.";;
        esac
   done
}


#### help
echo "$path$sample" >> $csv_file
./$sample  | tee -a $csv_file

# Check help files
caseopen_r=$(cat $csv_file | grep -e "-r")
if [ -z "$caseopen_r" ]; then
	caseopen_err=1
	echo "Fail : help() is error." | tee -a $csv_file
	echo "FAIL" | tee -a $csv_file
	exit
fi

#### Read default status
echo "$path$sample  -r " >> $csv_file
./$sample -r  | tee -a $csv_file
check_case
# open : clear and check
# close : open case to check
#            clear and check
if [ $case_status -eq $case_status_error ]; then
    caseopen_err=1
elif [ $case_status -eq $case_status_open ]; then
    echo "$path$sample  -c " >> $csv_file
    ./$sample -c | tee -a $csv_file
    echo "$path$sample  -r " >> $csv_file
    ./$sample -r | tee -a $csv_file
    check_case
    if [ $case_status -eq $case_status_close ]; then
        caseopen_err=0
    fi
else
    echo "Please open case and close it."
    wait_caseopen
    echo "$path$sample  -r " >> $csv_file
     ./$sample -r  | tee -a $csv_file
    check_case
    if [ $case_status -eq $case_status_open ]; then
         echo "$path$sample  -c " >> $csv_file
        ./$sample -c | tee -a $csv_file
        echo "$path$sample  -r " >> $csv_file
        ./$sample -r | tee -a $csv_file
        check_case
        if [ $case_status -eq $case_status_close ]; then
            caseopen_err=0
        fi
    fi
fi

#### Test result
if [ "$caseopen_err" -eq 0 ]; then
    echo "PASS" | tee -a $csv_file
else
    echo "FAIL" | tee -a $csv_file
fi
