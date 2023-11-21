#!/bin/bash
#

#set -eu
set -o pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

RUNUSER=wospi
HOMEDIR=${HOMEDIR:-/home/$RUNUSER}

PROG=wospi.pyc
RUNSCR=$HOMEDIR/wetter/$PROG

#------------------------
#
logMSG() {
    #DT=$(date +'%Y-%m-%e %H:%M:%S')
    DT=$(date +'%a %b %e %T %Y')
    echo "$DT $1: $2"
}

run_cron() {
    logMSG INFO "#1 start cron daemon"
    sudo /usr/sbin/service cron start
}

run_mqtt() {
    if [ "$TARGET" != "image-vanilla" ]; then
	logMSG INFO "#2 start mqtt service"
	/usr/bin/python $HOMEDIR/tools/wospi2mqtt2.py &
	sleep 1
    fi
}

env2file() {
    logMSG INFO "#3 save environment variables to .env"
    if [ ! -f "/tmp/.env" ]; then
	env|egrep "HOMEPATH|BACKUPPATH|CSVPATH|TMPPATH|WLOGPATH|WOSPI_CONFIG|BACKUP_DIR|MQTT_" > /tmp/.env
    fi
}

run_wospi() {
    logMSG INFO "#3 start wospi"

    PATH=$PATH:$HOMEDIR/wetter:$HOMEDIR/tools
    cd $HOMEDIR

    #sudo /etc/init.d/wospi start
    /usr/bin/python $RUNSCR 
    el=$?

    if [ $el -ne 0 ]; then
	logMSG ERROR "failed to start wospi"
	exit 1
    else
	PID=$(ps -ef|grep wospi.py[c] | awk '{print $2}')
	logMSG INFO "wospi is running with PID $PID"
	ps -ef|grep pytho[n]
    fi
}

run_loop() {
    while :; do
	logMSG INFO "Press [CTRL+C] to stop.."
	sleep 1
    done
}


#------------------------
#

case "$1" in
	cron)
	    run_cron
	    ;;
	mqtt)
	    run_mqtt
	    ;;
	wtest)
	    run_wospi
	    ;;
	wospi)
	    env2file
	    run_cron
	    run_mqtt
	    run_wospi
	    ;;
	bash)
	    exec "$@"
	    ;;
	loop)
	    run_loop
	    ;;
	*)
	    if [ -$# -eq 0]; then
		logMSG WARN "${0##*/} no parameter given."
	    else
		logMSG INFO "${0##*/} called with unknown parameter: '${@}'"
	    fi
	    logMSG INFO "usage: ${0##*/} { cron|mqtt|wospi|bash|loop|wtest }"
	    exit 1
	    ;;
esac

exit 0

