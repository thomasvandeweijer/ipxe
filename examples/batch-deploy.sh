#!/bin/bash

curl -X POST \
-H "Content-Type: application/json" \
-H "X-Auth-Token: ${METAL_AUTH_TOKEN}" \
"https://api.equinix.com/metal/v1/projects/8ee6de57-73a3-433d-a118-bd07af3da428/devices/batch" \
-d '{
    "batches": [
        {
        "metro": "am",
        "plan": "c3.small.x86",
        "operating_system": "custom_ipxe",
        "always_pxe": true,
        "ipxe_script_url": "http://ipxe.thomasvdw.com/flatcar/",
        "quantity": 3
        }
    ]
}'
