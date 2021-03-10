#!/usr/bin/env bash

htest_import_simple() {
    cat >> $sandbox/.bash_history <<EOF
foo
bar
baz
EOF

    sandbox_hist import

    row_count=$(sandbox_sql 'SELECT COUNT(*) FROM history;')
    assert_equal 3 "${row_count}" "rows imported by simple bash_history"
}

htest_import_will_dedupe() {
    cat >> $sandbox/.bash_history <<EOF
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
    cat >> $sandbox/.bash_history <<EOF
echo \`ls\`
ls ./\$(hi)
foo \\\\bar\\\\baz
foo ; bar ; baz
EOF

    sandbox_hist import

    row_count=$(sandbox_sql 'SELECT COUNT(*) FROM history;')
    assert_equal 4 "${row_count}" "rows imported by simple bash_history"

    sandbox_sql 'SELECT command FROM HISTORY ORDER BY id ASC;' \
        > $sandbox/exported_commands.txt
    diff $sandbox/.bash_history $sandbox/exported_commands.txt
    assert_equal 0 $? "exported commands should match"
}

htest_import_run_twice_will_do_nothing_the_second_time() {
    cat >> $sandbox/.bash_history <<EOF
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
    cat >> $sandbox/.bash_history <<EOF
foo
"bar
baz"
"""""""
qu" x "lol "
EOF

    sandbox_hist import

    local tmp=$(mktemp)
    sandbox_sql 'SELECT command FROM history ORDER BY id ASC;' > $tmp
    diff $tmp $sandbox/.bash_history
    assert_equal 0 $?
    rm -f $tmp
}

htest_import_zsh_extended_history_parses_correctly() {
    cat >> $sandbox/.bash_history <<EOF
: 1492369835:0;hist import
: 1492369844:0;hist /hist import
: 1492369861:4;hist shell
: 1492369868:0;hist version
: 1492369908:0;hist /hist | wc -l
: 1492370096:30;history
: 1492370103:0;man history
: 1492370245:0;history-stat
: 1492370604:50;vi $HISTFILE
: 1492370674:0;tail $HISTFILEfoo
EOF

    cat >> $sandbox/expected_commands.psv <<EOF
1492369835|hist import
1492369844|hist /hist import
1492369861|hist shell
1492369868|hist version
1492369908|hist /hist | wc -l
1492370096|history
1492370103|man history
1492370245|history-stat
1492370604|vi $HISTFILE
1492370674|tail $HISTFILEfoo
EOF

    ZSH_EXTENDED_HISTORY=1 \
        sandbox_hist import

    sandbox_sql "SELECT timestamp, command FROM history;" \
        > $sandbox/actual_commands.psv;
    diff $sandbox/expected_commands.psv $sandbox/actual_commands.psv;
    assert_equal 0 $? "rows imported with ZSH_EXTENDED_HISTORY set should match"
}
