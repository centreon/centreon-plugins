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
...                 --mode=hitratio
...                 --host=${HOSTNAME}
...                 --username=${USERNAME}
...                 --password=${PASSWORD}
...                 --port=${PORT}


*** Test Cases ***
Hitratio ${tc}
    [Documentation]    Check PostgreSQL Backends
    [Tags]    database    postgresql    noauto
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Regexp   ${command}    ${expected_regexp}

    Examples:   tc   extraoptions                            expected_regexp    --
    ...         1    ${EMPTY}                                OK: All databases hitratio are ok
    ...         2    --warning-delta=:10                     WARNING: Database 'postgres' hitratio at % - Database 'template0' hitratio at [\\\\d\\\\.]+% - Database 'template1' hitratio at [\\\\d\\\\.]+% | 'postgres#database.hitratio.delta.percentage'=[\\\\d\\\\.]+%;0:10;;0;100 'postgres#database.hitratio.average.percentage'=[\\\\d\\\\.]+%;;;0;100 'template0#database.hitratio.delta.percentage'=[\\\\d\\\\.]+%;0:10;;0;100 'template0#database.hitratio.average.percentage'=[\\\\d\\\\.]+%;;;0;100 'template1#database.hitratio.delta.percentage'=[\\\\d\\\\.]+%;0:10;;0;100 'template1#database.hitratio.average.percentage'=[\\\\d\\\\.]+%;;;0;100
    ...         3    --critical-delta=:10                    CRITICAL: Database 'postgres' hitratio at [\\\\d\\\\.]+% - Database 'template0' hitratio at [\\\\d\\\\.]+% - Database 'template1' hitratio at [\\\\d\\\\.]+% | 'postgres#database.hitratio.delta.percentage'=[\\\\d\\\\.]+%;;0:10;0;100 'postgres#database.hitratio.average.percentage'=[\\\\d\\\\.]+%;;;0;100 'template0#database.hitratio.delta.percentage'=[\\\\d\\\\.]+%;;0:10;0;100 'template0#database.hitratio.average.percentage'=[\\\\d\\\\.]+%;;;0;100 'template1#database.hitratio.delta.percentage'=[\\\\d\\\\.]+%;;0:10;0;100 'template1#database.hitratio.average.percentage'=[\\\\d\\\\.]+%;;;0;100
    ...         4    --warning-average=:10                   WARNING: Database 'postgres' hitratio at [\\\\d\\\\.]+% - Database 'template0' hitratio at [\\\\d\\\\.]+% - Database 'template1' hitratio at [\\\\d\\\\.]+% | 'postgres#database.hitratio.delta.percentage'=[\\\\d\\\\.]+%;;;0;100 'postgres#database.hitratio.average.percentage'=[\\\\d\\\\.]+%;0:10;;0;100 'template0#database.hitratio.delta.percentage'=[\\\\d\\\\.]+%;;;0;100 'template0#database.hitratio.average.percentage'=[\\\\d\\\\.]+%;0:10;;0;100 'template1#database.hitratio.delta.percentage'=[0\\\\d\\\\.]+%;;;0;100 'template1#database.hitratio.average.percentage'=[\\\\d\\\\.]+%;0:10;;0;100
    ...         5    --critical-average=:10                  CRITICAL: Database 'postgres' hitratio at [\\\\d\\\\.]+% - Database 'template0' hitratio at [\\\\d\\\\.]+% - Database 'template1' hitratio at [\\\\d\\\\.]+% | 'postgres#database.hitratio.delta.percentage'=[\\\\d\\\\.]+%;;;0;100 'postgres#database.hitratio.average.percentage'=[\\\\d\\\\.]+%;;0:10;0;100 'template0#database.hitratio.delta.percentage'=[\\\\d\\\\.]+%;;;0;100 'template0#database.hitratio.average.percentage'=[\\\\d\\\\.]+%;;0:10;0;100 'template1#database.hitratio.delta.percentage'=[\\\\d\\\\.]+%;;;0;100 'template1#database.hitratio.average.percentage'=[\\\\d\\\\.]+%;;0:10;0;100
