## Check status
if [ "$cmd" = "ee" ]; then
        status=$(cat $bypass_file | grep "$bypass_ee_str" | wc -l)
        echo "Currently at line $LINENO in file $0"
elif [ "$cmd" = "dd" ]; then
    status=$(cat $bypass_file | grep "$bypass_dd_str" | wc -l)
        echo "Currently at line $LINENO in file $0"
elif [ "$cmd" = "ed" ]; then
    status=$(cat $bypass_file | grep "$bypass_ed_str" | wc -l)
        echo "Currently at line $LINENO in file $0"
else
    echo "command error: $cmd"  | tee -a $csv_file
        echo "Currently at line $LINENO in file $0"
fi
