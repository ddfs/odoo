#!/bin/bash
### BEGIN INIT INFO
# Provides:          myportal.fi
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start openerp daemon at boot time
# Description:       Enable service provided by daemon.
# X-Interactive:     true
### END INIT INFO

# init functions
. /lib/lsb/init-functions

# title
title="myportal.fi"

# workspace directory
workspace="/path/to/website/myportal.fi/live"

# daemon [ python or virtualenv ] ?
daemon="python" 

# PID
daemon_pid="$workspace/var/run/${title}.pid"

# executable script
daemon_exec="$workspace/openerp-server"

# args
daemon_args=""

# configuration file
daemon_conf="$workspace/etc/openerp-server.conf"

# data directory.
daemon_data_dir="$workspace/myportal/data"

# log level
daemon_log_level="warn"

# log directory
daemon_log_dir="$workspace/var/log"

# log file
daemon_logs="$daemon_log_dir/openerp-server.log"

# parse daemon into executable form
daemon_run="$(which $daemon) $daemon_exec $daemon_args"

# user
daemon_user=myportal

# group
daemon_group="$daemon_user"

# port
daemon_port=34601

# openerp-server configuration
export LOGNAME=$daemon_user

fnc_pid() {
    pid=

    if [ -f $daemon_pid ]; then
        pid=$(cat $daemon_pid)
    fi

    if [ -z "$pid" ]; then
        pid=$(ps auxwww | grep "$daemon" | grep "$daemon_exec" | grep -v grep | awk '{print $2}')

        # update pid file
        echo "$pid" > $daemon_pid
    fi

    # check if really running
    if [ ! -z "$pid" ]; then
        if ! ps -p $pid > /dev/null; then
            # remove the pid file
            rm -rf $daemon_pid

            # null pid value
            pid=
        fi
    fi

    echo $pid
}

fnc_start() {
    fnc_is_root $title

    pid=`fnc_pid`

    if [ "$pid" ]; then
        log_action_msg "$title" "is already running [PID: $pid]"
    else
        log_progress_msg "$title" "is starting"

        # start daemon
        start-stop-daemon --start --quiet --pidfile $daemon_pid --chuid $daemon_user:$daemon_group --background --make-pidfile --exec $daemon_run -- --config $daemon_conf --log-level=$daemon_log_level --logfile $daemon_logs --xmlrpc-port=$daemon_port --proxy-mode

        i=0

        # wait 3 seconds
        while [ $i -lt 3 ]; do
            log_progress_msg "."

            i=$(($i+1))

            sleep 1
        done

        echo

        # show status
        fnc_status
    fi
}

fnc_stop() {
    fnc_is_root $title

    pid=`fnc_pid`

    if [ -z "$pid" ]; then
        log_warning_msg "$title" "is not running"
    else
        log_progress_msg "$title" "is stopping"

        start-stop-daemon --stop --quiet --pidfile $daemon_pid --oknodo --retry 3

	    i=0

        # give a little time to stop
        while [ $i -lt 3 ]; do
            echo -n "."

            i=$(($i+1))

            sleep 1
        done

        echo

        # stopped nicely?
        pid=`fnc_pid`

        if [ -z "$pid" ]; then
            log_action_msg "$title" "is stopped"

            # remove pid
            rm -f $daemon_pid
        else
            # not stopping
            log_failure_msg "$title" "is still running"
        fi
    fi
}

fnc_kill() {
    fnc_is_root $title

    pid=`fnc_pid`

    if [ -z "$pid" ]; then
        log_warning_msg "$title" "is not running"
    else
        log_progress_msg "$title" "is stopping"

        eval "kill -9 $pid"

	    i=0

        while [ $i -lt 3 ]; do
            echo -n "."

            i=$(($i+1))

            sleep 1
        done

        echo

        # kill works?
        pid=`fnc_pid`

        if [ -z "$pid" ]; then
            log_action_msg "$title" "is killed"

            # remove pid
            rm -f $daemon_pid
        else
            # not able to kill
            log_failure_msg "$title" "is still running"
        fi
    fi
}

fnc_status() {
    pid=`fnc_pid`

    if [ -z "$pid" ]; then
        log_warning_msg "$title" "not running"
    else
        log_action_msg "$title" "running [PID: $pid]"
    fi
}

case "$1" in
    start)
        fnc_start
    ;;

    stop)
        fnc_stop
    ;;

    restart|force-reload)
        fnc_stop
        fnc_start
    ;;

    status)
        fnc_status
    ;;

    # -------------------------------------------------------------------------
    # hidden functions
    # -------------------------------------------------------------------------
    kill)
        fnc_kill
    ;;

    install)
        fnc_is_root $title

        if ! getent passwd | grep -q "^$daemon_user:"; then
            adduser --system --no-create-home --quiet --group $daemon_user
        fi

        # Register "$daemon_user" as a postgres superuser
        su - postgres -c "createuser -s $daemon_user" 2> /dev/null || true

        # Configuration file
        chown $daemon_user:$daemon_group $daemon_conf
        chmod 0640 $daemon_conf

        # Log
        mkdir -p $daemon_log_dir
        chown $daemon_user:daemon_group $daemon_log_dir
        chmod 0750 $daemon_log_dir

        # Data dir
        mkdir -p $daemon_data_dir
        chown $daemon_user:$daemon_group $daemon_data_dir

        # update-python-modules
        update-python-modules
    ;;

    uninstall)
        fnc_is_root $title

        deluser --quiet --system $daemon_user || true
        delgroup --quiet --system --only-if-empty $daemon_group || true

        if [ -d "$workspace" ]; then
            # don't do this :)
            echo "to delete all files: rm -rf $workspace"
        fi

    ;;

    *)
        echo "Usage: $title {start|stop|restart|force-reload|status}" >&2
        exit 1
    ;;
esac

exit 0