*** Settings ***
Documentation       Check PaloAlto High Availability (HA) status.

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
...                 --mode=ha

*** Test Cases ***
paloalto-ha ${tc}
    [Tags]    network    paloalto    api    ha
    ${command}    Catenate
    ...    ${CMD}
    ...    --auth-type=api-key
    ...    --api-key=D@pAs$W@rD
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                   expected_result    --
            ...      1     ${EMPTY}                                                        OK: PA-850 status: local state: passive (priority: 110), peer state: active (priority: 100, conn: up), state sync: synchronized, HA1 link: up, HA2 link: up, HA mode: active-passive, build compatibility: Match
            ...      2     --warning-peer-state='\\\%{peer_state_priority} =~ /active/'    WARNING: PA-850 status: peer state: active (priority: 100, conn: up)
            ...      3     --critical-peer-state='\\\%{peer_state_priority} =~ /active/'   CRITICAL: PA-850 status: peer state: active (priority: 100, conn: up)
            ...      4     --warning-state-sync='\\\%{state_sync} =~ /synchronized/'       WARNING: PA-850 status: state sync: synchronized
            ...      5     --critical-state-sync='\\\%{state_sync} =~ /synchronized/'      CRITICAL: PA-850 status: state sync: synchronized
            ...      6     --warning-ha1-link-status='\\\%{ha1_status} =~ /up/'            WARNING: PA-850 status: HA1 link: up
            ...      7     --critical-ha1-link-status='\\\%{ha1_status} =~ /up/'           CRITICAL: PA-850 status: HA1 link: up
            ...      8     --warning-ha2-link-status='\\\%{ha2_status} =~ /up/'            WARNING: PA-850 status: HA2 link: up
            ...      9     --critical-ha2-link-status='\\\%{ha2_status} =~ /up/'           CRITICAL: PA-850 status: HA2 link: up
            ...      10    --warning-build-compat='\\\%{build_compat} =~ /Match/'          WARNING: PA-850 status: build compatibility: Match
            ...      11    --critical-build-compat='\\\%{build_compat} =~ /Match/'         CRITICAL: PA-850 status: build compatibility: Match
