*** Settings ***
Documentation       Database Oracle plugin
...                 To execute this test, run an Oracle Docker container with:
...                 docker run -d -p 1522:1521 -e ORACLE_PWD=Oracle123    container-registry.oracle.com/database/free:latest
...                 To run these tests you need to manually configure an RMAN external catalog, which is not documented here

Resource            ${CURDIR}${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${HOSTNAME}     127.0.0.1
${USERNAME}     rman
${PASSWORD}     rman
${PORT}         1521
${CMD}          ${CENTREON_PLUGINS}
...             --plugin=database::oracle::plugin
...             --hostname=${HOSTNAME}
...             --port=${PORT}
...             --username=${USERNAME}
...             --password=${PASSWORD}
...             --servicename=FREEPDB1


*** Test Cases ***
RmanBackupAge ${tc}
    [Tags]    database    oracle    rman    notauto
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=rman-backup-age
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:
    ...    tc
    ...    extraoptions
    ...    expected_regexp
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    UNKNOWN: Cannot execute query: ORA-00942: table or view "SYS"."V_
    ...    2
    ...    --component-type=rman_catalog
    ...    CRITICAL: Rman 'DB INCR' backups never executed - Rman 'ARCHIVELOG' backups never executed - Rman 'CONTROLFILE' backups never executed | 'DB_FULL_backup_age'=
    ...    3
    ...    --component-type=rman_catalog --incremental-level
    ...    CRITICAL: Rman 'DB INCR' backups never executed - Rman 'ARCHIVELOG' backups never executed | 'DB_FULL_backup_age'=
    ...    4
    ...    --incremental-level
    ...    backup_set_details.incremental_level

RmanBackupProblems ${tc}
    [Tags]    database    oracle    rman    notauto
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=rman-backup-problems
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:
    ...    tc
    ...    extraoptions
    ...    expected_regexp
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    UNKNOWN: Cannot execute query: ORA-00942: table or view "SYS"."V_
    ...    2
    ...    --component-type=rman_catalog
    ...    OK: During the last 3 days, number of backups completed: 2, failed: 0, completed with warnings: 0, completed with errors: 0 | 'rman.backups.completed.count'=2;;;0; 'rman.backups.failed.count'=0;;;0; 'rman.backups.completed_with_warnings.count'=0;;;0; 'rman.backups.completed_with_errors.count'=0;;;0;

DisplayHelp ${tc}
    [Tags]    database    oracle    rman
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=rman-backup-problems
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:    tc    extraoptions    expected_regexp    --
    ...    1    --mode=rman-backup-problems --help    Plugin Description:
    ...    2    --mode=rman-backup-age --help    Plugin Description:
