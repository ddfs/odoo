#!/bin/bash
### BEGIN INIT INFO
# Provides:          myportal.fi
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start odoo daemon at boot time
# Description:       Enable service provided by daemon.
# X-Interactive:     true
### END INIT INFO

# init functions
. /lib/lsb/init-functions

# title
title="hexon.fi"

# workspace directory
workspace="/srv/$title/live"

# daemon env
daemon_env_dir="/srv/$title/venv"
daemon_env_run="$daemon_env_dir/bin/activate"

# daemon
daemon_bin="python3"
daemon="$daemon_env_dir/bin/$daemon_bin"

# PID
daemon_pid="$workspace/var/run/${title}.pid"

# executable script
daemon_exec="$workspace/odoo-server"

# args
daemon_args=""

# configuration file
daemon_conf="$workspace/etc/odoo-server.conf"

# data directory.
daemon_data_dir="$workspace/data"

# log level
daemon_log_level="warn"

# log directory
daemon_log_dir="$workspace/var/log"

# log file
daemon_logs="$daemon_log_dir/odoo-server.log"

# parse daemon into executable form
daemon_run="$daemon $daemon_exec $daemon_args"

# user
daemon_user=www-data

# group
daemon_group="$daemon_user"

# port
daemon_port=34600

# odoo-server configuration
export LOGNAME=$daemon_user

fnc_daemon_env() {
    log_action_msg "$title" "preparing environment"

    # create environment if missing
    if [ -z $daemon_env ]; then
        eval "virtualenv -p /usr/bin/$daemon_bin $daemon_env_dir"
    fi

    # activate environment
    eval "source $daemon_env_run"

    # ensure requirements
    eval "pip install --no-cache-dir -r $workspace/etc/requirements.txt"

    log_action_msg "$title" "environment ready."
}

fnc_daemon_env_reset() {
    log_action_msg "$title" "resetting environment"

    # check it exists
    if [ -d $daemon_env ]; then
        eval "rm -rf $daemon_env_dir"
    fi

    # re-load
    fnc_daemon_env
}

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
        fnc_daemon_env

        log_progress_msg "$title" "is starting"

        # start daemon
        start-stop-daemon --start --quiet --pidfile $daemon_pid --chuid $daemon_user:$daemon_group --background --make-pidfile --exec $daemon_run -- --config $daemon_conf --log-level=$daemon_log_level --logfile $daemon_logs --xmlrpc-port=$daemon_port --proxy-mode --no-database-list --without-demo=all

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
    env)
        fnc_daemon_env
    ;;

    env_reset)
        fnc_daemon_env_reset
    ;;

    kill)
        fnc_kill
    ;;

    *)
        echo "Usage: $title {start|stop|restart|force-reload|status}" >&2
        exit 1
    ;;
esac

exit 0

