*** Settings ***
Documentation       Linux Local process openfiles

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::local::plugin


*** Test Cases ***
process-openfiles auto ${tc}
    [Tags]    os    linux    local
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=process
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:        tc    extra_options                                                                 expected_regexp    --
    ...              1     --add-open-files --warning-open-files=:1 --filter-command=robot               ^WARNING: Process: \\\\[command => robot\\\\] \\\\[arg => [\\\\w\\\\.\\\\s/-]+\\\\] \\\\[state => [RSD]\\\\] open files: \\\\d+/\\\\d+ \\\\([\\\\d\\\\.]+%\\\\) \\\\| 'processes.total.count'=\\\\d+;;;0;
    ...              2     --add-open-files --critical-open-files=:1 --filter-command=robot              ^CRITICAL: Process: \\\\[command => robot\\\\] \\\\[arg => [\\\\w\\\\.\\\\s/-]+\\\\] \\\\[state => [RSD]\\\\] open files: \\\\d+/\\\\d+ \\\\([\\\\d\\\\.]+%\\\\) \\\\| 'processes.total.count'=\\\\d+;;;0;
    ...              3     --add-open-files --critical-open-files-prct=:0 --filter-command=robot         ^CRITICAL: Process: \\\\[command => robot\\\\] \\\\[arg => [\\\\w\\\\.\\\\s/-]+\\\\] \\\\[state => [RSD]\\\\] open files: \\\\d+/\\\\d+ \\\\([\\\\d\\\\.]+%\\\\) \\\\| 'processes.total.count'=\\\\d+;;;0;
