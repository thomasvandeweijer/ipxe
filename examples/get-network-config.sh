#!/usr/bin/env bash

set -x

get_external_info() {
# return routable IP address, external interface and default gateway
# the first positional parameter can be 4 or 6 and determines whether IPv4 of IPv6 information is returned
    local dev
    local via
    local global_ip

    if [ "$1" != "4" ] && [ "$1" != "6" ]; then
        >&2 echo "No valid protocol given. Should be either 4 or 6"
        exit 1
    fi

    PROTO=$1
    # determine the external interface by checking where the default route leads
    dev=$(ip -"${PROTO}" route show exact default | grep -Eo 'dev[[:space:]]*[^[:space:]]+' | cut -d' ' -f2)

    if [ -n "${dev}" ]; then
    # determine the globally routable public IP by checking which source address is used to get to the default gw
        via=$(ip -"${PROTO}" route show exact default | grep -Eo 'via[[:space:]]*[^[:space:]]+' | cut -d' ' -f2)
        global_ip=$(ip -"${PROTO}" route get "${via}" | grep -Eo 'src[[:space:]]*[^[:space:]]+' | cut -d' ' -f2)
    printf "%s %s %s\n" "${dev}" "${via}" "${global_ip}"
    else
        return
    fi

}

modified_fibonacci=(2 3 5 8 13 13 21 21 34 ) # start with fast retry then exponentially back off

for i in "${modified_fibonacci[@]}"
do
    read -r EXT_IF4 DEF_GW4 GLOBAL_IP4 <<<"$(get_external_info 4)"
    read -r EXT_IF6 DEF_GW6 GLOBAL_IP6 <<<"$(get_external_info 6)"

    # see if any values came back empty
    for j in EXT_IF4 DEF_GW4 GLOBAL_IP4 DEF_GW6 GLOBAL_IP6; do
        if [ -z "${!j}" ]; then
           >&2 echo "Error getting value $i from ip route info. Retrying after $i seconds"
           continue
        fi
    done
    break # all values were succesfully retrieved
done


if [ "${EXT_IF4}" != "${EXT_IF6}" ]; then
    >&2 echo "External interface for IPv4 is different from the external interface for IPv6!"
    exit 1
fi

for i in EXT_IF4 DEF_GW4 GLOBAL_IP4 DEF_GW6 GLOBAL_IP6; do
    echo "${i}=${!i}"
done
