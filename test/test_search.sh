#!/bin/bash
typeset sandbox

htest_search_length() {
    local -i length=1024
    printf '%0.sA' $(seq $length) > "$sandbox"/.bash_history
    echo >> "$sandbox"/.bash_history
    sandbox_hist import
    actual=$(
        sandbox_hist_with_output search A |
        grep A |
        awk '{print $NF}'
    )
    actual_length=${#actual}
    assert_equal "${actual_length}" $length "actual length"
}
