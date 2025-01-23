*** Settings ***
Documentation       Netapp Ontap Restapi Volumes plugin

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
...                 --mode=volumes


*** Test Cases ***
Volumes ${tc}
    [Tags]    storage    netapp    ontapp    api    volumes    mockoon   
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extra_options                                                      expected_result    --
            ...       1   ${EMPTY}                                                           OK: Volume 'svm1:volume1' state: online, space usage total: 4.00 TB used: 2.82 TB (90.42%) free: 392.42 GB (9.58%), logical-usage : skipped (no value(s)), logical-usage-free : skipped (no value(s)), logical-usage-prct : skipped (no value(s)), read : skipped (no value(s)), write : skipped (no value(s)), other : skipped (no value(s)), total : skipped (no value(s)), read-iops : skipped (no value(s)), write-iops : skipped (no value(s)), other-iops : skipped (no value(s)), total-iops : skipped (no value(s)), read-latency : skipped (no value(s)), write-latency : skipped (no value(s)), other-latency : skipped (no value(s)), total-latency : skipped (no value(s)) | 'svm1:volume1#volume.space.usage.bytes'=3097083330560B;;;0;4398046511104 'svm1:volume1#volume.space.free.bytes'=421353881600B;;;0;4398046511104 'svm1:volume1#volume.space.usage.percentage'=90.42%;;;0;100
            ...       2   --filter-volume-name='volume1'                                     OK: Volume 'svm1:volume1' state: online, space usage total: 4.00 TB used: 2.82 TB (90.42%) free: 392.42 GB (9.58%), logical space usage total: 3.20 TB used: 2.88 TB (90.00%) free: 325.03 GB (10.00%), read : skipped (no value(s)), write : skipped (no value(s)), other : skipped (no value(s)), total : skipped (no value(s)), read-iops : skipped (no value(s)), write-iops : skipped (no value(s)), other-iops : skipped (no value(s)), total-iops : skipped (no value(s)), read-latency : skipped (no value(s)), write-latency : skipped (no value(s)), other-latency : skipped (no value(s)), total-latency : skipped (no value(s)) | 'svm1:volume1#volume.space.usage.bytes'=3097083330560B;;;0;4398046511104 'svm1:volume1#volume.space.free.bytes'=421353881600B;;;0;4398046511104 'svm1:volume1#volume.space.usage.percentage'=90.42%;;;0;100 'svm1:volume1#volume.logicalspace.usage.bytes'=3169438617600B;;;0;3518437212160 'svm1:volume1#volume.logicalspace.free.bytes'=348998594560B;;;0;3518437212160 'svm1:volume1#volume.logicalspace.usage.percentage'=90.00%;;;0;100
            ...       3   --filter-name='volume1'                                            OK: Volume 'svm1:volume1' state: online, space usage total: 4.00 TB used: 2.82 TB (90.42%) free: 392.42 GB (9.58%), logical-usage : skipped (no value(s)), logical-usage-free : skipped (no value(s)), logical-usage-prct : skipped (no value(s)), read : skipped (no value(s)), write : skipped (no value(s)), other : skipped (no value(s)), total : skipped (no value(s)), read-iops : skipped (no value(s)), write-iops : skipped (no value(s)), other-iops : skipped (no value(s)), total-iops : skipped (no value(s)), read-latency : skipped (no value(s)), write-latency : skipped (no value(s)), other-latency : skipped (no value(s)), total-latency : skipped (no value(s)) | 'svm1:volume1#volume.space.usage.bytes'=3097083330560B;;;0;4398046511104 'svm1:volume1#volume.space.free.bytes'=421353881600B;;;0;4398046511104 'svm1:volume1#volume.space.usage.percentage'=90.42%;;;0;100
            ...       4   --warning-status='\\\%{state} !~ /notonline/i'                     WARNING: Volume 'svm1:volume1' state: online | 'svm1:volume1#volume.space.usage.bytes'=3097083330560B;;;0;4398046511104 'svm1:volume1#volume.space.free.bytes'=421353881600B;;;0;4398046511104 'svm1:volume1#volume.space.usage.percentage'=90.42%;;;0;100
            ...       5   --critical-status='\\\%{state} !~ /notonline/i'                    CRITICAL: Volume 'svm1:volume1' state: online | 'svm1:volume1#volume.space.usage.bytes'=3097083330560B;;;0;4398046511104 'svm1:volume1#volume.space.free.bytes'=421353881600B;;;0;4398046511104 'svm1:volume1#volume.space.usage.percentage'=90.42%;;;0;100
            ...       6   --warning-usage-prct=50                                            WARNING: Volume 'svm1:volume1' space usage total: 4.00 TB used: 2.82 TB (90.42%) free: 392.42 GB (9.58%) | 'svm1:volume1#volume.space.usage.bytes'=3097083330560B;;;0;4398046511104 'svm1:volume1#volume.space.free.bytes'=421353881600B;;;0;4398046511104 'svm1:volume1#volume.space.usage.percentage'=90.42%;0:50;;0;100
            ...       7   --critical-usage-prct=50                                           CRITICAL: Volume 'svm1:volume1' space usage total: 4.00 TB used: 2.82 TB (90.42%) free: 392.42 GB (9.58%) | 'svm1:volume1#volume.space.usage.bytes'=3097083330560B;;;0;4398046511104 'svm1:volume1#volume.space.free.bytes'=421353881600B;;;0;4398046511104 'svm1:volume1#volume.space.usage.percentage'=90.42%;;0:50;0;100
            ...       8   --filter-volume-name='volume1' --warning-logical-usage-prct=50     WARNING: Volume 'svm1:volume1' logical space usage total: 3.20 TB used: 2.88 TB (90.00%) free: 325.03 GB (10.00%) | 'svm1:volume1#volume.space.usage.bytes'=3097083330560B;;;0;4398046511104 'svm1:volume1#volume.space.free.bytes'=421353881600B;;;0;4398046511104 'svm1:volume1#volume.space.usage.percentage'=90.42%;;;0;100 'svm1:volume1#volume.logicalspace.usage.bytes'=3169438617600B;;;0;3518437212160 'svm1:volume1#volume.logicalspace.free.bytes'=348998594560B;;;0;3518437212160 'svm1:volume1#volume.logicalspace.usage.percentage'=90.00%;0:50;;0;100
            ...       9   --filter-volume-name='volume1' --critical-logical-usage-prct=50    CRITICAL: Volume 'svm1:volume1' logical space usage total: 3.20 TB used: 2.88 TB (90.00%) free: 325.03 GB (10.00%) | 'svm1:volume1#volume.space.usage.bytes'=3097083330560B;;;0;4398046511104 'svm1:volume1#volume.space.free.bytes'=421353881600B;;;0;4398046511104 'svm1:volume1#volume.space.usage.percentage'=90.42%;;;0;100 'svm1:volume1#volume.logicalspace.usage.bytes'=3169438617600B;;;0;3518437212160 'svm1:volume1#volume.logicalspace.free.bytes'=348998594560B;;;0;3518437212160 'svm1:volume1#volume.logicalspace.usage.percentage'=90.00%;;0:50;0;100 
