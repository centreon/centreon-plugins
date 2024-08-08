*** Settings ***
Documentation       datacore rest api plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}storage-datacore-api.json

${CMD}              ${CENTREON_PLUGINS} --plugin=storage::datacore::restapi::plugin --password=pass --username=user --port=${APIPORT} --hostname=${HOSTNAME} --proto=http


*** Test Cases ***
Datacore check pool usage ${tc}
    [Documentation]    Check Datacore pool usage
    [Tags]    storage    api
    ${command}    Catenate
    ...    ${CMD} 
    ...    --mode=pool-usage 
    ...    --critical-oversubscribed=${critical-oversubscribed} 
    ...    --warning-oversubscribed=${warning-oversubscribed} 
    ...    --warning-bytesallocatedpercentage=${warning-bytesallocatedpercentage} 
    ...    --critical-bytesallocatedpercentage=${critical-bytesallocatedpercentage} 
    ...    --pool-id=B5C140F5-6B13-4CAD-AF9D-F7C4172B3A1D:{4dec1b5a-2577-11e5-80c3-00155d651622}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc      warning-bytesallocatedpercentage      critical-bytesallocatedpercentage    warning-oversubscribed      critical-oversubscribed    expected_result   --
        ...      1       2                                     5                                    -1                          3                          CRITICAL: Bytes Allocated : 12 % WARNING: Over subscribed bytes : 0 | 'datacore.pool.bytesallocated.percentage'=12%;0:2;0:5;0;100 'datacore.pool.oversubscribed.bytes'=0bytes;0:-1;0:3;0;
        ...      2       70                                    80                                    10                         20                         OK: Bytes Allocated : 12 % - Over subscribed bytes : 0 | 'datacore.pool.bytesallocated.percentage'=12%;0:70;0:80;0;100 'datacore.pool.oversubscribed.bytes'=0bytes;0:10;0:20;0;

Datacore check alert count ${tc}
    [Documentation]    Check Datacore pool usage
    [Tags]    storage    api
    ${command}    Catenate
    ...    ${CMD} 
    ...    --mode=alerts 
    ...    --warning-error=${warning-error} 
    ...    --critical-error=${critical-error} 
    ...    --warning-warning=${warning-warning} 
    ...    --critical-warning=${critical-warning}
    
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc      warning-error    critical-error    warning-warning    critical-warning    expected_result   --
        ...      1       0                1                 5                  5                   WARNING: number of error alerts : 1 | 'datacore.event.error.count'=1;0:0;0:1;0; 'datacore.alerts.warning.count'=1;0:5;0:5;0; 'datacore.alerts.info.count'=0;;;0; 'datacore.alerts.trace.count'=0;;;0;
        ...      2       5                5                 5                  5                   OK: number of error alerts : 1, number of warning alerts : 1, number of info alerts : 0, number of trace alerts : 0 | 'datacore.event.error.count'=1;0:5;0:5;0; 'datacore.alerts.warning.count'=1;0:5;0:5;0; 'datacore.alerts.info.count'=0;;;0; 'datacore.alerts.trace.count'=0;;;0;

Datacore check status monitor ${tc}
    [Documentation]    Check Datacore pool usage
    [Tags]    storage    api
    ${command}    Catenate
    ...    ${CMD} 
    ...    --mode=status-monitor
    ...    --statefile-dir=/dev/shm/
    
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc      expected_result   --
        ...      1       CRITICAL: 'State of HostVM2' status : 'Critical', message is 'Connected'
