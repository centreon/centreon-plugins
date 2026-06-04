*** Settings ***
Documentation       database::mssql::plugin

Resource            ${CURDIR}${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${INJECT_PERL}      -MDBD::Sybase -I${CURDIR}
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=database::mssql::plugin
...                 --mode=dead-locks
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --username=1
...                 --password=1


*** Test Cases ***
Dead-locks ${tc}
    [Tags]    database    mssql

    ${OLD_PERL5OPT}=    Get Environment Variable    PERL5OPT    default=
    Set Environment Variable    PERL5OPT    ${INJECT_PERL} ${OLD_PERL5OPT}
    Set Environment Variable    MOCK_DBI_DATA_FILE    ${CURDIR}${/}dead-locks-mock-data.pl

    ${command}=    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: 317.00 total dead locks/s | 'total#mssql.deadlocks.count'=317.00;;;0; 'AllocUnit#mssql.deadlocks.count'=0.00;;;0; 'Application#mssql.deadlocks.count'=0.00;;;0; 'Database#mssql.deadlocks.count'=11.00;;;0; 'Extent#mssql.deadlocks.count'=0.00;;;0; 'File#mssql.deadlocks.count'=141.00;;;0; 'HoBT#mssql.deadlocks.count'=0.00;;;0; 'Key#mssql.deadlocks.count'=101.00;;;0; 'Metadata#mssql.deadlocks.count'=38.00;;;0; 'OIB#mssql.deadlocks.count'=0.00;;;0; 'Object#mssql.deadlocks.count'=2.00;;;0; 'Page#mssql.deadlocks.count'=0.00;;;0; 'RID#mssql.deadlocks.count'=24.00;;;0; 'RowGroup#mssql.deadlocks.count'=0.00;;;0; 'Xact#mssql.deadlocks.count'=0.00;;;0;
    ...    2
    ...    --filter-database=Database
    ...    OK: 11.00 total dead locks/s - 11.00 dead locks/s | 'total#mssql.deadlocks.count'=11.00;;;0; 'Database#mssql.deadlocks.count'=11.00;;;0;
    ...    3
    ...    --include-instance=Database
    ...    OK: 11.00 total dead locks/s - 11.00 dead locks/s | 'total#mssql.deadlocks.count'=11.00;;;0; 'Database#mssql.deadlocks.count'=11.00;;;0;
    ...    4
    ...    --exclude-instance=Database
    ...    OK: 306.00 total dead locks/s | 'total#mssql.deadlocks.count'=306.00;;;0; 'AllocUnit#mssql.deadlocks.count'=0.00;;;0; 'Application#mssql.deadlocks.count'=0.00;;;0; 'Extent#mssql.deadlocks.count'=0.00;;;0; 'File#mssql.deadlocks.count'=141.00;;;0; 'HoBT#mssql.deadlocks.count'=0.00;;;0; 'Key#mssql.deadlocks.count'=101.00;;;0; 'Metadata#mssql.deadlocks.count'=38.00;;;0; 'OIB#mssql.deadlocks.count'=0.00;;;0; 'Object#mssql.deadlocks.count'=2.00;;;0; 'Page#mssql.deadlocks.count'=0.00;;;0; 'RID#mssql.deadlocks.count'=24.00;;;0; 'RowGroup#mssql.deadlocks.count'=0.00;;;0; 'Xact#mssql.deadlocks.count'=0.00;;;0;
    ...    5
    ...    --include-instance=Database --warning-deadlocks-by-instance=1
    ...    WARNING: 11.00 dead locks/s | 'total#mssql.deadlocks.count'=11.00;;;0; 'Database#mssql.deadlocks.count'=11.00;0:1;;0;
    ...    6
    ...    --include-instance=Database --critical-deadlocks-by-instance=1
    ...    CRITICAL: 11.00 dead locks/s | 'total#mssql.deadlocks.count'=11.00;;;0; 'Database#mssql.deadlocks.count'=11.00;;0:1;0;
    ...    7
    ...    --include-instance=unexisting
    ...    UNKNOWN: No locks counter found with given filters
    ...    8
    ...    --include-instance=Database --warning-deadlocks=1
    ...    WARNING: 11.00 total dead locks/s | 'total#mssql.deadlocks.count'=11.00;0:1;;0; 'Database#mssql.deadlocks.count'=11.00;;;0;
    ...    9
    ...    --include-instance=Database --critical-deadlocks=1
    ...    CRITICAL: 11.00 total dead locks/s | 'total#mssql.deadlocks.count'=11.00;;0:1;0; 'Database#mssql.deadlocks.count'=11.00;;;0;
