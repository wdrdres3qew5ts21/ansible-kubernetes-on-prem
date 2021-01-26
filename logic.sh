#!/bin/bash

KUBE_CONTROL_PLANE="THBKKPS1626"

if [ "$HOSTNAME" = "$KUBE_CONTROL_PLANE" ]; then
    echo "Strings are equal."
else
    echo "Strings are not equal."
fi