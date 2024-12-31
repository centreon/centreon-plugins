*** Settings ***
Documentation       Check Iplabel scenarios

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}monitoring-iplabel-ekara.json
${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::monitoring::iplabel::ekara::restapi::plugin
...                 --hostname=localhost
...                 --api-username='username'
...                 --api-password='password'
...                 --port='3000'
...                 --proto='http'

*** Test Cases ***
scenario ${tc}
    [Documentation]    Check Iplabel scenarios
    [Tags]    monitoring   iplabel    restapi

    ${command}    Catenate
    ...    ${cmd}
    ...    --mode=scenarios
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options            expected_result    --
        ...      1     --filter-name='Centreon Demo Navigation|Centreon Demo ping NA' --output-ignore-perfdata    CRITICAL: Scenario 'Centreon Demo Navigation': status: Failure (2) WARNING: Scenario 'Centreon Demo ping NA': status: Degraded (8)
        ...      2     --filter-name='AKILA - Business App'                                                       OK: Scenario 'AKILA - Business App': status: Success (1), availability: 100%, time total all steps: 4280ms - All steps are ok | 'AKILA - Business App#scenario.availability.percentage'=100%;;;0;100 'AKILA - Business App#scenario.time.allsteps.total.milliseconds'=4280ms;;;0; 'AKILA - Business App~Dashboard 2#scenario.step.time.milliseconds'=898ms;;;0; 'AKILA - Business App~Dashboard 3#scenario.step.time.milliseconds'=848ms;;;0; 'AKILA - Business App~Run Chrome#scenario.step.time.milliseconds'=2534ms;;;0;
        ...      3     --filter-name='wrong currentstatus.*'                                                      WARNING: Scenario 'wrong currentstatus, no perfdata': status: Unknown (14) - Scenario 'wrong currentstatus, no perfdata' Don't have any performance data, please try to add a bigger timeframe
        ...      4     --filter-name='not a scenario name'                                                        UNKNOWN: No scenario found
        ...      5     --filter-id='09fe2561.*' --warning-time-total-allsteps='30' --output-ignore-perfdata       WARNING: Scenario 'AKILA - (Web) ': time total all steps: 5822ms
        ...      6     --filter-status='2' --output-ignore-perfdata                                               CRITICAL: Scenario 'Centreon Demo Navigation': status: Failure (2)
        ...      7     --api-password='Wrongpassword' --api-username='wrongUsername'                              UNKNOWN: Authentication endpoint returns error code 'Wrong email or password' (add --debug option for detailed message)