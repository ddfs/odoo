#!/bin/bash

fnc_local_args="" # -u module1,module2

workspace=`pwd`
py_exec="/usr/bin/python3" # "/usr/bin/python2"
py_venv="$workspace/venv"

fnc_clean() {
    eval "find $workspace -name ""*.pyc"" -delete"
    eval "find $workspace -name ""__pycache__"" -delete"
}

fnc_env() {
    # create environment if missing
    if [ -z $pyvenv ]; then
        eval "virtualenv -p $py_exec $py_venv"
    fi

    # activate environment
    eval "source $py_venv/bin/activate"

    # ensure requirements
    eval "pip install --no-cache-dir -r $workspace/etc/requirements.txt"
}

fnc_install() {
    eval "$workspace/odoo-server --config=$workspace/etc/odoo-server.conf --xmlrpc-port=8090 --log-level=info --stop-after-init --without-demo=all -i base -i web"
}

fnc_local() {
    eval "$workspace/odoo-server --config=$workspace/etc/odoo-server.conf --xmlrpc-port=8090 --log-level=info --without-demo=all $fnc_local_args"
}

fnc_upgrade() {
    eval "$workspace/odoo-server --config=$workspace/etc/odoo-server.conf --xmlrpc-port=8090 --log-level=info --stop-after-init -u base"
}

case "$1" in
    clean)
        fnc_clean
    ;;

    env)
        fnc_clean
        fnc_env
    ;;

    install)
        fnc_clean
        fnc_install
    ;;

    local)
        fnc_clean
        fnc_local
    ;;

    upgrade)
        fnc_clean
        fnc_upgrade
    ;;

    *)
        echo "Usage: {clean|env|install|local|upgrade}" >&2
        exit 1
    ;;
esac

exit 0
