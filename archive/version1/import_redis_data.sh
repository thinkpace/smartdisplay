#!/bin/sh

# Requirement: redis-cli needs to be installed!

dataFile="data.redis"

while getopts "d" opt; do
    case $opt in
        d)
            dataFile="data-debug.redis"
            ;;
    esac
done

cat $dataFile | redis-cli -h 192.168.178.52 --pipe

