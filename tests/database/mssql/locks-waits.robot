*** Settings ***
Documentation       In this robot file, before each test case, we restore the statefile to an initial state and age, and
...                 we fix the time so that the age of the data is always 1 minute. Every value, calculated as a per_minute
...                 average is consequently predictible.

Resource            ${CURDIR}${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${INJECT_PERL}      -MDBD::Sybase -Mfixed_date -I${CURDIR}
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=database::mssql::plugin
...                 --mode=locks-waits
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --username=1
...                 --password=1


*** Test Cases ***
Locks-waits ${tc}
    [Tags]    database    mssql
    [Setup]    Ctn Locks Waits Test Setup

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
    ...    OK: 124.00 total locks waits/min | 'total#mssql.lockswaits.perminute'=124.00;;;0; 'AllocUnit#mssql.lockswaits.perminute'=8.00;;;0; 'Application#mssql.lockswaits.perminute'=1.00;;;0; 'Database#mssql.lockswaits.perminute'=5.00;;;0; 'Extent#mssql.lockswaits.perminute'=3.00;;;0; 'File#mssql.lockswaits.perminute'=30.00;;;0; 'HoBT#mssql.lockswaits.perminute'=2.00;;;0; 'Key#mssql.lockswaits.perminute'=51.00;;;0; 'Metadata#mssql.lockswaits.perminute'=7.00;;;0; 'OIB#mssql.lockswaits.perminute'=4.00;;;0; 'Object#mssql.lockswaits.perminute'=1.00;;;0; 'Page#mssql.lockswaits.perminute'=1.00;;;0; 'RID#mssql.lockswaits.perminute'=4.00;;;0; 'RowGroup#mssql.lockswaits.perminute'=4.00;;;0; 'Xact#mssql.lockswaits.perminute'=3.00;;;0;
    ...    2
    ...    --filter-database=Database
    ...    OK: 45.00 total locks waits/min - instance Database: 5.00 locks waits/min | 'total#mssql.lockswaits.perminute'=45.00;;;0; 'Database#mssql.lockswaits.perminute'=5.00;;;0;
    ...    3
    ...    --include-instance=Database
    ...    OK: 45.00 total locks waits/min - instance Database: 5.00 locks waits/min | 'total#mssql.lockswaits.perminute'=45.00;;;0; 'Database#mssql.lockswaits.perminute'=5.00;;;0;
    ...    4
    ...    --exclude-instance=Database
    ...    OK: 79.00 total locks waits/min | 'total#mssql.lockswaits.perminute'=79.00;;;0; 'AllocUnit#mssql.lockswaits.perminute'=8.00;;;0; 'Application#mssql.lockswaits.perminute'=1.00;;;0; 'Extent#mssql.lockswaits.perminute'=3.00;;;0; 'File#mssql.lockswaits.perminute'=30.00;;;0; 'HoBT#mssql.lockswaits.perminute'=2.00;;;0; 'Key#mssql.lockswaits.perminute'=51.00;;;0; 'Metadata#mssql.lockswaits.perminute'=7.00;;;0; 'OIB#mssql.lockswaits.perminute'=4.00;;;0; 'Object#mssql.lockswaits.perminute'=1.00;;;0; 'Page#mssql.lockswaits.perminute'=1.00;;;0; 'RID#mssql.lockswaits.perminute'=4.00;;;0; 'RowGroup#mssql.lockswaits.perminute'=4.00;;;0; 'Xact#mssql.lockswaits.perminute'=3.00;;;0;
    ...    5
    ...    --include-instance=Database --warning-lockswaits-by-instance=1
    ...    WARNING: instance Database: 5.00 locks waits/min | 'total#mssql.lockswaits.perminute'=45.00;;;0; 'Database#mssql.lockswaits.perminute'=5.00;0:1;;0;
    ...    6
    ...    --include-instance=Database --critical-lockswaits-by-instance=1
    ...    CRITICAL: instance Database: 5.00 locks waits/min | 'total#mssql.lockswaits.perminute'=45.00;;;0; 'Database#mssql.lockswaits.perminute'=5.00;;0:1;0;
    ...    7
    ...    --include-instance=unexisting
    ...    UNKNOWN: No locks waits counter found with given filters
    ...    8
    ...    --include-instance=Database --warning-lockswaits=40
    ...    WARNING: 45.00 total locks waits/min | 'total#mssql.lockswaits.perminute'=45.00;0:40;;0; 'Database#mssql.lockswaits.perminute'=5.00;;;0;
    ...    9
    ...    --include-instance=Database --critical-lockswaits=40
    ...    CRITICAL: 45.00 total locks waits/min | 'total#mssql.lockswaits.perminute'=45.00;;0:40;0; 'Database#mssql.lockswaits.perminute'=5.00;;;0;


*** Keywords ***
Ctn Locks Waits Test Setup
    @{statefiles}=    List Files In Directory    ${CURDIR}${/}statefiles    mssql_locks-waits_*
    FOR    ${statefile}    IN    @{statefiles}
        Copy File    ${CURDIR}${/}statefiles${/}${statefile}    ${/}var${/}lib${/}centreon${/}centplugins${/}
    END
