#!/bin/bash
typeset sandbox

htest_import_simple() {
    cat >> "$sandbox"/.bash_history <<EOF
foo
bar
baz
EOF

    sandbox_hist import

    row_count=$(sandbox_sql 'SELECT COUNT(*) FROM history;')
    assert_equal 3 "${row_count}" "rows imported by simple bash_history"
}

htest_import_will_dedupe() {
    cat >> "$sandbox"/.bash_history <<EOF
foo
bar
baz
baz
bar
EOF

    sandbox_hist import

    row_count=$(sandbox_sql 'SELECT COUNT(*) FROM history;')
    assert_equal 3 "${row_count}" "rows imported by simple bash_history"
}

htest_import_handles_funny_characters() {
    cat >> "$sandbox"/.bash_history <<EOF
echo \`ls\`
ls ./\$(hi)
foo \\\\bar\\\\baz
foo ; bar ; baz
EOF

    sandbox_hist import

    row_count=$(sandbox_sql 'SELECT COUNT(*) FROM history;')
    assert_equal 4 "${row_count}" "rows imported by simple bash_history"

    sandbox_sql 'SELECT command FROM HISTORY ORDER BY id ASC;' \
        > "$sandbox"/exported_commands.txt
    diff "$sandbox"/.bash_history "$sandbox"/exported_commands.txt
    assert_equal 0 $? "exported commands should match"
}

htest_import_run_twice_will_do_nothing_the_second_time() {
    cat >> "$sandbox"/.bash_history <<EOF
foo
bar
baz
EOF

    sandbox_hist import

    row_count=$(sandbox_sql 'SELECT COUNT(*) FROM history;')
    assert_equal 3 "${row_count}" "rows imported by simple bash_history"

    sandbox_hist import

    row_count=$(sandbox_sql 'SELECT COUNT(*) FROM history;')
    assert_equal 3 "${row_count}" "rows imported by simple bash_history should not change"
}

htest_import_imbalanced_quotes() {
    cat >> "$sandbox"/.bash_history <<EOF
foo
"bar
baz"
"""""""
qu" x "lol "
EOF

    sandbox_hist import

    local -r tmp=$(mktemp)
    sandbox_sql 'SELECT command FROM history ORDER BY id ASC;' > "$tmp"
    diff "$tmp" "$sandbox"/.bash_history
    assert_equal 0 $?
    rm -f "$tmp"
}

htest_import_zsh_extended_history_parses_correctly() {
    cp "$PWD"/sample.zsh_history "$sandbox"/.bash_history
    cp "$PWD"/sample.zsh_history.expected_output "$sandbox"/expected_commands.psv

    ZSH_EXTENDED_HISTORY=1 \
        sandbox_hist import

    sandbox_sql > "$sandbox"/actual_commands.psv "
    SELECT command_timestamp, command
    FROM history
    ORDER by command_timestamp;
    "

    diff "$sandbox"/expected_commands.psv "$sandbox"/actual_commands.psv
    assert_equal 0 $? "rows imported with ZSH_EXTENDED_HISTORY set should match"
}
