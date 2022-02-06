#!/bin/bash
# Config monitors 
# Usage:
#
## mons -a 1,3,2 -e 2 -p 1 -l on
## mons --arrangement 1,3,2 --enabled-mons 2 --laptop on

# gather args
args=$(getopt -l "arrangement:laptop:enabled:primary:" -o "a:l:e:p:h" -- "$@")
eval set -- "$args"

printUsage() {
    echo -e "USAGE (all arguments required):"
    echo -e "\t-a/--arrangement: order of the displays, comma separated (ex: 1,2,3 or 1,3,2,4) [str]"
    echo -e "\t-p/--primary: primary display number (used for audio) [int]"
    echo -e "\t-l/--laptop: laptop screen on or off (ex: on or off) [str]"
    echo -e "\t-e/--enabled-mons: how many enable to monitors starting from the left [int]"
    echo -e "\nExample: mons --arrangement 1,3,2 --enabled-mons 2 --laptop on --primary 1"
}

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
        -h)
            printUsage
            exit 0
            ;;
    esac
    shift
done

if [[ ! "${arrangement}" ]] || [[ ! "${laptop}" ]] ||[[ ! "${enabled}" ]] ||[[ ! "${primary}" ]]; then
    printUsage
    exit 1
fi

for monitor in $(xrandr | grep -iE '^DP.*\sconnected' | awk '{print $1}' | cut -d'-' -f2 | sort); do
    monitors+=("DP-${monitor}")
done

laptopDP='eDP-1'

IFS=',';
for id in ${arrangement}; do
    (( count++ ))
    if [[ ! ${prev} ]]; then
        if [[ ${laptop} == "on" ]]; then
            cmd="xrandr --output ${laptopDP} --auto"
        else
            cmd="xrandr --output ${laptopDP} --off"
        fi
    fi
    if [[ ${id} -eq ${primary} ]]; then
        cmd="${cmd} --output ${monitors[$((${id} - 1))]} --primary"
    else
        cmd="${cmd} --output ${monitors[$((${id} - 1))]}"
    fi
    if [[ ${prev} ]]; then
        cmd="${cmd} --right-of ${monitors[$((${prev} - 1))]}"
    elif [[ ${laptop} -eq "on" ]]; then
        cmd="${cmd} --right-of ${laptopDP}"
    fi
    if [[ ! ${disable} ]]; then
        cmd="${cmd} --auto"
    else
        cmd="${cmd} --off"
    fi
    prev=${id}
    if [[ ${count} == ${enabled} ]]; then
        disable=1
    fi
done

# run the command
echo "RUNNING ${cmd}"
eval "${cmd}" 
