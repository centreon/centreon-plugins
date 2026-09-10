*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=storage::ibm::flashsystem::restapi::plugin
...                 --mode=eventlog
...                 --hostname=${HOSTNAME}
...                 --proto='http'
...                 --port=${APIPORT}
...                 --api-path='/rest/v1'
...                 --api-username='user'
...                 --api-password='pass'
...                 --statefile-dir=/tmp


*** Test Cases ***
eventlog ${tc}
    [Tags]    storage    ibm    flashsystem    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc      extra_options                                                          expected_result    --
            ...       1       ${EMPTY}                                                               CRITICAL: Event '3101' status: alert, error code: 2017, event id: 064003, object: host host-29, last seen: 260902154807 [One or more configured hosts are offline] | 'eventlog.alerts.count'=1;;;0; 'eventlog.messages.count'=11;;;0;
            ...       2       --filter-error-code='^9999$'                                           OK: Unfixed event log entries: 1 alert(s), 11 message(s) | 'eventlog.alerts.count'=1;;;0; 'eventlog.messages.count'=11;;;0;
            ...       3       --critical-event-status='\\\%{status} =~ /never/' --warning-messages=0    WARNING: Unfixed event log entries: 11 message(s) | 'eventlog.alerts.count'=1;;;0; 'eventlog.messages.count'=11;0:0;;0;
            ...       4       --filter-object-type='host'                                            CRITICAL: Event '3101' status: alert, error code: 2017, event id: 064003, object: host host-29, last seen: 260902154807 [One or more configured hosts are offline] | 'eventlog.alerts.count'=1;;;0; 'eventlog.messages.count'=11;;;0;
