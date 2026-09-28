*** Settings ***
Documentation       Database MSSQL plugin
...                 To execute this test, run an MSSQL Docker container with:
...                 docker run -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD='Str0ngPass!' -p 1433:1433 mcr.microsoft.com/mssql/server:2022-latest
...                 Then add a # on '[Setup] Skip' line below and execute the test.

Resource            ${CURDIR}${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${HOSTNAME}     127.0.0.1
${PORT}         1433
${USERNAME}     sa
${PASSWORD}     Str0ngPass!
${CMD}          ${CENTREON_PLUGINS}
...             --plugin=database::mssql::plugin
...             --mode=databases-size
...             --hostname=${HOSTNAME}
...             --username=${USERNAME}
...             --password=${PASSWORD}
...             --port=${PORT}


*** Test Cases ***
database size ${tc}
    [Documentation]    Check MSSQL connected users
    [Tags]    database    mssql
    [Setup]    Skip    Reason: This test can only be executed manually
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:    tc    extraoptions    expected_regexp    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All databases are ok | 'master#datafiles.space.usage.bytes'=\\\\d+;;;0;.*
    ...    2
    ...    --filter-database='NoTeXiSt'
    ...    UNKNOWN: No database found, check filter parameter.
