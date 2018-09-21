#!/usr/bin/env bash
#  -----------------------------------------------------------------------------
#  (c)
#  -----------------------------------------------------------------------------
fnc_local_args="-u my_module"

workspace=`pwd`

python_exec="/usr/bin/python3" # python2|python3
python_pip="pip" # pip|pip2|pip3
python_venv="${workspace}/venv"

odoo_exec="${workspace}/odoo-bin"
odoo_conf="${workspace}/local.conf"
odoo_requirements="${workspace}/requirements.txt"

fnc_clean() {
    eval "find ${workspace} -name ""*.pyc"" -delete"
    eval "find ${workspace} -name ""__pycache__"" -delete"
}

fnc_env_activate() {
    # activate environment
    if [[ -f "${python_venv}/bin/activate" ]]; then
        eval "source ${python_venv}/bin/activate"
    else
        echo "Create virtual environment first!"
        exit 1
    fi
}

fnc_env() {
    # create environment if missing
    if [[ ! -d ${python_venv} ]]; then
        eval "virtualenv -p ${python_exec} ${python_venv}"
    fi

    fnc_env_activate

    # ensure requirements
    eval "${python_pip} install --no-cache-dir -r ${odoo_requirements}"
}

fnc_install() {
    eval "${odoo_exec} --config=${odoo_conf} --no-xmlrpc --stop-after-init --without-demo=all -i base -i web"
}

fnc_local() {
    eval "${odoo_exec} --config=${odoo_conf} --without-demo=all ${fnc_local_args}"
}

fnc_upgrade() {
    eval "${odoo_exec} --config=${odoo_conf} --no-xmlrpc --stop-after-init --without-demo=all -u base -u all"
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
        fnc_env_activate
        fnc_install
    ;;

    local)
        fnc_clean
        fnc_env_activate
        fnc_local
    ;;

    upgrade)
        fnc_clean
        fnc_env_activate
        fnc_upgrade
    ;;

    *)
        echo "Usage: {clean|env|install|local|upgrade}" >&2
        exit 1
    ;;
esac

exit 0
