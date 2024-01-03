#!/usr/bin/env bash

HIST=$(dirname "$0")/../hist

fail=false
success_count=0
failure_count=0

begin_tests() {
    reset_counts
    reset_workspace
}

reset_counts() {
    fail=false
    success_count=0
    failure_count=0
}

reset_workspace() {
    WORKSPACE=$(mktemp -d)
}

new_sandbox() {
    mktemp -d
}

sandbox_sql() {
    if [[ -z $sandbox ]]; then
        "\$sandbox required. Aborting"
        exit 1
    fi

    echo "$@" | sqlite3 "$sandbox"/.historian.db
}

sandbox_hist() {
    if [ -z "$sandbox" ]; then
        "\$sandbox required. Aborting"
        exit 1
    fi
    HOME=$sandbox HISTORIAN_WITH_TIMESTAMPS=0 \
        $HIST "$@" >/dev/null 2>&1
    return $?
}

sandbox_hist_with_output() {
    if [ -z "$sandbox" ]; then
        "\$sandbox required. Aborting"
        exit 1
    fi
    HOME=$sandbox HISTORIAN_WITH_TIMESTAMPS=0 \
        $HIST "$@"
    return $?
}

add_success() {
    let success_count=success_count+1
}

add_failure() {
    let failure_count=failure_count+1
    local msg="$1"
    if [ -n "${CURRENT_TEST_FN}" ]; then
        echo "${CURRENT_TEST_FN} : Failed: ${msg}"
    else
        echo "Failed: ${msg}"
    fi
}

destroy_sandbox() {
    local sandbox=$1
    if [[ -n $sandbox ]] && grep -q /tmp <<< "$sandbox"; then
        rm -rf "$sandbox"
    else
        echo "Warning: not destroying sandbox: ${sandbox}" >&2
    fi
}

assert_equal() {
    local expected="$1"
    local actual="$2"
    local msg="$3"

    if [ "$expected" != "$actual" ]; then
        add_failure "expected ${expected}, but got ${actual}: ${msg}"
    else
        add_success
    fi
}

finish_tests() {
    let total_count=${failure_count}+${success_count}

    echo "${success_count} / ${total_count} assertions passed"

    if [ ${failure_count} -gt 0 ]; then
        exit 1
    fi
}

awk() {
    if [ -e /opt/local/bin/gawk ]; then
      /opt/local/bin/gawk "$@"
    elif [ -e /usr/local/bin/gawk ]; then
      /usr/local/bin/gawk "$@"
    else
      /usr/bin/env awk "$@"
    fi
}
export awk
