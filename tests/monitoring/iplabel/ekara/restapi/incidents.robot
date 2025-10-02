*** Settings ***
Documentation       Check Iplabel incidents

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}monitoring-iplabel-ekara.json
${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::monitoring::iplabel::ekara::restapi::plugin
...                 --hostname=localhost
...                 --port='3000'
...                 --proto='http'

*** Test Cases ***

incidents-username ${tc}
    [Documentation]    Check Iplabel scenarios
    [Tags]    monitoring   iplabel    restapi

    ${command}    Catenate
    ...    ${cmd}
    ...    --mode=incidents
    ...    --api-username='username'
    ...    --api-password='password'
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options                                               expected_result    --
        ...      1     --filter-name='Centreon Demo Navigation|AKILA - .Web.'      CRITICAL: Incident #25421291, Scenario 'Centreon Demo Navigation' severity: Critical - Incident #25421962, Scenario 'AKILA - (Web)' severity: Critical - Incident #25422458, Scenario 'Centreon Demo Navigation' severity: Critical - Incident #25423513, Scenario 'Centreon Demo Navigation' status: Open, severity: Critical | 'ekara.incidents.current.total.count'=4;;;0;
        ...      2    --filter-name='not a name'                                   UNKNOWN: No scenarios found, can't search for incidents. Please check filters.

incidents-apikey ${tc}
    [Documentation]    Check Iplabel scenarios
    [Tags]    monitoring   iplabel    restapi

    ${command}    Catenate
    ...    ${cmd}
    ...    --mode=incidents
    ...    --api-key='PaSsWoRdZ'
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options                                               expected_result    --
        ...      1     --filter-name='X-Centreon Demo Navigation|X-AKILA - .Web.'  CRITICAL: Incident #25421291, Scenario 'X-Centreon Demo Navigation' severity: Critical - Incident #25421962, Scenario 'X-AKILA - (Web)' severity: Critical - Incident #25422458, Scenario 'X-Centreon Demo Navigation' severity: Critical - Incident #25423513, Scenario 'X-Centreon Demo Navigation' status: Open, severity: Critical | 'ekara.incidents.current.total.count'=4;;;0;
        ...      2     --filter-name='yet not a name'                              UNKNOWN: No scenarios found, can't search for incidents. Please check filters.

incidents ${tc}
    [Documentation]    Check Iplabel scenarios
    [Tags]    monitoring   iplabel    restapi

    ${command}    Catenate
    ...    ${cmd}
    ...    --mode=incidents
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options                                                             expected_result    --
        ...      1     ${EMPTY}                                                                  UNKNOWN: Need to specify --api-key or --api-username/--api-password options.
        ...      2     --api-username=username --api-password=password --api-key=PaSsWoRdZ       UNKNOWN: Cannot use both --api-key and --api-username/--api-password options.
