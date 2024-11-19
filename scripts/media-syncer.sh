#!/bin/bash

######################################################################################

scriptName=$(basename -- "$0")
for pid in $(pidof -x ${scriptName}); do
    if [ $pid != $$ ]; then
        echo "[$(date)] : $scriptName : Process is already running with PID $pid"
        exit 1
    fi
done

######################################################################################

if [ "${LOGNAME}" != "matt" ]; then
    echo "[$(date)] : $scriptName : Process must be ran by the 'matt' user."
    exit 1
fi

######################################################################################

if [ "$TERM" == "xterm" ]; then
    VERBOSE="-v -h --progress"
else
    VERBOSE=""
fi

######################################################################################

if [ "$TERM" == "xterm" ]; then
    echo
    echo "-----------------------------------------------------------"
    echo "Media Syncer :: OdinTV.local -> JackMedia.local"
    date
    echo ""
    echo "Drive 1"
fi

rsync -a ${VERBOSE} --exclude Working/ root@10.0.0.10:/var/media/Data1/ /mnt/media1/ --delete

if [ "$TERM" == "xterm" ]; then
    echo
    echo "Drive 2"
fi

rsync -a ${VERBOSE} --exclude Working/ --exclude Complete/ --exclude Torrents/ --exclude Old/ --exclude www.asstr.org.rar root@10.0.0.10:/var/media/Data2/ /mnt/media2/Media/ --delete

if [ "$TERM" == "xterm" ]; then
    echo "-----------------------------------------------------------"
    date
    echo
fi
