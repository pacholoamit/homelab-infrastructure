#!/usr/bin/env bash
# ACTIONS_RUNNER_HOOK_JOB_STARTED: runs before each job's first step.
#
# Every job starts without Playwright browsers, as on a fresh hosted VM.
# help-center's browser tests run only when Chromium is installed, and on
# hosted runners it never is during `validate`; an earlier e2e job on this
# persistent runner must not change that. The e2e jobs install Chromium
# themselves.
rm -rf "${HOME:-/home/runner}/.cache/ms-playwright"
