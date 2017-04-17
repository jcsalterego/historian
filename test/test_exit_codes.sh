#!/bin/bash

htest_bare_command_returns_zero_exit_code() {
    sandbox_hist
    assert_equal 0 $? "bare command should return exit code 0"
}

htest_version_returns_zero_exit_code() {
    sandbox_hist version
    assert_equal 0 $? "version should return exit code 0"
}
