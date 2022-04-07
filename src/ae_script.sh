SCRIPT_PWD=$(dirname $(realpath $0))
export SCRIPT_PWD

source ${SCRIPT_PWD}/function.sh
source ${SCRIPT_PWD}/check_function.sh
source ${SCRIPT_PWD}/yaml.sh

if [ -e "$1" ]
then
    parse_yaml $1 || exit
    create_variables $1 || exit
    
else
    echo "arg1 must be yaml file "
fi

MAX_THREAD=10
LOG_FILE=./log
PARALLEL_OPTIONS="-u --silent --will-cite --retries 5 --jobs $MAX_THREAD --joblog $LOG_FILE "

# first : loop and check
#check loop
echo -e "check loop"
CHECK=""
for host_id in "${!host_list__host[@]}"
do
    hostname="${host_list__host[$host_id]}"
    login="${host_list__login[$host_id]}"
    echo -n "${login}@${hostname}"

    for check_function in ${host_list__check[$host_id]}
    do
        #check_function=${host_list__check[$check_id]}
        THIS_CHECK=$(${check_function} "${login}@${hostname}")
        if [ "$THIS_CHECK" = "ko" ]
        then
            CHECK="ko"
            echo -e " / ${check_function} failed !"
            #fatal ko : breaks 2 loops
            break 2
        else
            echo -en " / ${check_function} ok"
            CHECK="ok"
        fi
    done

    echo -en "\n"
    
done

#don't do anything if only one check failed
if [ "$CHECK" = "ko" -o "$CHECK" = "" ]; then
    echo check error, aborting
    exit
fi


host_list__host_export=$(declare -p host_list__host 2>/dev/null)
host_list__login_export=$(declare -p host_list__login 2>/dev/null)
host_list__script_export=$(declare -p host_list__script 2>/dev/null)
export host_list__host_export host_list__login_export host_list__script_export
echo $host_list__host_export
echo $host_list__login_export
echo $host_list__script_export

function go_script() {
    source ${SCRIPT_PWD}/function.sh
    source ${SCRIPT_PWD}/check_function.sh
    host_id=$1

    eval $host_list__host_export
    eval $host_list__login_export
    eval $host_list__script_export
    hostname="${host_list__host[$host_id]}"
    login="${host_list__login[$host_id]}"
    script="${host_list__script[$host_id]}"
    echo "${login}@${hostname} => $script"
    ssh_ "${login}@${hostname}" "$script"
}
export -f go_script

parallel $PARALLEL_OPTIONS "go_script {}" ::: ${!host_list__host[@]}

