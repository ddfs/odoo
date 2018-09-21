#!/usr/bin/env bash
### BEGIN INIT INFO
# Provides:          %daemon.name%
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

# daemon name
daemon_name="%daemon.name%"

# daemon working directory
daemon_workspace="%daemon.workspace%"

# daemon PID file
daemon_pid="/var/run/${daemon_name}.pid"

# daemon user
daemon_user="%daemon.user%"

# daemon group
daemon_group="%daemon.group%"

# daemon python env directory
daemon_python_env_dir="${daemon_workspace}/venv"

# python env activator
daemon_python_env_activate="${daemon_python_env_dir}/bin/activate"

# python executable
daemon_python_bin="%daemon.python.bin%"

# python pip executable
daemon_python_pip="%daemon.python.pip%"

# python requirements
daemon_python_quirements="%daemon.python.requirements%"

# odoo executable script
daemon_odoo_exec="%daemon.odoo.exec%"

# odoo configuration file
daemon_odoo_conf="%daemon.odoo.conf%"

# additional args to odoo
daemon_odoo_args="%daemon.odoo.args%"

# daemon exec path
daemon_exec="${daemon_python_env_dir}/bin/${daemon_python_bin}"

# daemon run command
daemon_run="$daemon_exec $daemon_odoo_exec"

# server configuration
export LOGNAME="$daemon_user"

fnc_daemon_env() {
    log_action_msg "${daemon_name} preparing environment"

    # test virtualenv installed correctly
    virtualenv_bin=$(which virtualenv)

    if [[ -z ${virtualenv_bin} ]] || [[ ! -x ${virtualenv_bin} ]]; then
        log_failure_msg "virtualenv is not available. exiting"
        exit -1
    fi

    # create environment if missing
    if [[ ! -d ${daemon_python_env_dir} ]]; then
        eval "${virtualenv_bin} -p /usr/bin/${daemon_python_bin} ${daemon_python_env_dir}"
    fi

    # activate environment
    eval "source ${daemon_python_env_activate}"

    # ensure requirements
    eval "${daemon_python_pip} install --no-cache-dir -r ${daemon_python_quirements}"

    log_action_msg "${daemon_name} environment ready."
}


fnc_daemon_env_reset() {
    log_action_msg "${daemon_name} resetting environment"

    # check it exists
    if [[ -d ${daemon_python_env_dir} ]]; then
        eval "rm -rf ${daemon_python_env_dir}"
    fi

    # re-load
    fnc_daemon_env
}

fnc_pid() {
    pid=

    if [[ -f ${daemon_pid} ]]; then
        pid=$(cat ${daemon_pid})
    fi

    if [[ -z ${pid}  ]]; then
        pid=$(ps auxwww | grep "${daemon_exec}" | grep "${daemon_odoo_exec}" | grep -v grep | awk '{print $2}')

        # update pid file
        echo "${pid}" > ${daemon_pid}
    fi

    # check if really running
    if [ ! -z "${pid}" ]; then
        if ! ps -p ${pid} > /dev/null; then
            # remove the pid file
            rm -rf ${daemon_pid}

            # null pid value
            pid=
        fi
    fi

    echo ${pid}
}

fnc_start() {
    pid=$(fnc_pid)

    if [[ ${pid} ]]; then
        log_action_msg "${daemon_name} is already running [PID: ${pid}]"
    else
        fnc_daemon_env

        log_progress_msg "${daemon_name} is starting"

        # start daemon
        start-stop-daemon --start --quiet --background --make-pidfile --remove-pidfile --oknodo \
                --pidfile ${daemon_pid} \
                --chdir ${daemon_workspace} \
                --chuid ${daemon_user}:${daemon_group} \
                --startas ${daemon_run} \
                -- \
                    --config ${daemon_odoo_conf} \
                    --no-database-list \
                    --without-demo=all ${daemon_odoo_args}

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
    pid=$(fnc_pid)

    if [[ -z ${pid} ]]; then
        log_warning_msg "${daemon_name} is not running"
    else
        log_progress_msg "${daemon_name} is stopping"

        start-stop-daemon --stop --quiet --pidfile ${daemon_pid} --oknodo --retry 3

        i=0

        # give a little time to stop
        while [ $i -lt 3 ]; do
            echo -n "."

            i=$(($i+1))

            sleep 1
        done

        echo

        # stopped nicely?
        pid=$(fnc_pid)

        if [[ -z ${pid} ]]; then
            log_action_msg "${daemon_name} is stopped"

            # remove pid
            rm -f ${daemon_pid}
        else
            # not stopping
            log_failure_msg "${daemon_name} is still running"
        fi
    fi
}

fnc_kill() {
    pid=$(fnc_pid)

    if [[ -z ${pid} ]]; then
        log_warning_msg "${daemon_name} is not running"
    else
        log_progress_msg "${daemon_name} is stopping"

        eval "kill -9 ${pid}"

        i=0

        while [ $i -lt 3 ]; do
            echo -n "."

            i=$(($i+1))

            sleep 1
        done

        echo

        # kill works?
        pid=$(fnc_pid)

        if [[ -z ${pid} ]]; then
            log_action_msg "${daemon_name} is killed"

            # remove pid
            rm -f ${daemon_pid}
        else
            # not able to kill
            log_failure_msg "${daemon_name} is still running"
        fi
    fi
}

fnc_status() {
    pid=$(fnc_pid)

    if [[ -z ${pid} ]]; then
        log_warning_msg "${daemon_name} not running"
    else
        log_action_msg "${daemon_name} running [PID: ${pid}]"
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
        echo "Usage: ${daemon_name} {start|stop|restart|force-reload|status}" >&2
        exit 1
    ;;
esac

exit 0

