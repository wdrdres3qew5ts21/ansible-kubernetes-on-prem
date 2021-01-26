#!/bin/bash
while getopts ":h:d" opt; do
  case $opt in
    a)
      echo "-a was triggered!" >&2
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

KUBE_CONTROL_PLANE="THBKKPS1626"

if [ "$HOSTNAME" = "$KUBE_CONTROL_PLANE" ]; then
    echo "Strings are equal."
else
    echo "Strings are not equal."
fi