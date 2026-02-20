*** Settings ***
Documentation       network::kairos::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::kairos::snmp::plugin
...         --mode=hardware
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=network/kairos/snmp/kairos-ent


*** Test Cases ***
Hardware ${tc}
    [Tags]    network    kairos    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Board voltage: 129.00V, TX current: 0.00A, temperature is 29 C, TX temperature is 20 C | 'board.voltage.volt'=129.00V;;;; 'board.tx.current.ampere'=0.00A;;;; 'board.temperature.celsius'=29C;;;; 'board.tx.temperature.celsius'=20C;;;;
    ...    2
    ...    --warning-board-temperature=1
    ...    WARNING: Board temperature is 29 C | 'board.voltage.volt'=129.00V;;;; 'board.tx.current.ampere'=0.00A;;;; 'board.temperature.celsius'=29C;0:1;;; 'board.tx.temperature.celsius'=20C;;;;
    ...    3
    ...    --critical-board-temperature=1
    ...    CRITICAL: Board temperature is 29 C | 'board.voltage.volt'=129.00V;;;; 'board.tx.current.ampere'=0.00A;;;; 'board.temperature.celsius'=29C;;0:1;; 'board.tx.temperature.celsius'=20C;;;;
    ...    4
    ...    --warning-board-tx-current=1:
    ...    WARNING: Board TX current: 0.00A | 'board.voltage.volt'=129.00V;;;; 'board.tx.current.ampere'=0.00A;1:;;; 'board.temperature.celsius'=29C;;;; 'board.tx.temperature.celsius'=20C;;;;
    ...    5
    ...    --critical-board-tx-current=1:
    ...    CRITICAL: Board TX current: 0.00A | 'board.voltage.volt'=129.00V;;;; 'board.tx.current.ampere'=0.00A;;1:;; 'board.temperature.celsius'=29C;;;; 'board.tx.temperature.celsius'=20C;;;;
    ...    6
    ...    --warning-board-tx-temperature=1
    ...    WARNING: Board TX temperature is 20 C | 'board.voltage.volt'=129.00V;;;; 'board.tx.current.ampere'=0.00A;;;; 'board.temperature.celsius'=29C;;;; 'board.tx.temperature.celsius'=20C;0:1;;;
    ...    7
    ...    --critical-board-tx-temperature=1
    ...    CRITICAL: Board TX temperature is 20 C | 'board.voltage.volt'=129.00V;;;; 'board.tx.current.ampere'=0.00A;;;; 'board.temperature.celsius'=29C;;;; 'board.tx.temperature.celsius'=20C;;0:1;;
    ...    8
    ...    --warning-board-voltage=1
    ...    WARNING: Board voltage: 129.00V | 'board.voltage.volt'=129.00V;0:1;;; 'board.tx.current.ampere'=0.00A;;;; 'board.temperature.celsius'=29C;;;; 'board.tx.temperature.celsius'=20C;;;;
    ...    9
    ...    --critical-board-voltage=1
    ...    CRITICAL: Board voltage: 129.00V | 'board.voltage.volt'=129.00V;;0:1;; 'board.tx.current.ampere'=0.00A;;;; 'board.temperature.celsius'=29C;;;; 'board.tx.temperature.celsius'=20C;;;;
