*** Settings ***
Documentation       Database PostgreSQL plugin
...                 To execute this test, run an MSSQL Docker container with:
...                 docker run --name pg -e POSTGRES_PASSWORD='Str0ngPass!' -p 5432:5432 -d postgres

Resource            ${CURDIR}${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${HOSTNAME}         127.0.0.1
${PORT}             5432
${USERNAME}         postgres
${PASSWORD}         secret
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=database::postgres::plugin
...                 --mode=timesync
...                 --host=${HOSTNAME}
...                 --username=${USERNAME}
...                 --password=${PASSWORD}
...                 --port=${PORT}


*** Test Cases ***
Timesync ${tc}
    [Documentation]    Check PostgreSQL Timesync
    [Tags]    database    postgresql   noauto
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Regexp   ${command}    ${expected_regexp}

    Examples:   tc   extraoptions                       expected_regexp    --
    ...         1    ${EMPTY}                           OK: [\\\\d\\\\.+-]+s time diff between servers \\\\| 'time.offset.seconds'=-[\\\\d\\\\.+-]+s;;;0;
    ...         2    --warning-offset=:0                WARNING: [\\\\d\\\\.+-]+s time diff between servers \\\\| 'time.offset.seconds'=-[\\\\d\\\\.+-]+s;0:0;;0;
    ...         3    --critical-offset=:0               CRITICAL: [\\\\d\\\\.+-]+s time diff between servers \\\\| 'time.offset.seconds'=-[\\\\d\\\\.+-]+s;;0:0;0;
