#!/bin/bash
# Config monitors for laptop + DisplayPort MST setups 
# Usage:
#

printUsage() {
    echo -e "USAGE:"
    echo -e "\t-a/--arrangement: order of the displays, comma separated (ex: 1,2,3 or 1,3,2,4) [str]"
    echo -e "\t-p/--primary: primary display number (used for audio) [int]"
    echo -e "\t-l/--laptop: laptop screen on or off (ex: on or off) [str]"
    echo -e "\t-e/--enabled-mons: how many enable to monitors starting from the left [int]"
    echo -e "\t-s/--scale: scaling factor used for external monitors [float]"
    echo -e "\nExample: mons --arrangement 1,3,2 --enabled-mons 2 --laptop on --primary 1 --scale 1.33"
}

round() {
    echo ${1} | awk '{printf("%d\n",$1 + 0.5)}'
}

# gather args
args=$(getopt -l "arrangement:,laptop:,enabled:,primary:,scale:,debug,help" -o "a:l:e:p:s:hd" -- "$@")

#if ! [ $(eval set -- "$args") ] ; then
#    printUsage
#    exit 1
#fi

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
                -s|--scale)
                        scale="$2"
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

if [[ ! "${arrangement}" ]] || [[ ! "${laptop}" ]] || [[ ! "${enabled}" ]] || [[ ! "${primary}" ]]; then
    printUsage
    exit 1
fi

xrandr=$(xrandr)

laptopDP='eDP-1'
for monitor in $(echo "${xrandr}" | grep -E '.*connected\s[0-9]|\sconn' | grep -iv "${laptopDP}" | awk '{print $1}' | sort); do
    monitors+=("${monitor}")
done

debug "Monitor arrangenent: $(if [[ ${laptop} == "on" ]]; then printf "${laptopDP} "; fi)$(IFS=','; for id in ${arrangement}; do printf "${monitors[$((${id} -1))]} "; done)"

count=0

debug "Starting loop"
IFS=',';
for id in ${arrangement}; do
    if [[ ${count} == ${enabled} ]]; then
        disable=1
    fi
    (( count++ ))
    if [[ ! ${prev} ]] && [[ ! ${laptop_set} ]]; then
        debug "No previous display set, setting laptop display options"
        mon_res=$(echo ${xrandr} | grep ${laptopDP} -A1 | tail -n1 | awk '{print $1}' | cut -d'x' -f1)
        cmd="xrandr --output ${laptopDP}"
        if [[ ${laptop} == "on" ]]; then
            debug "Laptop mode set to auto"
            cmd+=" --auto"            
        elif [[ ${enabled} -gt 0 ]]; then
            debug "Laptop mode set to off"
            cmd+=" --off"
        else
            debug "Laptop mode set to auto"
            cmd+=" --auto"
        fi
        if [[ ${enabled} -eq 0 ]]; then
            debug "No other displays enabled, setting laptop to primary"
            cmd+=" --primary"
        fi
        current_pos=$(( current_pos + mon_res ))
        laptop_set=1
    fi
    if [[ ${id} -gt ${#monitors[@]} ]]; then
        debug "skipping monitor ${id} because only ${#monitors[@]} monitors found"
        continue
    fi
    monitor_name=${monitors[$((${id} -1))]}
    mon_res=$(echo ${xrandr} | grep ${monitor_name} -A1 | tail -n1 | awk '{print $1}' | cut -d'x' -f1)
    debug "Setting options for monitor ${monitor_name}"
    if [[ ${id} -eq ${primary} ]] && [[ ! ${disable} ]]; then
        debug "${monitor_name} set as primary display"
        cmd+=" --output ${monitor_name} --primary"
    else
        cmd+=" --output ${monitor_name}"
    fi
    if [[ ! ${scale} ]]; then
        scale=1
    fi
    if [[ ! ${disable} ]]; then
        debug "${monitor_name} set to auto mode"
        cmd+=" --auto"
        cmd+=" --scale ${scale}x${scale}"
        cmd+=" --pos ${current_pos}x0"
    else
        debug "${monitor_name} set to off mode"
        cmd+=" --off"
    fi
    scaled_res=$(round $(echo "${mon_res} * ${scale}" | bc))
    debug "Current position: ${current_pos}"
    debug "Scaled resolution: $(round ${scaled_res})"
    current_pos=$(echo "${current_pos} + ${scaled_res}" | bc)
    debug "New position: ${current_pos}"
    prev=${id}
done

# run the command
echo "RUNNING ${cmd}"
printf "Press ENTER to continue"; read
eval "${cmd}"
