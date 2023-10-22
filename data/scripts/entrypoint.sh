#!/bin/bash
#

#set -eu
set -o pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

HOMEDIR=${HOMEDIR:-/home/wospi}

run_cron() {
    echo "#1 start cron daemon"
    sudo /usr/sbin/service cron start
}

run_mqtt() {
    echo "#2 start wospi mqtt service"
    sudo /usr/bin/python $HOMEDIR/tools/wospi2mqtt2.py > /dev/null 2>&1 &
    sleep 1
}

run_wospi() {
    echo "#3 start wospi"

    PATH=$PATH:$HOMEDIR/wetter:$HOMEDIR/tools

    sudo /etc/init.d/wospi start
    el=$?

    if [ $el -ne 0 ]; then
	echo "ERROR: failed to start wospi"
	exit 1
    else
	PID=$(ps -ef|grep wospi.py[c] | awk '{print $2}')
	echo "INFO: wospi is running with PID $PID"
	ps -ef|grep pytho[n]
    fi
}


#------------------------
#
echo "INFO: $0 called with: '${@}'"

case "$1" in
	wospi)
	    echo "INFO: $0 started with command '$1'"
	    run_cron
	    run_mqtt
	    run_wospi
	    ;;
	bash)
	    echo "INFO: $0 started with command '$1'"
	    exec "$@"
	    ;;
	mqtt)
	    echo "INFO: $0 started with command '$1'"
	    run_mqtt
	    ;;
	*)
	    echo "WARN: $0 no parameter given."
	    exit 1
	    ;;
esac

exit 0

