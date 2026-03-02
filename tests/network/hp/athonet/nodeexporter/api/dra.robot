*** Settings ***
Documentation       HP Athonet Node Exporter plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}mockoon.json

${BASE_URL}             http://${HOSTNAME}:${APIPORT}
${CMD}                  ${CENTREON_PLUGINS} --plugin=network::hp::athonet::nodeexporter::api::plugin --mode=dra --hostname=${HOSTNAME} --port=${APIPORT} --proto http --api-username=1 --api-password=1



*** Test Cases ***
DRA (Diameter Routing Agent) ${tc}
    [Tags]    network    hp    api
    ${command}    Catenate
    ...    ${CMD}
    ...    --critical-diameter-connection-status=0
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extra_options                                                                         expected_result    --
            ...       1   ${EMPTY}                                                                              OK: All diameter connections are ok | 'diameter.connections.detected.count'=26;;;0; 'diameter.connections.up.count'=13;;;0;26 'diameter.connections.down.count'=13;;;0;26
            ...       2   --filter-origin-host=site1-dra.*fgh123                                                OK: All diameter connections are ok | 'diameter.connections.detected.count'=4;;;0; 'diameter.connections.up.count'=2;;;0;4 'diameter.connections.down.count'=2;;;0;4
            ...       3   --filter-origin-host=site1-dra.*fgh123 --unknown-diameter-connection-status=1         UNKNOWN: diameter stack 'stack-local' origin host 'site1-dra01.bjo.fgh123.klm567.domain.local' connection status: up - diameter stack 'stack-public' origin host 'site1-dra01-local.bjo.fgh123.klm567.domain.local' connection status: up - diameter stack 'stack-public' origin host 'site1-dra01.bjo.fgh123.klm567.domain.local' connection status: down - diameter stack 'stack-local' origin host 'site1-dra01-local.bjo.fgh123.klm567.domain.local' connection status: down | 'diameter.connections.detected.count'=4;;;0; 'diameter.connections.up.count'=2;;;0;4 'diameter.connections.down.count'=2;;;0;4
            ...       4   --filter-origin-host=site1-dra.*fgh123 --warning-diameter-connection-status=1         WARNING: diameter stack 'stack-local' origin host 'site1-dra01.bjo.fgh123.klm567.domain.local' connection status: up - diameter stack 'stack-public' origin host 'site1-dra01-local.bjo.fgh123.klm567.domain.local' connection status: up - diameter stack 'stack-public' origin host 'site1-dra01.bjo.fgh123.klm567.domain.local' connection status: down - diameter stack 'stack-local' origin host 'site1-dra01-local.bjo.fgh123.klm567.domain.local' connection status: down | 'diameter.connections.detected.count'=4;;;0; 'diameter.connections.up.count'=2;;;0;4 'diameter.connections.down.count'=2;;;0;4
            ...       5   --filter-origin-host=site1-dra.*fgh123 --critical-diameter-connection-status=1        CRITICAL: diameter stack 'stack-local' origin host 'site1-dra01.bjo.fgh123.klm567.domain.local' connection status: up - diameter stack 'stack-public' origin host 'site1-dra01-local.bjo.fgh123.klm567.domain.local' connection status: up - diameter stack 'stack-public' origin host 'site1-dra01.bjo.fgh123.klm567.domain.local' connection status: down - diameter stack 'stack-local' origin host 'site1-dra01-local.bjo.fgh123.klm567.domain.local' connection status: down | 'diameter.connections.detected.count'=4;;;0; 'diameter.connections.up.count'=2;;;0;4 'diameter.connections.down.count'=2;;;0;4
            ...       6   --filter-origin-host=site1-dra.*fgh123 --warning-diameter-connections-detected=1      WARNING: Number of diameter connections detected: 4 | 'diameter.connections.detected.count'=4;0:1;;0; 'diameter.connections.up.count'=2;;;0;4 'diameter.connections.down.count'=2;;;0;4
            ...       7   --filter-origin-host=site1-dra.*fgh123 --critical-diameter-connections-detected=1     CRITICAL: Number of diameter connections detected: 4 | 'diameter.connections.detected.count'=4;;0:1;0; 'diameter.connections.up.count'=2;;;0;4 'diameter.connections.down.count'=2;;;0;4
            ...       8   --filter-origin-host=site1-dra.*fgh123 --warning-diameter-connections-up=1            WARNING: Number of diameter connections up: 2 | 'diameter.connections.detected.count'=4;;;0; 'diameter.connections.up.count'=2;0:1;;0;4 'diameter.connections.down.count'=2;;;0;4
            ...       9   --filter-origin-host=site1-dra.*fgh123 --critical-diameter-connections-up=1           CRITICAL: Number of diameter connections up: 2 | 'diameter.connections.detected.count'=4;;;0; 'diameter.connections.up.count'=2;;0:1;0;4 'diameter.connections.down.count'=2;;;0;4
            ...      10   --filter-origin-host=site1-dra.*fgh123 --warning-diameter-connections-down=1          WARNING: Number of diameter connections down: 2 | 'diameter.connections.detected.count'=4;;;0; 'diameter.connections.up.count'=2;;;0;4 'diameter.connections.down.count'=2;0:1;;0;4
            ...      11   --filter-origin-host=site1-dra.*fgh123 --critical-diameter-connections-down=1         CRITICAL: Number of diameter connections down: 2 | 'diameter.connections.detected.count'=4;;;0; 'diameter.connections.up.count'=2;;;0;4 'diameter.connections.down.count'=2;;0:1;0;4

