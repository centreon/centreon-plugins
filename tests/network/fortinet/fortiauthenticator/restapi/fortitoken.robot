*** Settings ***
Documentation       FortiAuthenticator REST API FortiToken Status

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}fortiauthenticator.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS} 
...                 --plugin=network::fortinet::fortiauthenticator::restapi::plugin
...                 --mode=fortitoken
...                 --hostname=${HOSTNAME}
...                 --api-username=FAKE
...                 --api-token=T@k3nn
...                 --proto=http
...                 --port=${APIPORT}

*** Test Cases ***
Fortitoken ${tc}
    [Tags]    network   fortinet    fortiauthenticator    restapi

    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:    tc       extraoptions                      expected_result   --
    ...          1        ${EMPTY}                          OK: [Tokens] total:29 - assigned:24(82.76%) - available:5(17.24%) - pending:0(0.00%) | 'tokens.total.count'=29;;;0; 'tokens.assigned.count'=29;;;0; 'tokens.pending.count'=29;;;0; 'tokens.available.count'=29;;;0; 'tokens.assigned.percentage'=29.00%;;;0;100 'tokens.pending.percentage'=29.00%;;;0;100 'tokens.available.percentage'=29.00%;;;0;100
    ...          2        --api-token=FAKE                  UNKNOWN: 401 Unauthorized
    ...          3        --warning-assigned-prct=:10       WARNING: [Tokens] total:29 - assigned:24(82.76%) - available:5(17.24%) - pending:0(0.00%) | 'tokens.total.count'=29;;;0; 'tokens.assigned.count'=29;;;0; 'tokens.pending.count'=29;;;0; 'tokens.available.count'=29;;;0; 'tokens.assigned.percentage'=29.00%;0:10;;0;100 'tokens.pending.percentage'=29.00%;;;0;100 'tokens.available.percentage'=29.00%;;;0;100
    ...          4        --critical-assigned-prct=:10      CRITICAL: [Tokens] total:29 - assigned:24(82.76%) - available:5(17.24%) - pending:0(0.00%) | 'tokens.total.count'=29;;;0; 'tokens.assigned.count'=29;;;0; 'tokens.pending.count'=29;;;0; 'tokens.available.count'=29;;;0; 'tokens.assigned.percentage'=29.00%;;0:10;0;100 'tokens.pending.percentage'=29.00%;;;0;100 'tokens.available.percentage'=29.00%;;;0;100
    ...          5        --include-type=ftk                OK: [Tokens] total:3 - assigned:1(33.33%) - available:2(66.67%) - pending:0(0.00%) | 'tokens.total.count'=3;;;0; 'tokens.assigned.count'=3;;;0; 'tokens.pending.count'=3;;;0; 'tokens.available.count'=3;;;0; 'tokens.assigned.percentage'=3.00%;;;0;100 'tokens.pending.percentage'=3.00%;;;0;100 'tokens.available.percentage'=3.00%;;;0;100
    ...          6        --exclude-type=ftk                OK: [Tokens] total:26 - assigned:23(88.46%) - available:3(11.54%) - pending:0(0.00%) | 'tokens.total.count'=26;;;0; 'tokens.assigned.count'=26;;;0; 'tokens.pending.count'=26;;;0; 'tokens.available.count'=26;;;0; 'tokens.assigned.percentage'=26.00%;;;0;100 'tokens.pending.percentage'=26.00%;;;0;100 'tokens.available.percentage'=26.00%;;;0;100
    ...          7        --warning-assigned=30:            WARNING: [Tokens] total:29 - assigned:24(82.76%) - available:5(17.24%) - pending:0(0.00%) | 'tokens.total.count'=29;;;0; 'tokens.assigned.count'=29;30:;;0; 'tokens.pending.count'=29;;;0; 'tokens.available.count'=29;;;0; 'tokens.assigned.percentage'=29.00%;;;0;100 'tokens.pending.percentage'=29.00%;;;0;100 'tokens.available.percentage'=29.00%;;;0;100
    ...          8        --critical-assigned=30:           CRITICAL: [Tokens] total:29 - assigned:24(82.76%) - available:5(17.24%) - pending:0(0.00%) | 'tokens.total.count'=29;;;0; 'tokens.assigned.count'=29;;30:;0; 'tokens.pending.count'=29;;;0; 'tokens.available.count'=29;;;0; 'tokens.assigned.percentage'=29.00%;;;0;100 'tokens.pending.percentage'=29.00%;;;0;100 'tokens.available.percentage'=29.00%;;;0;100
    ...          9        --warning-available=30:           WARNING: [Tokens] total:29 - assigned:24(82.76%) - available:5(17.24%) - pending:0(0.00%) | 'tokens.total.count'=29;;;0; 'tokens.assigned.count'=29;;;0; 'tokens.pending.count'=29;;;0; 'tokens.available.count'=29;30:;;0; 'tokens.assigned.percentage'=29.00%;;;0;100 'tokens.pending.percentage'=29.00%;;;0;100 'tokens.available.percentage'=29.00%;;;0;100
    ...          10       --critical-available=30:          CRITICAL: [Tokens] total:29 - assigned:24(82.76%) - available:5(17.24%) - pending:0(0.00%) | 'tokens.total.count'=29;;;0; 'tokens.assigned.count'=29;;;0; 'tokens.pending.count'=29;;;0; 'tokens.available.count'=29;;30:;0; 'tokens.assigned.percentage'=29.00%;;;0;100 'tokens.pending.percentage'=29.00%;;;0;100 'tokens.available.percentage'=29.00%;;;0;100
    ...          11       --warning-available-prct=30:      WARNING: [Tokens] total:29 - assigned:24(82.76%) - available:5(17.24%) - pending:0(0.00%) | 'tokens.total.count'=29;;;0; 'tokens.assigned.count'=29;;;0; 'tokens.pending.count'=29;;;0; 'tokens.available.count'=29;;;0; 'tokens.assigned.percentage'=29.00%;;;0;100 'tokens.pending.percentage'=29.00%;;;0;100 'tokens.available.percentage'=29.00%;30:;;0;100
    ...          12       --critical-available-prct=30:     CRITICAL: [Tokens] total:29 - assigned:24(82.76%) - available:5(17.24%) - pending:0(0.00%) | 'tokens.total.count'=29;;;0; 'tokens.assigned.count'=29;;;0; 'tokens.pending.count'=29;;;0; 'tokens.available.count'=29;;;0; 'tokens.assigned.percentage'=29.00%;;;0;100 'tokens.pending.percentage'=29.00%;;;0;100 'tokens.available.percentage'=29.00%;;30:;0;100
    ...          13       --warning-pending=30:             WARNING: [Tokens] total:29 - assigned:24(82.76%) - available:5(17.24%) - pending:0(0.00%) | 'tokens.total.count'=29;;;0; 'tokens.assigned.count'=29;;;0; 'tokens.pending.count'=29;30:;;0; 'tokens.available.count'=29;;;0; 'tokens.assigned.percentage'=29.00%;;;0;100 'tokens.pending.percentage'=29.00%;;;0;100 'tokens.available.percentage'=29.00%;;;0;100
    ...          14       --critical-pending=30:            CRITICAL: [Tokens] total:29 - assigned:24(82.76%) - available:5(17.24%) - pending:0(0.00%) | 'tokens.total.count'=29;;;0; 'tokens.assigned.count'=29;;;0; 'tokens.pending.count'=29;;30:;0; 'tokens.available.count'=29;;;0; 'tokens.assigned.percentage'=29.00%;;;0;100 'tokens.pending.percentage'=29.00%;;;0;100 'tokens.available.percentage'=29.00%;;;0;100
    ...          15       --warning-pending-prct=30:        WARNING: [Tokens] total:29 - assigned:24(82.76%) - available:5(17.24%) - pending:0(0.00%) | 'tokens.total.count'=29;;;0; 'tokens.assigned.count'=29;;;0; 'tokens.pending.count'=29;;;0; 'tokens.available.count'=29;;;0; 'tokens.assigned.percentage'=29.00%;;;0;100 'tokens.pending.percentage'=29.00%;30:;;0;100 'tokens.available.percentage'=29.00%;;;0;100
    ...          16       --critical-pending-prct=30:       CRITICAL: [Tokens] total:29 - assigned:24(82.76%) - available:5(17.24%) - pending:0(0.00%) | 'tokens.total.count'=29;;;0; 'tokens.assigned.count'=29;;;0; 'tokens.pending.count'=29;;;0; 'tokens.available.count'=29;;;0; 'tokens.assigned.percentage'=29.00%;;;0;100 'tokens.pending.percentage'=29.00%;;30:;0;100 'tokens.available.percentage'=29.00%;;;0;100
    ...          17       --warning-total=30:               WARNING: [Tokens] total:29 - assigned:24(82.76%) - available:5(17.24%) - pending:0(0.00%) | 'tokens.total.count'=29;30:;;0; 'tokens.assigned.count'=29;;;0; 'tokens.pending.count'=29;;;0; 'tokens.available.count'=29;;;0; 'tokens.assigned.percentage'=29.00%;;;0;100 'tokens.pending.percentage'=29.00%;;;0;100 'tokens.available.percentage'=29.00%;;;0;100
    ...          18       --critical-total=30:              CRITICAL: [Tokens] total:29 - assigned:24(82.76%) - available:5(17.24%) - pending:0(0.00%) | 'tokens.total.count'=29;;30:;0; 'tokens.assigned.count'=29;;;0; 'tokens.pending.count'=29;;;0; 'tokens.available.count'=29;;;0; 'tokens.assigned.percentage'=29.00%;;;0;100 'tokens.pending.percentage'=29.00%;;;0;100 'tokens.available.percentage'=29.00%;;;0;100
