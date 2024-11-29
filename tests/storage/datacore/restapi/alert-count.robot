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