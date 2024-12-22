#!/bin/bash

log () {
  echo $(date +"%Y-%m-%d %k:%M:%S") $1
}

/usr/bin/killall chromium-browser

sleep 1m

while true
do
  /usr/bin/curl -sS localhost | /bin/grep "<title>Smart Display</title>"
  curlResult=$?
  log "curlResult is $curlResult ..."
  if [[ $curlResult == 0 ]]
  then
    log "... smartdisplay is up and running, continue"
    /usr/bin/chromium-browser --incognito --start-fullscreen http://smartdisplay.home.familiebaus.de &
    sleep 1m
    break
  else
    log "... smartdisplay is down, sleep 1m"
    sleep 1m
  fi
done
