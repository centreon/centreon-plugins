*** Settings ***
Documentation       Check the backup status

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}keysight_debug.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=network::keysight::nvos::restapi::plugin
...                 --custommode=api
...                 --hostname=${HOSTNAME}
...                 --api-username=username
...                 --api-password=password
...                 --port=${APIPORT}


*** Test Cases ***
ports ${tc}
    [Documentation]    Check the backups status
    [Tags]    network    backbox    restapi    backup
    ${command}    Catenate
    ...    ${cmd}
    ...    --mode=ports
    ...    ${extraoptions}
    Log    ${cmd}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc    extraoptions                                                                                    expected_result    --
            ...       1     --verbose                                                                                       OK:
            ...       2     --filter-name                                                                                   WARNING:
            ...       3     --unknown-license-status=\\\%{status}                                                           CRITICAL:
            ...       4     --warning-license-status='\\\%{status} =~ /invalid_software_version/'                           WARNING: 
            ...       5     --critical-license-status=\\\%{name}                                                            CRITICAL: 
            ...       6     --unknown-link-status=\\\%{adminStatus}                                                         WARNING:
            ...       7     --warning-link-status=\\\%{name}                                                                CRITICAL:
            ...       8     --critical-link-status='\\\%{adminStatus} eq "enabled" and \\\%{operationalStatus} ne "up"'     OK:
            ...       9     --warning-traffic-out-prct --critical-traffic-out-prct                                          OK:
            ...       10    --warning-packets-out --critical-packets-out                                                    OK:
            ...       11    --warning-traffic-out --critical-traffic-out                                                    OK:
            ...       12    --warning-packets-dropped --critical-packets-dropped                                            OK:
            ...       13    --warning-packets-pass --critical-packets-pass                                                  OK:
            ...       14    --warning-packets-insp --critical-packets-insp                                                  OK:
