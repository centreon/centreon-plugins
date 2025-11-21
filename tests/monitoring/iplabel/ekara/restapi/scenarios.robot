*** Settings ***
Documentation       Check Iplabel scenarios

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}monitoring-iplabel-ekara.json
${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::monitoring::iplabel::ekara::restapi::plugin
...                 --hostname=localhost
...                 --port='3000'
...                 --proto='http'


*** Test Cases ***
scenario-username ${tc}
    [Documentation]    Check Iplabel scenarios
    [Tags]    monitoring    iplabel    restapi

    ${command}    Catenate
    ...    ${cmd}
    ...    --mode=scenarios
    ...    --api-username='username'
    ...    --api-password='password'
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options            expected_result    --
        ...      1     --filter-name='Centreon Demo Navigation|Centreon Demo ping NA' --output-ignore-perfdata    CRITICAL: Scenario 'Centreon Demo Navigation': status: Failure (2) WARNING: Scenario 'Centreon Demo ping NA': status: Degraded (8)
        ...      2     --filter-name='AKILA - Business App'                                                       OK: Scenario 'AKILA - Business App': status: Success (1), availability: 100%, time total all steps: 4280ms - All steps are ok | 'AKILA - Business App#scenario.availability.percentage'=100%;;;0;100 'AKILA - Business App#scenario.time.allsteps.total.milliseconds'=4280ms;;;0; 'AKILA - Business App~Run Chrome#scenario.step.time.milliseconds'=2534ms;;;0; 'AKILA - Business App~Dashboard 2#scenario.step.time.milliseconds'=898ms;;;0; 'AKILA - Business App~Dashboard 3#scenario.step.time.milliseconds'=848ms;;;0;
        ...      3     --filter-name='wrong currentstatus.*'                                                      UNKNOWN: Scenario 'wrong currentstatus, no perfdata': status: Unknown (14) - No execution, please try again with a bigger timeframe
        ...      4     --filter-name='not a scenario name'                                                        UNKNOWN: No scenario found
        ...      5     --filter-id='127a149b.*' --warning-time-total='30' --output-ignore-perfdata                WARNING: Scenario 'AKILA - (Browser Page Load)': Step: Default, last exec: 30-12-2024 10:30:00 UTC, time total: 1097 ms
        ...      6     --filter-status='2' --output-ignore-perfdata                                               CRITICAL: Scenario 'Centreon Demo Navigation': status: Failure (2)
        ...      7     --filter-status='2' --filter-siteid='site' --filter-workspaceid='workspace' --output-ignore-perfdata    CRITICAL: Scenario 'Centreon Demo Navigation': status: Failure (2)
        ...      8     --filter-type='not a scenario type'                                                        UNKNOWN: No scenario found
        ...      9     --api-password='Wrongpassword' --api-username='wrongUsername'                              UNKNOWN: Authentication endpoint returns error code 'Wrong email or password' (add --debug option for detailed message)
        # This scenario failed the second step. we show only the first step perfdata, and not the perfdata of the other step for another timestamp.
        ...      10    --filter-name='AKILA - .Web.'                                                              CRITICAL: Scenario 'AKILA - (Web)': status: Failure (2) | 'AKILA - (Web)#scenario.availability.percentage'=45.76%;;;0;100 'AKILA - (Web)#scenario.time.allsteps.total.milliseconds'=4733ms;;;0; 'AKILA - (Web)~Home#scenario.step.time.milliseconds'=2851ms;;;0;
        # without any filter-name of filter-id, every scenario are taken into account of this type.
        ...      11    --filter-type='WEB' --output-ignore-perfdata                                               CRITICAL: Scenario 'AKILA - (Web)': status: Failure (2) - Scenario 'Centreon Demo Navigation': status: Failure (2)
        # Check the unknown default parameter. These scenario are not real and go to the same scenarioId, which is not possible in real life.
        ...      12    --filter-name='unknown Status 0' --output-ignore-perfdata                                  UNKNOWN: Scenario 'unknown Status 0': status: Unknown (0)
        ...      13    --filter-name='unknown Status 3' --output-ignore-perfdata                                  UNKNOWN: Scenario 'unknown Status 3': status: Aborted (3)
        ...      14    --filter-name='unknown Status 4' --output-ignore-perfdata                                  UNKNOWN: Scenario 'unknown Status 4': status: No execution (4)
        ...      15    --filter-name='unknown Status 5' --output-ignore-perfdata                                  UNKNOWN: Scenario 'unknown Status 5': status: No execution (5)
        ...      16    --filter-name='unknown Status 6' --output-ignore-perfdata                                  UNKNOWN: Scenario 'unknown Status 6': status: Stopped (6)
        ...      17    --filter-name='AKILA - .Web.' --curl-opt='CURLOPT_HTTPHEADER => [test: 2]' --curl-opt='CURLOPT_HTTPHEADER => [ Authorization: Bearer VeryLongTokenToAuthenticate]'             CRITICAL: Scenario 'AKILA - (Web)': status: Failure (2) | 'AKILA - (Web)#scenario.availability.percentage'=64.48%;;;0;100 'AKILA - (Web)#scenario.time.allsteps.total.milliseconds'=4031ms;;;0; 'AKILA - (Web)~Home#scenario.step.time.milliseconds'=3862ms;;;0; 'AKILA - (Web)~Dashboard v2#scenario.step.time.milliseconds'=215ms;;;0; 'AKILA - (Web)~Dashboard v3#scenario.step.time.milliseconds'=68ms;;;0;

scenario-apikey ${tc}
    [Documentation]    Check Iplabel scenarios
    [Tags]    monitoring    iplabel    restapi

    ${command}    Catenate
    ...    ${cmd}
    ...    --mode=scenarios
    ...    --api-key='PaSsWoRdZ'
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options                                                             expected_result    --
        ...      1     --filter-name='X-AKILA - Business App'                                    OK: Scenario 'X-AKILA - Business App': status: Success (1), availability: 100%, time total all steps: 4280ms - All steps are ok | 'X-AKILA - Business App#scenario.availability.percentage'=100%;;;0;100 'X-AKILA - Business App#scenario.time.allsteps.total.milliseconds'=4280ms;;;0; 'X-AKILA - Business App~Run Chrome#scenario.step.time.milliseconds'=2534ms;;;0; 'X-AKILA - Business App~Dashboard 2#scenario.step.time.milliseconds'=898ms;;;0; 'X-AKILA - Business App~Dashboard 3#scenario.step.time.milliseconds'=848ms;;;0;
        ...      9     --api-key='wrongkey'                                                      UNKNOWN: API key is not valid.

scenario ${tc}
    [Documentation]    Check Iplabel scenarios
    [Tags]    monitoring    iplabel    restapi

    ${command}    Catenate
    ...    ${cmd}
    ...    --mode=scenarios
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options                                                             expected_result    --
        ...      1     ${EMPTY}                                                                  UNKNOWN: Need to specify --api-key or --api-username/--api-password options.
        ...      2     --api-username=username --api-password=password --api-key=PaSsWoRdZ       UNKNOWN: Cannot use both --api-key and --api-username/--api-password options.
