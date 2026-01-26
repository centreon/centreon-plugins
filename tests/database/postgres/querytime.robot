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
...                 --mode=query-time
...                 --host=${HOSTNAME}
...                 --username=${USERNAME}
...                 --password=${PASSWORD}
...                 --port=${PORT}


*** Test Cases ***
Querytime ${tc}
    [Documentation]    Check PostgreSQL Querytime
    [Tags]    database    postgresql    noauto
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Regexp   ${command}    ${expected_regexp}

    Examples:   tc   extraoptions                  expected_regexp    --
    ...         1    ${EMPTY}                      OK: All databases queries time are ok | 'postgres#database.longqueries.count'=\\\\d;;;0; 'template0#database.longqueries.count'=\\\\d;;;0; 'template1#database.longqueries.count'=\\\\d;;;0;
    ...         2    --include-user=UNK            OK: All databases queries time are ok
    ...         3    --exclude-user=UNK            OK: All databases queries time are ok | 'postgres#database.longqueries.count'=\\\\d;;;0; 'template0#database.longqueries.count'=\\\\d;;;0; 'template1#database.longqueries.count'=\\\\d;;;0;
    ...         4    --include-database=postgres   OK: All queries time are ok on database 'postgres' | 'postgres#database.longqueries.count'=0;;;0;
    ...         5    --exclude-database=postgres   OK: All databases queries time are ok | 'template0#database.longqueries.count'=0;;;0; 'template1#database.longqueries.count'=0;;;0;
    ...         6    --warning=1:                  WARNING: 1 request exceed warning threshold on database 'postgres' | 'postgres#database.longqueries.count'=1;;;0; 'template0#database.longqueries.count'=0;;;0; 'template1#database.longqueries.count'=0;;;0;
    ...         7    --critical=1:                 CRITICAL: 1 request exceed critical threshold on database 'postgres' | 'postgres#database.longqueries.count'=1;;;0; 'template0#database.longqueries.count'=0;;;0; 'template1#database.longqueries.count'=0;;;0;
    ...         8    --idle                        OK: All databases queries time are ok | 'postgres#database.longqueries.count'=0;;;0; 'template0#database.longqueries.count'=0;;;0; 'template1#database.longqueries.count'=0;;;0;
