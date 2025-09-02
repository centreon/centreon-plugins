*** Settings ***
Documentation       Quanta

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}quanta.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::monitoring::quanta::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --api-token=PaSsWoRd
...                 --site-id=10
...                 --proto=http
...                 --port=${APIPORT}

*** Test Cases ***
UserJourneyIncidents ${tc}
    [Tags]    quanta    api
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=user-journey-incidents
    ...    --journey-id=3666
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp     ${command}    ${expected_regexp}

    Examples:        tc       extraoptions                                                                           expected_regexp    --
            ...      1        ${EMPTY}                                                                               CRITICAL: Incident for interaction 'Decline cookies' status: open | 'quanta.incidents.total.count'=32;;;0;
            ...      2        --ignore-closed                                                                        CRITICAL: Incident for interaction 'Decline cookies' status: open | 'quanta.incidents.total.count'=1;;;0;
            ...      3        --critical-incident-status='' --warning-incident-status='\\\%{status} =~ /open/i'      WARNING: Incident for interaction 'Decline cookies' status: open | 'quanta.incidents.total.count'=32;;;0;
            ...      4        --critical-incident-status='' --warning-incident-type='\\\%{type} =~ /timeout/i'       ^WARNING: Incident for interaction.+$
            ...      5        --critical-incident-status='' --warning-incident-duration=:10                          ^WARNING: Incident for interaction.+$
