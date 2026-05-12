################################################
####  LED test script
################################################
path=$1
log_file=$2
sample=$3
rm -rf $log_file

root_path=$(pwd)
csv_file=${root_path}/$log_file 
gpio_file=${root_path}/../gpio.tmp  
cd $path

declare -i gpio_err=0

echo -e "--- Test make ---" | tee -a $csv_file 
#### Building test : make clean
make clean  | tee -a $csv_file 
gpio_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $gpio_check_flag -ne 0 ]; then
    gpio_err=1
    echo "Fail : make clean failed." | tee -a $csv_file 
    echo "FAIL" | tee -a $csv_file 
    exit 
fi

#### Building test : make
make  | tee -a $csv_file  
gpio_check_flag=$(cat $csv_file | grep "Error" | wc -l)
if [ $gpio_check_flag -ne 0 ]; then
    gpio_err=1
    echo "Fail : make failed." | tee -a $csv_file 
    echo "FAIL" | tee -a $csv_file 
    exit 
fi

echo "-----------------" | tee -a $csv_file  

echo "$path/$sample" >> $csv_file
./$sample  | tee -a $csv_file 

# Check help files
gpio_r=$(cat $csv_file | grep -e "-r")
if [ -z "$gpio_r" ]; then
	gpio_err=1
	echo "Fail : help() is error." | tee -a $csv_file 
	echo "FAIL" | tee -a $csv_file 
	exit
fi

##### Run ./gpio -r
#### Analyze GPO and GPI  
./gpio -r | cut -d":" -f 1 > $gpio_file
declare -i i_idx=0
declare -i o_idx=0
declare -a gpi
declare -a gpo

while read -r line
do
    #printf '%s\n' "$line"
    io=$(echo $line | cut -d" " -f 1) 
    if [ "$io" = "GPI" ]; then
        gpi[i_idx]=$(echo $line | cut -d" " -f 2)
        i_idx=$(($i_idx+1))
    elif [ "$io" = "GPO" ]; then
        gpo[o_idx]=$(echo $line | cut -d" " -f 2)
        o_idx=$(($o_idx+1))
    fi
done < "$gpio_file"

if [ $i_idx -lt 4 ]; then
    echo "GPI number error: $i_idx" | tee -a $csv_file 
    gpio_err=1
    echo "Fail" | tee -a $csv_file 
    exit 1 
fi

if [ $o_idx -lt 4 ]; then
    echo "GPO number error: $o_idx"  | tee -a $csv_file
    gpio_err=1
    echo "Fail" | tee -a $csv_file  
    exit 1 
fi

#echo "GPI - ${gpi[0]}, ${gpi[1]}, ${gpi[2]}, ${gpi[3]}"
#echo "GPO - ${gpo[0]}, ${gpo[1]}, ${gpo[2]}, ${gpo[3]}"

for ((i=0;i<4;i++))
do
      # Set high test
    echo "------------  GPO ${gpo[i]} -----------------"  | tee -a $csv_file
    echo "./gpio -${gpo[i]}h" | tee -a $csv_file 
    ./gpio -${gpo[i]}h | tee -a $csv_file 

    hl=$(./gpio -r | grep "GPO ${gpo[i]}")
    echo $hl | tee -a $csv_file  
    out=$(echo $hl | cut -d":" -f 2 | tr -d ' ')
    if [ "$out" != "1" ]; then
        echo "Get GPO${gpo[i]} fail."  | tee -a $csv_file
        gpio_err=1
    else
        echo "Get GPO${gpo[i]} pass." | tee -a $csv_file
    fi

    hl=$(./gpio -r | grep "GPI ${gpi[i]}") 
    echo $hl | tee -a $csv_file  
    in=$(echo $hl | cut -d":" -f 2 | tr -d ' ')
    if [ "$in" != "1" ]; then
        echo "Get GPI${gpi[i]} fail." | tee -a $csv_file
        gpio_err=1
   else
        echo "Get GPI${gpi[i]} pass." | tee -a $csv_file
    fi
 
    # Set low test
    echo "./gpio -${gpo[i]}l" | tee -a $csv_file 
    ./gpio -${gpo[i]}l  | tee -a $csv_file 

    hl=$(./gpio -r | grep "GPO ${gpo[i]}")
    echo $hl | tee -a $csv_file  
    out=$(echo $hl | cut -d":" -f 2 | tr -d ' ')
    if [ "$out" != "0" ]; then
        echo "Get GPO${gpo[i]} fail." | tee -a $csv_file
        gpio_err=1
    else
        echo "Get GPO${gpo[i]} pass." | tee -a $csv_file
    fi

    hl=$(./gpio -r | grep "GPI ${gpi[i]}")
    echo $hl | tee -a $csv_file  
    in=$(echo $hl | cut -d":" -f 2 | tr -d ' ')
    if [ "$in" != "0" ]; then
        echo "Get GPI${gpi[i]} fail." | tee -a $csv_file
        gpio_err=1
   else
        echo "Get GPI${gpi[i]} pass." | tee -a $csv_file
    fi
done

#### Test result
if [ "$gpio_err" -eq 0 ]; then
    echo "PASS" | tee -a $csv_file 
else
    echo "FAIL" | tee -a $csv_file 
fi
