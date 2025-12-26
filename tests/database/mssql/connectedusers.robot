*** Settings ***
Documentation       Database MSSQL plugin
...                 To execute this test, run an MSSQL Docker container with:
...                 docker run -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD='Str0ngPass!' -p 1433:1433 mcr.microsoft.com/mssql/server:2022-latest
...                 Then add a # on '[Setup] Skip' line below and execute the test.

Resource            ${CURDIR}${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${HOSTNAME}         127.0.0.1
${PORT}             1433
${USERNAME}         sa
${PASSWORD}         Str0ngPass!
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=database::mssql::plugin
...                 --mode=connected-users
...                 --hostname=${HOSTNAME}
...                 --username=${USERNAME}
...                 --password=${PASSWORD}
...                 --port=${PORT}


*** Test Cases ***
ConnectedUsers ${tc}
    [Documentation]    Check MSSQL connected users
    [Tags]    database    mssql
    [Setup]   Skip    Reason: This test can only be executed manually
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Regexp   ${command}    ${expected_regexp}

    Examples:   tc   extraoptions                             expected_regexp    --
    ...         1    ${EMPTY}                                 OK: \\\\d+ connected user(s) | 'mssql.users.connected.count'=\\\\d+;;;0;
    ...         2    ${EMPTY} --database-name='NoTeXiSt'      OK: 0 connected user(s) | 'mssql.users.connected.count'=0;;;0;
    ...         3    ${EMPTY} --database-name='master'        OK: [1-9]\\\\d* connected user(s) | 'mssql.users.connected.count'=[1-9]\\\\d*;;;0;
    ...         4    ${EMPTY} --count-admin-users             OK: [1-9]\\\\d* connected user(s) | 'mssql.users.connected.count'=[1-9]\\\\d*;;;0;
    ...         5    ${EMPTY} --uniq-users                    OK: [1-9]\\\\d* connected user(s) | 'mssql.users.connected.count'=[1-9]\\\\d*;;;0;
    ...         6    ${EMPTY} --warning-connected-user=:0     WARNING: [1-9]\\\\d* connected user(s) | 'mssql.users.connected.count'=[1-9]\\\\d*;0:0;;0;
    ...         7    ${EMPTY} --critical-connected-user=:0    CRITICAL: [1-9]\\\\d* connected user(s) | 'mssql.users.connected.count'=[1-9]\\\\d*;;0:0;0;
