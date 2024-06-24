*** Settings ***
Documentation       Application Microsoft HyperV 2022

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=apps::microsoft::hyperv::2012::local::plugin
...         --mode=node-integration-service
...         --command=cat
...         --command-path=/usr/bin
...         --no-ps
...         --command-options=nodeintegrationservice-2022.json

*** Test Cases ***
HyperV 2022 ${tc}/3
    [Documentation]    Apps Microsoft HyperV 2022
    [Tags]    applications    microsoft    hyperv    virtualization
    ${command}    Catenate
    ...    ${CMD}
    ...    --filter-vm='${filter_vm}'

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    \nWrong output result for command:\n${command}\n\nExpected:\n${expected_result}\nCommand output:\n${output}\n\n

    Examples:        tc    filter_vm       expected_result    --
            ...      1     ${EMPTY}        CRITICAL: 1 problem(s) detected
            ...      2     VSERVER05       OK: VM 'VSERVER05' 0 problem(s) detected - VM 'VSERVER05' 0 problem(s) detected
            ...      3     VSERVER07       CRITICAL: VM 'VSERVER07' 1 problem(s) detected

