*** Settings ***
Documentation       Application Microsoft HyperV 2022

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=apps::microsoft::hyperv::2012::local::plugin
...         --mode=node-integration-service
...         --command=cat
...         --command-path=/usr/bin
...         --no-ps


*** Test Cases ***
HyperV 2022-1 ${tc}
    [Documentation]    Apps Microsoft HyperV 2022
    [Tags]    applications    microsoft    hyperv    virtualization
    ${command}    Catenate
    ...    ${CMD}
    ...    --command-options=${CURDIR}/nodeintegrationservice-2022-1.json
    ...    --filter-vm='${filter_vm}'

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    filter_vm       expected_result    --
            ...      1     ${EMPTY}        CRITICAL: 1 problem(s) detected
            ...      2     VSERVER05       OK: VM 'VSERVER05' 0 problem(s) detected - VM 'VSERVER05' 0 problem(s) detected
            ...      3     VSERVER07       CRITICAL: VM 'VSERVER07' 1 problem(s) detected
HyperV 2022-2 ${tc}
    [Documentation]    Apps Microsoft HyperV 2022
    [Tags]    applications    microsoft    hyperv    virtualization
    ${command}    Catenate
    ...    ${CMD}
    ...    --command-options=${CURDIR}/nodeintegrationservice-2022-2.json
    ...    --filter-vm='${filter_vm}'

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    filter_vm       expected_result    --
            ...      1     ${EMPTY}        OK: All integration services are ok
            ...      2     VSERVER05       OK: VM 'VSERVER05' 0 problem(s) detected - VM 'VSERVER05' 0 problem(s) detected
            ...      3     VSERVER07       OK: VM 'VSERVER07' 0 problem(s) detected - VM 'VSERVER07' 0 problem(s) detected

