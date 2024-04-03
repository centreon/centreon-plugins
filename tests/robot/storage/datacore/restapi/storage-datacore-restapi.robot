*** Settings ***
Documentation       datacore rest api plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}storage-datacore-api.json

${CMD}              ${CENTREON_PLUGINS} --plugin=storage::datacore::restapi::plugin --password=pass --username=user --port=3000 --hostname=127.0.0.1 --proto=http


*** Test Cases ***
Datacore check pool usage
    [Documentation]    Check Datacore pool usage
    [Tags]    storage    api
    ${output}    Run
    ...    ${CMD} --mode=pool-usage --critical-oversubscribed=${critical-oversubscribed} --warning-oversubscribed=${warning-oversubscribed} --warning-bytesallocatedpercentage=${warning-bytesallocatedpercentage} --critical-bytesallocatedpercentage=${critical-bytesallocatedpercentage} --pool-id=B5C140F5-6B13-4CAD-AF9D-F7C4172B3A1D:{4dec1b5a-2577-11e5-80c3-00155d651622}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${result}
    ...    Wrong output result for pool usage :\n\n ${output} \n\n ${result}\n\n

    Examples:    warning-bytesallocatedpercentage      critical-bytesallocatedpercentage    warning-oversubscribed      critical-oversubscribed    result   --
        ...      2    5    -1    3    CRITICAL: Bytes Allocated : 12 % WARNING: Over subscribed bytes : 0 | 'datacore.pool.bytesallocated.percentage'=12%;0:2;0:5;0;100 'datacore.pool.oversubscribed.bytes'=0bytes;0:-1;0:3;0;
        ...      70    80    10    20    OK: Bytes Allocated : 12 % - Over subscribed bytes : 0 | 'datacore.pool.bytesallocated.percentage'=12%;0:70;0:80;0;100 'datacore.pool.oversubscribed.bytes'=0bytes;0:10;0:20;0;

Datacore check alert count
    [Documentation]    Check Datacore pool usage
    [Tags]    storage    api
    ${output}    Run
    ...    ${CMD} --mode=alerts --warning-error=${warning-error} --critical-error=${critical-error} --warning-warning=${warning-warning} --critical-warning=${critical-warning}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${result}
    ...    Wrong output result for alert count :\n\n ${output} \n\n ${result}\n\n

    Examples:    warning-error    critical-error    warning-warning    critical-warning    result   --
        ...      0    1    5    5    WARNING: number of error alerts : 1 | 'datacore.event.error.count'=1;0:0;0:1;0; 'datacore.alerts.warning.count'=1;0:5;0:5;0; 'datacore.alerts.info.count'=0;;;0; 'datacore.alerts.trace.count'=0;;;0;
        ...      5    5    5    5    OK: number of error alerts : 1, number of warning alerts : 1, number of info alerts : 0, number of trace alerts : 0 | 'datacore.event.error.count'=1;0:5;0:5;0; 'datacore.alerts.warning.count'=1;0:5;0:5;0; 'datacore.alerts.info.count'=0;;;0; 'datacore.alerts.trace.count'=0;;;0;

Datacore check status monitor
    [Documentation]    Check Datacore pool usage
    [Tags]    storage    api
    ${output}    Run
    ...    ${CMD} --mode=status-monitor
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${result}
    ...    Wrong output result for status monitor :\n${output} \nresult:\n${result}\n\n

    Examples:    result   --
        ...    CRITICAL: 'State of HostVM2' status : 'Critical', message is 'Connected'
