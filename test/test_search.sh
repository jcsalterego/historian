#!/usr/bin/env bash

htest_search_length() {
    local length=1024
    echo \
        | awk '{while (z++ < '$length') {printf "A"}}' \
        > $sandbox/.bash_history
    sandbox_hist import
    actual=$(sandbox_hist_with_output search A \
        | grep A \
        | awk '{print $NF}' \
          );
    actual_length=$(echo $actual | awk '{print length($0);}')
    assert_equal ${actual_length} $length "actual length"
}
