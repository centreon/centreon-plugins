*** Settings ***
Documentation       apps::backup::rubrik::graphql::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}rubrik-mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::backup::rubrik::graphql::plugin
...                 --mode=storage
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --service-account=XXX
...                 --secret=XXX


*** Test Cases ***
Storage ${tc}
    [Tags]    apps    backup    graphql
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All storage are ok | 'RBKE-VI#storage.space.usage.bytes'=573357998080B;;;0;2070812979200 'RBKE-VI#storage.space.free.bytes'=1497454981120B;;;0;2070812979200 'RBKE-VI#storage.space.usage.percentage'=27.69%;;;0;100 'RBKE-VI#storage.average.daily.growth.bytes'=1253542206B;;;; 'RBKE-VI#storage.full.remaining.days.count'=1194d;;;0; 'TRBKE-IN#storage.space.usage.bytes'=12865716224B;;;0;1034222690304 'TRBKE-IN#storage.space.free.bytes'=1021356974080B;;;0;1034222690304 'TRBKE-IN#storage.space.usage.percentage'=1.24%;;;0;100 'TRBKE-IN#storage.average.daily.growth.bytes'=-917407B;;;; 'TRBKE-IN#storage.full.remaining.days.count'=1826d;;;0;
    ...    2
    ...    --start-time=2020-01-01 --end-time=2030-02-02
    ...    OK: All storage are ok | 'RBKE-VI#storage.space.usage.bytes'=573357998080B;;;0;2070812979200 'RBKE-VI#storage.space.free.bytes'=1497454981120B;;;0;2070812979200 'RBKE-VI#storage.space.usage.percentage'=27.69%;;;0;100 'RBKE-VI#storage.average.daily.growth.bytes'=1253542206B;;;; 'RBKE-VI#storage.full.remaining.days.count'=1194d;;;0; 'TRBKE-IN#storage.space.usage.bytes'=12865716224B;;;0;1034222690304 'TRBKE-IN#storage.space.free.bytes'=1021356974080B;;;0;1034222690304 'TRBKE-IN#storage.space.usage.percentage'=1.24%;;;0;100 'TRBKE-IN#storage.average.daily.growth.bytes'=-917407B;;;; 'TRBKE-IN#storage.full.remaining.days.count'=1826d;;;0;
    ...    3
    ...    --last=99999m
    ...    OK: All storage are ok | 'RBKE-VI#storage.space.usage.bytes'=573357998080B;;;0;2070812979200 'RBKE-VI#storage.space.free.bytes'=1497454981120B;;;0;2070812979200 'RBKE-VI#storage.space.usage.percentage'=27.69%;;;0;100 'RBKE-VI#storage.average.daily.growth.bytes'=1253542206B;;;; 'RBKE-VI#storage.full.remaining.days.count'=1194d;;;0; 'TRBKE-IN#storage.space.usage.bytes'=12865716224B;;;0;1034222690304 'TRBKE-IN#storage.space.free.bytes'=1021356974080B;;;0;1034222690304 'TRBKE-IN#storage.space.usage.percentage'=1.24%;;;0;100 'TRBKE-IN#storage.average.daily.growth.bytes'=-917407B;;;; 'TRBKE-IN#storage.full.remaining.days.count'=1826d;;;0;
    ...    4
    ...    --warning-usage=1
    ...    WARNING: Storage for cluster 'RBKE-VI' space usage total: 1.88 TB used: 533.98 GB (27.69%) free: 1.36 TB (72.31%) - Storage for cluster 'TRBKE-IN' space usage total: 963.19 GB used: 11.98 GB (1.24%) free: 951.21 GB (98.76%) | 'RBKE-VI#storage.space.usage.bytes'=573357998080B;0:1;;0;2070812979200 'RBKE-VI#storage.space.free.bytes'=1497454981120B;;;0;2070812979200 'RBKE-VI#storage.space.usage.percentage'=27.69%;;;0;100 'RBKE-VI#storage.average.daily.growth.bytes'=1253542206B;;;; 'RBKE-VI#storage.full.remaining.days.count'=1194d;;;0; 'TRBKE-IN#storage.space.usage.bytes'=12865716224B;0:1;;0;1034222690304 'TRBKE-IN#storage.space.free.bytes'=1021356974080B;;;0;1034222690304 'TRBKE-IN#storage.space.usage.percentage'=1.24%;;;0;100 'TRBKE-IN#storage.average.daily.growth.bytes'=-917407B;;;; 'TRBKE-IN#storage.full.remaining.days.count'=1826d;;;0;
    ...    5
    ...    --critical-usage=1
    ...    CRITICAL: Storage for cluster 'RBKE-VI' space usage total: 1.88 TB used: 533.98 GB (27.69%) free: 1.36 TB (72.31%) - Storage for cluster 'TRBKE-IN' space usage total: 963.19 GB used: 11.98 GB (1.24%) free: 951.21 GB (98.76%) | 'RBKE-VI#storage.space.usage.bytes'=573357998080B;;0:1;0;2070812979200 'RBKE-VI#storage.space.free.bytes'=1497454981120B;;;0;2070812979200 'RBKE-VI#storage.space.usage.percentage'=27.69%;;;0;100 'RBKE-VI#storage.average.daily.growth.bytes'=1253542206B;;;; 'RBKE-VI#storage.full.remaining.days.count'=1194d;;;0; 'TRBKE-IN#storage.space.usage.bytes'=12865716224B;;0:1;0;1034222690304 'TRBKE-IN#storage.space.free.bytes'=1021356974080B;;;0;1034222690304 'TRBKE-IN#storage.space.usage.percentage'=1.24%;;;0;100 'TRBKE-IN#storage.average.daily.growth.bytes'=-917407B;;;; 'TRBKE-IN#storage.full.remaining.days.count'=1826d;;;0;
    ...    6
    ...    --warning-usage-free=1
    ...    WARNING: Storage for cluster 'RBKE-VI' space usage total: 1.88 TB used: 533.98 GB (27.69%) free: 1.36 TB (72.31%) - Storage for cluster 'TRBKE-IN' space usage total: 963.19 GB used: 11.98 GB (1.24%) free: 951.21 GB (98.76%) | 'RBKE-VI#storage.space.usage.bytes'=573357998080B;;;0;2070812979200 'RBKE-VI#storage.space.free.bytes'=1497454981120B;0:1;;0;2070812979200 'RBKE-VI#storage.space.usage.percentage'=27.69%;;;0;100 'RBKE-VI#storage.average.daily.growth.bytes'=1253542206B;;;; 'RBKE-VI#storage.full.remaining.days.count'=1194d;;;0; 'TRBKE-IN#storage.space.usage.bytes'=12865716224B;;;0;1034222690304 'TRBKE-IN#storage.space.free.bytes'=1021356974080B;0:1;;0;1034222690304 'TRBKE-IN#storage.space.usage.percentage'=1.24%;;;0;100 'TRBKE-IN#storage.average.daily.growth.bytes'=-917407B;;;; 'TRBKE-IN#storage.full.remaining.days.count'=1826d;;;0;
    ...    7
    ...    --critical-usage-free=1
    ...    CRITICAL: Storage for cluster 'RBKE-VI' space usage total: 1.88 TB used: 533.98 GB (27.69%) free: 1.36 TB (72.31%) - Storage for cluster 'TRBKE-IN' space usage total: 963.19 GB used: 11.98 GB (1.24%) free: 951.21 GB (98.76%) | 'RBKE-VI#storage.space.usage.bytes'=573357998080B;;;0;2070812979200 'RBKE-VI#storage.space.free.bytes'=1497454981120B;;0:1;0;2070812979200 'RBKE-VI#storage.space.usage.percentage'=27.69%;;;0;100 'RBKE-VI#storage.average.daily.growth.bytes'=1253542206B;;;; 'RBKE-VI#storage.full.remaining.days.count'=1194d;;;0; 'TRBKE-IN#storage.space.usage.bytes'=12865716224B;;;0;1034222690304 'TRBKE-IN#storage.space.free.bytes'=1021356974080B;;0:1;0;1034222690304 'TRBKE-IN#storage.space.usage.percentage'=1.24%;;;0;100 'TRBKE-IN#storage.average.daily.growth.bytes'=-917407B;;;; 'TRBKE-IN#storage.full.remaining.days.count'=1826d;;;0;
    ...    8
    ...    --warning-usage-prct=1
    ...    WARNING: Storage for cluster 'RBKE-VI' space usage total: 1.88 TB used: 533.98 GB (27.69%) free: 1.36 TB (72.31%) - Storage for cluster 'TRBKE-IN' space usage total: 963.19 GB used: 11.98 GB (1.24%) free: 951.21 GB (98.76%) | 'RBKE-VI#storage.space.usage.bytes'=573357998080B;;;0;2070812979200 'RBKE-VI#storage.space.free.bytes'=1497454981120B;;;0;2070812979200 'RBKE-VI#storage.space.usage.percentage'=27.69%;0:1;;0;100 'RBKE-VI#storage.average.daily.growth.bytes'=1253542206B;;;; 'RBKE-VI#storage.full.remaining.days.count'=1194d;;;0; 'TRBKE-IN#storage.space.usage.bytes'=12865716224B;;;0;1034222690304 'TRBKE-IN#storage.space.free.bytes'=1021356974080B;;;0;1034222690304 'TRBKE-IN#storage.space.usage.percentage'=1.24%;0:1;;0;100 'TRBKE-IN#storage.average.daily.growth.bytes'=-917407B;;;; 'TRBKE-IN#storage.full.remaining.days.count'=1826d;;;0;
    ...    9
    ...    --critical-usage-prct=1
    ...    CRITICAL: Storage for cluster 'RBKE-VI' space usage total: 1.88 TB used: 533.98 GB (27.69%) free: 1.36 TB (72.31%) - Storage for cluster 'TRBKE-IN' space usage total: 963.19 GB used: 11.98 GB (1.24%) free: 951.21 GB (98.76%) | 'RBKE-VI#storage.space.usage.bytes'=573357998080B;;;0;2070812979200 'RBKE-VI#storage.space.free.bytes'=1497454981120B;;;0;2070812979200 'RBKE-VI#storage.space.usage.percentage'=27.69%;;0:1;0;100 'RBKE-VI#storage.average.daily.growth.bytes'=1253542206B;;;; 'RBKE-VI#storage.full.remaining.days.count'=1194d;;;0; 'TRBKE-IN#storage.space.usage.bytes'=12865716224B;;;0;1034222690304 'TRBKE-IN#storage.space.free.bytes'=1021356974080B;;;0;1034222690304 'TRBKE-IN#storage.space.usage.percentage'=1.24%;;0:1;0;100 'TRBKE-IN#storage.average.daily.growth.bytes'=-917407B;;;; 'TRBKE-IN#storage.full.remaining.days.count'=1826d;;;0;
    ...    10
    ...    --warning-average-daily-growth=1
    ...    WARNING: Storage for cluster 'RBKE-VI' average daily growth: 1.17 GB - Storage for cluster 'TRBKE-IN' average daily growth: -895.91 KB | 'RBKE-VI#storage.space.usage.bytes'=573357998080B;;;0;2070812979200 'RBKE-VI#storage.space.free.bytes'=1497454981120B;;;0;2070812979200 'RBKE-VI#storage.space.usage.percentage'=27.69%;;;0;100 'RBKE-VI#storage.average.daily.growth.bytes'=1253542206B;0:1;;; 'RBKE-VI#storage.full.remaining.days.count'=1194d;;;0; 'TRBKE-IN#storage.space.usage.bytes'=12865716224B;;;0;1034222690304 'TRBKE-IN#storage.space.free.bytes'=1021356974080B;;;0;1034222690304 'TRBKE-IN#storage.space.usage.percentage'=1.24%;;;0;100 'TRBKE-IN#storage.average.daily.growth.bytes'=-917407B;0:1;;; 'TRBKE-IN#storage.full.remaining.days.count'=1826d;;;0;
    ...    11
    ...    --critical-average-daily-growth=1
    ...    CRITICAL: Storage for cluster 'RBKE-VI' average daily growth: 1.17 GB - Storage for cluster 'TRBKE-IN' average daily growth: -895.91 KB | 'RBKE-VI#storage.space.usage.bytes'=573357998080B;;;0;2070812979200 'RBKE-VI#storage.space.free.bytes'=1497454981120B;;;0;2070812979200 'RBKE-VI#storage.space.usage.percentage'=27.69%;;;0;100 'RBKE-VI#storage.average.daily.growth.bytes'=1253542206B;;0:1;; 'RBKE-VI#storage.full.remaining.days.count'=1194d;;;0; 'TRBKE-IN#storage.space.usage.bytes'=12865716224B;;;0;1034222690304 'TRBKE-IN#storage.space.free.bytes'=1021356974080B;;;0;1034222690304 'TRBKE-IN#storage.space.usage.percentage'=1.24%;;;0;100 'TRBKE-IN#storage.average.daily.growth.bytes'=-917407B;;0:1;; 'TRBKE-IN#storage.full.remaining.days.count'=1826d;;;0;
    ...    12
    ...    --warning-full-remaining-days=1
    ...    WARNING: Storage for cluster 'RBKE-VI' remaining days before filled: 1194 - Storage for cluster 'TRBKE-IN' remaining days before filled: 1826 | 'RBKE-VI#storage.space.usage.bytes'=573357998080B;;;0;2070812979200 'RBKE-VI#storage.space.free.bytes'=1497454981120B;;;0;2070812979200 'RBKE-VI#storage.space.usage.percentage'=27.69%;;;0;100 'RBKE-VI#storage.average.daily.growth.bytes'=1253542206B;;;; 'RBKE-VI#storage.full.remaining.days.count'=1194d;0:1;;0; 'TRBKE-IN#storage.space.usage.bytes'=12865716224B;;;0;1034222690304 'TRBKE-IN#storage.space.free.bytes'=1021356974080B;;;0;1034222690304 'TRBKE-IN#storage.space.usage.percentage'=1.24%;;;0;100 'TRBKE-IN#storage.average.daily.growth.bytes'=-917407B;;;; 'TRBKE-IN#storage.full.remaining.days.count'=1826d;0:1;;0;
    ...    13
    ...    --critical-full-remaining-days=1
    ...    CRITICAL: Storage for cluster 'RBKE-VI' remaining days before filled: 1194 - Storage for cluster 'TRBKE-IN' remaining days before filled: 1826 | 'RBKE-VI#storage.space.usage.bytes'=573357998080B;;;0;2070812979200 'RBKE-VI#storage.space.free.bytes'=1497454981120B;;;0;2070812979200 'RBKE-VI#storage.space.usage.percentage'=27.69%;;;0;100 'RBKE-VI#storage.average.daily.growth.bytes'=1253542206B;;;; 'RBKE-VI#storage.full.remaining.days.count'=1194d;;0:1;0; 'TRBKE-IN#storage.space.usage.bytes'=12865716224B;;;0;1034222690304 'TRBKE-IN#storage.space.free.bytes'=1021356974080B;;;0;1034222690304 'TRBKE-IN#storage.space.usage.percentage'=1.24%;;;0;100 'TRBKE-IN#storage.average.daily.growth.bytes'=-917407B;;;; 'TRBKE-IN#storage.full.remaining.days.count'=1826d;;0:1;0;
    ...    14
    ...    --include-cluster=zzeeza-7ee1-1234-9876-aaaaaaaa
    ...    OK: Storage for cluster 'TRBKE-IN' space usage total: 963.19 GB used: 11.98 GB (1.24%) free: 951.21 GB (98.76%), average daily growth: -895.91 KB, remaining days before filled: 1826 | 'TRBKE-IN#storage.space.usage.bytes'=12865716224B;;;0;1034222690304 'TRBKE-IN#storage.space.free.bytes'=1021356974080B;;;0;1034222690304 'TRBKE-IN#storage.space.usage.percentage'=1.24%;;;0;100 'TRBKE-IN#storage.average.daily.growth.bytes'=-917407B;;;; 'TRBKE-IN#storage.full.remaining.days.count'=1826d;;;0;
    ...    15
    ...    --exclude-cluster=TRBKE-IN
    ...    OK: All storage are ok | 'RBKE-VI#storage.space.usage.bytes'=573357998080B;;;0;2070812979200 'RBKE-VI#storage.space.free.bytes'=1497454981120B;;;0;2070812979200 'RBKE-VI#storage.space.usage.percentage'=27.69%;;;0;100 'RBKE-VI#storage.average.daily.growth.bytes'=1253542206B;;;; 'RBKE-VI#storage.full.remaining.days.count'=1194d;;;0; 'TRBKE-IN#storage.space.usage.bytes'=12865716224B;;;0;1034222690304 'TRBKE-IN#storage.space.free.bytes'=1021356974080B;;;0;1034222690304 'TRBKE-IN#storage.space.usage.percentage'=1.24%;;;0;100 'TRBKE-IN#storage.average.daily.growth.bytes'=-917407B;;;; 'TRBKE-IN#storage.full.remaining.days.count'=1826d;;;0;
