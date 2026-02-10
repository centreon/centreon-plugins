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
...                 --mode=vacuum
...                 --host=${HOSTNAME}
...                 --username=${USERNAME}
...                 --password=${PASSWORD}
...                 --port=${PORT}


*** Test Cases ***
EmptyVacuum ${tc}
    [Documentation]    Check PostgreSQL Vacuum
    [Tags]    database    postgresql
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Regexp   ${command}    ${expected_regexp}

    Examples:   tc   extraoptions                       expected_regexp    --
    ...         1    --help                             Plugin Description:


Vacuum ${tc}
    [Documentation]    Check PostgreSQL Vacuum
    [Tags]    database    postgresql    notauto
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Regexp   ${command}    ${expected_regexp}

    Examples:   tc   extraoptions                       expected_regexp    --
    ...         1    ${EMPTY}                           OK: Most recent vacuum dates back from \\\\d+ seconds \\\\| 'vacuum.last.execution.seconds'=\\\\d+s;;;0;
    ...         2    --warning-vacuum=:1                WARNING: Most recent vacuum dates back from \\\\d+ seconds \\\\| 'vacuum.last.execution.seconds'=\\\\d+s;0:1;;0;
    ...         3    --critical-vacuum=:1               CRITICAL: Most recent vacuum dates back from \\\\d+ seconds \\\\| 'vacuum.last.execution.seconds'=\\\\d+s;;0:1;0;
