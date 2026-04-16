*** Settings ***
Documentation       Check PaloAlto authentication (api-key or basic).

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon-paloalto-api.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=network::paloalto::api::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --mode=system     

*** Test Cases ***
paloalto-environment ${tc}
    [Tags]    network    paloalto    api    environment
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                             expected_result    --
            ...      1     ${EMPTY}                                                  UNKNOWN: With --auth-type=api-key: specify --api-key or --username/--password to auto-generate it.
            ...      2     --auth-type=api-key                                       UNKNOWN: With --auth-type=api-key: specify --api-key or --username/--password to auto-generate it.
            ...      3     --auth-type=api-key --username=AA --password=BB           OK: System uptime: 8552549 seconds, certificate status: Valid, operational mode: normal, software version: 10.1.12, WildFire mode: Disabled | 'system.uptime.seconds'=8552549s;;;0;
            ...      4     --auth-type=basic                                         UNKNOWN: Need to specify --username/--password options with --auth-type=basic.
            ...      5     --auth-type=basic --username=AA --password=BB             OK: System uptime: 8552549 seconds, certificate status: Valid, operational mode: normal, software version: 10.1.12, WildFire mode: Disabled | 'system.uptime.seconds'=8552549s;;;0;
