*** Settings ***
Documentation       Netapp Ontap Restapi Quotas plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}netapp.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=storage::netapp::ontap::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-username=username
...                 --api-password=password
...                 --mode=quotas


*** Test Cases ***
Quotas ${tc}
    [Tags]    storage    netapp    ontapp    api    quotas    mockoon   
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:         tc  extra_options                            expected_result    --
            ...       1   ${EMPTY}                                 OK: Quota 'vserver:svm1,volume:volume1,qtree:qt1' total: 100.00 B used: 50.00 B (50.00%) free: 50.00 B (50.00%) | 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.usage.bytes'=50B;0:90;;0;100 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.free.bytes'=50B;;;0;100 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.usage.percentage'=50.00%;;;0;100
            ...       2   --warning-space-usage='1:1'              OK: Quota 'vserver:svm1,volume:volume1,qtree:qt1' total: 100.00 B used: 50.00 B (50.00%) free: 50.00 B (50.00%) | 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.usage.bytes'=50B;0:90;;0;100 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.free.bytes'=50B;;;0;100 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.usage.percentage'=50.00%;;;0;100
            ...       3   --critical-space-usage='1:1'             CRITICAL: Quota 'vserver:svm1,volume:volume1,qtree:qt1' total: 100.00 B used: 50.00 B (50.00%) free: 50.00 B (50.00%) | 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.usage.bytes'=50B;0:90;1:1;0;100 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.free.bytes'=50B;;;0;100 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.usage.percentage'=50.00%;;;0;100
            ...       4   --warning-space-usage-prct='1:1'         WARNING: Quota 'vserver:svm1,volume:volume1,qtree:qt1' total: 100.00 B used: 50.00 B (50.00%) free: 50.00 B (50.00%) | 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.usage.bytes'=50B;0:90;;0;100 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.free.bytes'=50B;;;0;100 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.usage.percentage'=50.00%;1:1;;0;100
            ...       5   --critical-space-usage-prct='1:1'        CRITICAL: Quota 'vserver:svm1,volume:volume1,qtree:qt1' total: 100.00 B used: 50.00 B (50.00%) free: 50.00 B (50.00%) | 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.usage.bytes'=50B;0:90;;0;100 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.free.bytes'=50B;;;0;100 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.usage.percentage'=50.00%;;1:1;0;100
            ...       6   --warning-space-usage-free='1:1'         WARNING: Quota 'vserver:svm1,volume:volume1,qtree:qt1' total: 100.00 B used: 50.00 B (50.00%) free: 50.00 B (50.00%) | 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.usage.bytes'=50B;0:90;;0;100 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.free.bytes'=50B;1:1;;0;100 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.usage.percentage'=50.00%;;;0;100
            ...       7   --critical-space-usage-free='1:1'        CRITICAL: Quota 'vserver:svm1,volume:volume1,qtree:qt1' total: 100.00 B used: 50.00 B (50.00%) free: 50.00 B (50.00%) | 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.usage.bytes'=50B;0:90;;0;100 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.free.bytes'=50B;;1:1;0;100 'vserver:svm1~volume:volume1~qtree:qt1#quota.space.usage.percentage'=50.00%;;;0;100
