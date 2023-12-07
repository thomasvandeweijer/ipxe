#!/usr/bin/env bash

get_external_info() {
# return routable IP address, external interface and default gateway
# the first positional parameter can be 4 or 6 and determines whether IPv4 of IPv6 information is returned
    local dev
    local via
    local global_ip
    if [ "$1" != "4" ] && [ "$1" != "6" ]; then
        echo "No valid protocol given. Should be either 4 or 6"
        exit 1
    fi

    PROTO=$1
    # determine the external interface by checking where the default route leads
    dev=$(ip -"${PROTO}" route show exact default | grep -Eo 'dev[[:space:]]*[^[:space:]]+' | cut -d' ' -f2)
    via=$(ip -"${PROTO}" route show exact default | grep -Eo 'via[[:space:]]*[^[:space:]]+' | cut -d' ' -f2)

    # now determine the globally routable public IP by checking which source address is used to get to the default gw
    global_ip=$(ip -"${PROTO}" route get "${via}" | grep -Eo 'src[[:space:]]*[^[:space:]]+' | cut -d' ' -f2)

    printf "%s %s %s\n" "${dev}" "${via}" "${global_ip}"

}

read -r EXT_IF4 DEF_GW4 GLOBAL_IP4 <<<"$(get_external_info 4)"
read -r EXT_IF6 DEF_GW6 GLOBAL_IP6 <<<"$(get_external_info 6)"

if [ "${EXT_IF4}" != "${EXT_IF6}" ]; then
    echo "External interface for IPv4 is different from the external interface for IPv6!"
    exit 1
fi

# exit with an error if one of the keys returns an empty value
for i in EXT_IF4 DEF_GW4 GLOBAL_IP4 DEF_GW6 GLOBAL_IP6; do
    if [ -z "${!i}" ]; then
       echo "Error getting value $i from ip route info"
       exit 1
    fi
done

for i in EXT_IF4 DEF_GW4 GLOBAL_IP4 DEF_GW6 GLOBAL_IP6; do
    echo "${i}=${!i}"
done
