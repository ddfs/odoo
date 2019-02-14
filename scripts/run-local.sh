#!/usr/bin/env bash
#  -----------------------------------------------------------------------------
#  teknober.com - all rights reserved
#  -----------------------------------------------------------------------------
#  @author       : Fatih Piristine
#  -----------------------------------------------------------------------------

fnc_local_args="-u mymodule"

fnc_local_args=""

workspace=`pwd`

python_exec="/usr/bin/python2" # python2|python3
python_pip="pip" # pip|pip2|pip3
python_venv="${workspace}/venv"

odoo_exec="${workspace}/openerp-server"
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
    # force: -i base -u base -u all
    eval "${odoo_exec} --config=${odoo_conf} --no-xmlrpc --stop-after-init --without-demo=all -u base -u all"
}

fnc_reset_view() {
    if [[ -z "${1}" || -z ${2} || -z ${3} ]]; then
        echo "required: user password view-id"
        exit 1
    fi

    login=${1}; shift;
    password=${1}; shift;
    templates=${@}

    headers="-H 'Content-Type: application/x-www-form-urlencoded' -H 'Cookie: local-dev=1; session_id=add15ae1c084759fdabaf986b4562c206403bed4'"

    echo "------> login"
    eval "curl --data \"login=${login}&password=${password}\" http://127.0.0.1:8090/web/login ${headers} > /dev/null"

    for t in ${templates}; do
        echo ""
        echo "------> ${t}"
        eval "curl -d \"templates=${t}\" -X POST http://127.0.0.1:8090/website/reset_templates ${headers} > /dev/null"
    done;
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

    reset-view)
        shift; fnc_reset_view ${@}
    ;;

    *)
        echo "Usage: {clean|env|install|local|upgrade|reset-view}" >&2
        exit 1
    ;;
esac

exit 0
