####author : lovequeen
####date	:
####Wed Jul 22 14:37:04 CST 2026 (2026/07/22-14:37:04)
####
####like set env!!

echo "start.sh "
pwd
#### mkdir csv dir
if [[ ! -d ../csv ]]; then
    mkdir ../csv
fi

if [[ ! -f ../csv/nicee_slot_param.txt ]];then
    echo -e "" > ../csv/nicee_slot_param.txt
fi
