#!/bin/bash
# Config monitors for laptop + DisplayPort MST setups 
# Usage:
#
## mons -a 1,3,2 -e 2 -p 1 -l on
## mons --arrangement 1,3,2 --enabled-mons 2 --laptop on

printUsage() {
    echo -e "USAGE:"
    echo -e "\t-a/--arrangement: order of the displays, comma separated (ex: 1,2,3 or 1,3,2,4) [str]"
    echo -e "\t-p/--primary: primary display number (used for audio) [int]"
    echo -e "\t-l/--laptop: laptop screen on or off (ex: on or off) [str]"
    echo -e "\t-e/--enabled-mons: how many enable to monitors starting from the left [int]"
    echo -e "\nExample: mons --arrangement 1,3,2 --enabled-mons 2 --laptop on --primary 1"
}

# gather args
args=$(getopt -l "arrangement:,laptop:,enabled:,primary:,debug,help" -o "a:l:e:p:hd" -- "$@")

if ! [ $(eval set -- "$args") ] ; then
    printUsage
    exit 1
fi

echo fu
while [ $# -ge 1 ]; do
        case "$1" in
                --)
                    # No more options left.
                    shift
                    break
                   ;;
                -a|--arrangement)
                        arrangement="$2"
                        shift
                        ;;
                -l|--laptop)
                        laptop="$2"
                        shift
                        ;;
                -e|--enabled-mons)
                        enabled="$2"
                        shift
                        ;;
                -p|--primary)
                        primary="$2"
                        shift
                        ;;
                -d|--debug)
                        debug=1
                        shift
                        ;;
                -h|--help)
                        printUsage
                        exit 0
                        ;;
        esac
        shift
done

debug() {
    if [[ ${debug} ]]; then
        printf "DEBUG: ${@}\n"
    fi
}

debug test

if [[ ! "${arrangement}" ]] || [[ ! "${laptop}" ]] ||[[ ! "${enabled}" ]] ||[[ ! "${primary}" ]]; then
    printUsage
    exit 1
fi

laptopDP='eDP-1'
for monitor in $(xrandr | grep conn | grep -ivE ".*connected \(|${laptopDP}" | awk '{print $1}' | sort); do
    monitors+=("${monitor}")
done

count=0

debug "Starting loop"
IFS=',';
for id in ${arrangement}; do
    if [[ ${count} == ${enabled} ]]; then
        disable=1
    fi
    (( count++ ))
    if [[ ! ${prev} ]]; then
        debug "No previous display set"
        cmd="xrandr --output ${laptopDP}"
        if [[ ${laptop} == "on" ]]; then
            cmd+=" --auto"            
        elif ${enabled} -gt 0 ]]; then
            cmd+=" --off"
        else
            cmd+=" --auto"
        fi
        if [[ ${enabled} -eq 0 ]]; then
            cmd+=" --primary"
            break
        fi
    fi
    if [[ ${id} -gt ${#monitors[@]} ]]; then
        echo "skipping monitor ${id}"
        continue
    fi
    if [[ ${id} -eq ${primary} ]] && [[ ! ${disable} ]]; then
        cmd+=" --output ${monitors[$((${id} - 1))]} --primary"
    else
        cmd+=" --output ${monitors[$((${id} - 1))]}"
    fi
    if [[ ${prev} ]]; then
        cmd+=" --right-of ${monitors[$((${prev} - 1))]}"
    elif [[ ${laptop} -eq "on" ]]; then
        cmd+=" --right-of ${laptopDP}"
    fi
    if [[ ! ${disable} ]]; then
        cmd+=" --auto"
    else
        cmd+=" --off"
    fi
    prev=${id}
done

# run the command
echo "RUNNING ${cmd}"
read
eval "${cmd}" 
