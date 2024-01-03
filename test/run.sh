#!/usr/bin/env bash

# shellcheck source=_init.sh
source "$(dirname "$0")/_init.sh"

begin_tests

run_tests() {
    local -r test_dir=$1
    local -r test_fn_prefix=$2

    for file in ${test_dir}/test_*.sh; do
        if [ "$(basename "$file")" == "$(basename "$0")" ]; then
            # don't run myself
            continue
        fi

        echo "$(basename "$file"):"

        before_test_fns=$(declare -F | awk '{print $NF}' | grep -E "^${test_fn_prefix}_")
        source "$file"
        after_test_fns=$(declare -F | awk '{print $NF}' | grep -E "^${test_fn_prefix}_")

        test_fns=$(comm -1 <(echo "${before_test_fns}") <(echo "${after_test_fns}"))
        max_test_fn_size=0
        for test_fn in $test_fns; do
            len=${#test_fn}
            if [[ $len -gt $max_test_fn_size ]]; then
                max_test_fn_size=$len
            fi
        done
        for test_fn in $test_fns; do
            echo -n "  ${test_fn} ... "
            sandbox=$(new_sandbox)
            last_failure_count=${failure_count}
            CURRENT_TEST_FN=$test_fn
            eval "$test_fn"
            let new_failure_count=${failure_count}-${last_failure_count}
            if [ ${new_failure_count} -gt 0 ]; then
                echo "FAIL"
            else
                echo "PASS"
            fi
            destroy_sandbox "$sandbox"
        done
    done
}

run_tests "$(dirname "$0")" htest

finish_tests
