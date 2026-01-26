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
...                 --mode=backends
...                 --host=${HOSTNAME}
...                 --username=${USERNAME}
...                 --password=${PASSWORD}
...                 --port=${PORT}


*** Test Cases ***
Backends ${tc}
    [Documentation]    Check PostgreSQL Backends
    [Tags]    database    postgresql    noauto
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Regexp   ${command}    ${expected_regexp}

    Examples:   tc   extraoptions                                               expected_regexp    --
    ...         1    ${EMPTY}                                                   OK: Instance at \\\\d+.00% of client connections limit (\\\\d+ of max. 100) | 'instance.connected.count'=\\\\d+;;;0; 'instance.connected.percentage'=\\\\d+%;;;0; 'postgres#database.connected.count'=\\\\d+;;;0; 'postgres#database.connected.percentage'=\\\\d+%;;;0; 'template0#database.connected.count'=0;;;0; 'template0#database.connected.percentage'=0%;;;0; 'template1#database.connected.count'=0;;;0; 'template1#database.connected.percentage'=0%;;;0;
    ...         2    --check=role --include-role=pg_write_server_files          OK: Instance at \\\\d+.00% of client connections limit (\\\\d+ of max. 100) - Role 'pg_write_server_files' at 0.00% of connections limit (0 of max. 100) | 'instance.connected.count'=\\\\d+;;;0; 'instance.connected.percentage'=\\\\d+%;;;0; 'pg_write_server_files#role.connected.count'=0;;;0; 'pg_write_server_files#role.connected.percentage'=0%;;;0;
    ...         3    --check=role --exclude-role=pg                             OK: Instance at \\\\d+.00% of client connections limit (\\\\d+ of max. 100) - Role 'postgres' at \\\\d+.00% of connections limit (\\\\d+ of max. 100) | 'instance.connected.count'=\\\\d+;;;0; 'instance.connected.percentage'=\\\\d+%;;;0; 'postgres#role.connected.count'=\\\\d+;;;0; 'postgres#role.connected.percentage'=\\\\d+%;;;0;
    ...         4    --check=database --include-database=template1              OK: Instance at \\\\d+.00% of client connections limit (\\\\d+ of max. 100) - Database 'template1' at 0.00% of connections limit (0 of max. 100) | 'instance.connected.count'=\\\\d+;;;0; 'instance.connected.percentage'=\\\\d+%;;;0; 'template1#database.connected.count'=0;;;0; 'template1#database.connected.percentage'=0%;;;0
    ...         5    --check=database --exclude-database=template               OK: Instance at \\\\d+.00% of client connections limit (\\\\d+ of max. 100) - Database 'postgres' at \\\\d+.00% of connections limit (\\\\d+ of max. 100) | 'instance.connected.count'=\\\\d+;;;0; 'instance.connected.percentage'=\\\\d+%;;;0; 'postgres#database.connected.count'=\\\\d+;;;0; 'postgres#database.connected.percentage'=\\\\d+%;;;0;
    ...         6    --warning=10:                                              WARNING: Instance at \\\\d+.00% of client connections limit (\\\\d+ of max. 100) | 'instance.connected.count'=\\\\d+;10:;;0; 'instance.connected.percentage'=\\\\d+%;;;0; 'postgres#database.connected.count'=\\\\d+;;;0; 'postgres#database.connected.percentage'=\\\\d+%;;;0; 'template0#database.connected.count'=0;;;0; 'template0#database.connected.percentage'=0%;;;0; 'template1#database.connected.count'=0;;;0; 'template1#database.connected.percentage'=0%;;;0;
    ...         7    --critical=10:                                             CRITICAL: Instance at \\\\d+.00% of client connections limit (\\\\d+ of max. 100) | 'instance.connected.count'=\\\\d+;;10:;0; 'instance.connected.percentage'=2%;;;0; 'postgres#database.connected.count'=\\\\d+;;;0; 'postgres#database.connected.percentage'=\\\\d+%;;;0; 'template0#database.connected.count'=0;;;0; 'template0#database.connected.percentage'=0%;;;0; 'template1#database.connected.count'=0;;;0; 'template1#database.connected.percentage'=0%;;;0;
