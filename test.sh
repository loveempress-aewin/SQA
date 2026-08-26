declare -i by_bm_no=0;
# by_number=$(cat ./out_nicee.log |awk -F'=' '/bypass circuits/ {gsub(/[. ]+$/, "", $2); print $2}' )
# declare by_mb_no=$(awk -F'=' '/bypass circuits/ {gsub(/[. ]+$/, "", $2); print $2}' ${bypass_tem})
# if [[ "${by_number}" == " No bypass" ]]; then
#     by_mb_no=0
# else
#     echo "???"
# fi
function F_love(){
    local love_flag=$1;
    if [[ "${by_number}" =~ "No" ]]; then
        by_mb_no=0
    else
        if [[ ${love_flag} == 0 ]];then
            by_mb_no=${by_number}
        elif [[ ${love_flag} == 1 ]];then
            by_slot1=${by_number};
        else
            by_slot2=${by_number};
        fi
    fi
}

by_number=$(cat ./no_bypass.log |awk -F"=" '/bypass circuits/{print $2+0}')
F_love "0"

by_number=$(cat ./out_nicee.log |awk -F"=" '/bypass circuits/{print $2+0}')
F_love 1

echo "the by_mb:[${by_mb_no}]"
echo "the by_slot1:[${by_slot1}]"
