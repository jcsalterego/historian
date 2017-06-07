#!/usr/bin/env bash
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
    cp "$PWD"/sample.zsh_history "$sandbox"/.zsh_history
    expected_output=$PWD/sample.zsh_history.expected_output

    sandbox_hist_with_output import

    sandbox_sql > "$sandbox"/actual_output.psv "
    SELECT command_timestamp, command
    FROM history
    ORDER by command_timestamp;
    "

    diff "$expected_output" "$sandbox"/actual_output.psv
    assert_equal 0 $? "rows imported with from zsh_history set should match"
}

htest_import_historianrc_variables_get_imported() {
    cp "$PWD"/sample.historianrc "$sandbox"/.historianrc
    seq 15 > "$sandbox"/.bash_history
    sandbox_hist import
    cat > "$sandbox"/expected_output.psv <<EOF
1|commands_imported|15
1|fake_hostname|the-moon
1|interpreted_var|1 2 3 4 5 6 7 8 9 10
EOF
    sandbox_sql > "$sandbox"/actual_output.psv "
    SELECT metadata_id, key, value
    FROM metadata
    WHERE key <> 'imported_at'
    ORDER by metadata_id, key;
    "
    diff "$sandbox"/expected_output.psv "$sandbox"/actual_output.psv
    assert_equal 0 $? "variables from .historianrc set should match"
}

htest_import_fails_with_no_history_files() {
    sandbox_hist import
    assert_equal 2 $? "hist import should fail if no history input is found"
}
