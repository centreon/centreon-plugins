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
...                 --mode=list-databases
...                 --host=${HOSTNAME}
...                 --username=${USERNAME}
...                 --password=${PASSWORD}
...                 --port=${PORT}


*** Test Cases ***
Listdatabase ${tc}
    [Documentation]    Check PostgreSQL List Database
    [Tags]    database    postgresql    noauto
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings   ${command}    ${expected_string}

    Examples:   tc   extraoptions                       expected_string    --
    ...         1    ${EMPTY}                           List of databases: 'postgres' 'template0' 'template1'
    ...         2    --include-database=postgres        List of databases: 'postgres'
    ...         3    --exclude-database=postgres        List of databases: 'template0' 'template1'

