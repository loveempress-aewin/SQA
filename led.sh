################################################
####  LED test script
################################################
path=$1
log_file=$2
sample=$3
rm -rf $log_file

root_path=$(pwd)
csv_file=${root_path}/$log_file
help_file=${root_path}/../help.tmp
cmd_file=${root_path}/../csv/cmd.tmp
cd $path

declare -i led_err=0

echo -e "--- Test make ---" | tee -a $csv_file
#### Building test : make clean
make clean  | tee -a $csv_file
led_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $led_check_flag -ne 0 ]; then
    led_err=1
    echo "Fail : make clean failed." | tee -a $csv_file
    echo "FAIL" | tee -a $csv_file
    exit
fi

#### Building test : make
make  | tee -a $csv_file
led_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $led_check_flag -ne 0 ]; then
    led_err=1
    echo "Fail : make failed." | tee -a $csv_file
    echo "FAIL" | tee -a $csv_file
    exit
fi

echo "-----------------" | tee -a $csv_file

##### Run ./led
#### Analyze LED's number and color
echo "$path/$sample" >> $csv_file
./$sample  > $help_file
./$sample  | tee -a $csv_file

# Check help files
led_r=$(cat $help_file | grep -e "-r")
if [ -z "$led_r" ]; then
	led_err=1
	echo "Fail : help() is error." | tee -a $csv_file
	echo "FAIL" | tee -a $csv_file
	exit
fi


cat $help_file | grep led | cut -d":" -f 1 > $cmd_file

function check_led() {
    while true; do
        read -p "Is the LED light working correct? (y/n)" yn < /dev/tty
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
   done
}

# Read the input file line by line
while read -r line
do
    #printf '%s\n' "$line"
    echo "./$line" | tee -a $csv_file
    ./$line
    check_led
    led_check_flag=$?

    #echo $led_check_flag
    if [ "$led_check_flag" -eq 1 ]; then
        led_err=1
        echo "Failed" | tee -a $csv_file
    else
        echo "Pass" | tee -a $csv_file
    fi
done < "$cmd_file"

#### Test result
if [ "$led_err" -eq 0 ]; then
    echo "PASS" | tee -a $csv_file
else
    echo "FAIL" | tee -a $csv_file
fi
