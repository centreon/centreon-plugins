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
...                 --mode=locks
...                 --host=${HOSTNAME}
...                 --username=${USERNAME}
...                 --password=${PASSWORD}
...                 --port=${PORT}


*** Test Cases ***
Locks ${tc}
    [Documentation]    Check PostgreSQL Locks
    [Tags]    database    postgresql    notauto
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings  ${command}    ${expected_string}

    Examples:   tc   extraoptions                       expected_string    --
    ...         1    ${EMPTY}                           OK: All databases locks are ok | 'postgres#database.locks.total.count'=1;;;0; 'postgres#database.locks.waiting.count'=0;;;0; 'postgres#database.locks.accessshare.count'=1;;;0; 'template1#database.locks.total.count'=0;;;0; 'template1#database.locks.waiting.count'=0;;;0;
    ...         2    --include-database=postgres        OK: Database 'postgres' lock 'total':1, lock 'waiting':0, lock 'accessshare':1 | 'postgres#database.locks.total.count'=1;;;0; 'postgres#database.locks.waiting.count'=0;;;0; 'postgres#database.locks.accessshare.count'=1;;;0;
    ...         3    --exclude-database=postgres        OK: Database 'template1' lock 'total':0, lock 'waiting':0 | 'template1#database.locks.total.count'=0;;;0; 'template1#database.locks.waiting.count'=0;;;0;
    ...         4    --warning=total=10:                WARNING: Database 'postgres' lock 'total':1 - Database 'template1' lock 'total':0 | 'postgres#database.locks.total.count'=1;;;0; 'postgres#database.locks.waiting.count'=0;;;0; 'postgres#database.locks.accessshare.count'=1;;;0; 'template1#database.locks.total.count'=0;;;0; 'template1#database.locks.waiting.count'=0;;;0;
    ...         5    --critical=total=10:               CRITICAL: Database 'postgres' lock 'total':1 - Database 'template1' lock 'total':0 | 'postgres#database.locks.total.count'=1;;;0; 'postgres#database.locks.waiting.count'=0;;;0; 'postgres#database.locks.accessshare.count'=1;;;0; 'template1#database.locks.total.count'=0;;;0; 'template1#database.locks.waiting.count'=0;;;0;
