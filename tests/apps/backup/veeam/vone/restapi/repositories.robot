*** Settings ***
Documentation       apps::backup::veeam::vone::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}vone.mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...         --plugin=apps::backup::veeam::vone::restapi::plugin
...         --mode=repositories
...         --hostname=${HOSTNAME}
...         --port=${APIPORT}
...         --proto=http
...         --api-username=UsErNaMe
...         --api-password=P@s$W0Rd


*** Test Cases ***
Repositories ${tc}
    [Tags]    apps    backup    restapi
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
    ...    OK: All repositories are ok | 'repositories.detected.count'=3;;;0; 'fake-01#repository.state.count'=1;;;0; 'fake-01#repository.space.usage.bytes'=-12201897B;;;0;12345 'fake-01#repository.space.free.bytes'=12214242B;;;0;12345 'fake-01#repository.space.usage.percentage'=-98840.80%;;;0;100 'fake-02#repository.state.count'=1;;;0; 'fake-02#repository.space.usage.bytes'=1313B;;;0;123434 'fake-02#repository.space.free.bytes'=122121B;;;0;123434 'fake-02#repository.space.usage.percentage'=1.06%;;;0;100 'fake-03#repository.state.count'=1;;;0; 'fake-03#repository.space.usage.bytes'=111111B;;;0;123456 'fake-03#repository.space.free.bytes'=12345B;;;0;123456 'fake-03#repository.space.usage.percentage'=90.00%;;;0;100
    ...    2
    ...    --filter-uid=7890-123456
    ...    OK: repository 'fake-02' [type: MicrosoftWindows] state: ok - space usage total: 120.54 KB used: 1.28 KB (1.06%) free: 119.26 KB (98.94%) | 'repositories.detected.count'=1;;;0; 'fake-02#repository.state.count'=1;;;0; 'fake-02#repository.space.usage.bytes'=1313B;;;0;123434 'fake-02#repository.space.free.bytes'=122121B;;;0;123434 'fake-02#repository.space.usage.percentage'=1.06%;;;0;100
    ...    3
    ...    --filter-name=fake-03
    ...    OK: repository 'fake-03' [type: LinuxHardened] state: ok - space usage total: 120.56 KB used: 108.51 KB (90.00%) free: 12.06 KB (10.00%) | 'repositories.detected.count'=1;;;0; 'fake-03#repository.state.count'=1;;;0; 'fake-03#repository.space.usage.bytes'=111111B;;;0;123456 'fake-03#repository.space.free.bytes'=12345B;;;0;123456 'fake-03#repository.space.usage.percentage'=90.00%;;;0;100
    ...    4
    ...    --unknown-repository-status='%\\\{state\\\} =~ /ok/'
    ...    UNKNOWN: repository 'fake-01' [type: LinuxHardened] state: ok - repository 'fake-02' [type: MicrosoftWindows] state: ok - repository 'fake-03' [type: LinuxHardened] state: ok | 'repositories.detected.count'=3;;;0; 'fake-01#repository.state.count'=1;;;0; 'fake-01#repository.space.usage.bytes'=-12201897B;;;0;12345 'fake-01#repository.space.free.bytes'=12214242B;;;0;12345 'fake-01#repository.space.usage.percentage'=-98840.80%;;;0;100 'fake-02#repository.state.count'=1;;;0; 'fake-02#repository.space.usage.bytes'=1313B;;;0;123434 'fake-02#repository.space.free.bytes'=122121B;;;0;123434 'fake-02#repository.space.usage.percentage'=1.06%;;;0;100 'fake-03#repository.state.count'=1;;;0; 'fake-03#repository.space.usage.bytes'=111111B;;;0;123456 'fake-03#repository.space.free.bytes'=12345B;;;0;123456 'fake-03#repository.space.usage.percentage'=90.00%;;;0;100
    ...    5
    ...    --warning-repository-status='%\\\{state\\\} =~ /ok/'
    ...    WARNING: repository 'fake-01' [type: LinuxHardened] state: ok - repository 'fake-02' [type: MicrosoftWindows] state: ok - repository 'fake-03' [type: LinuxHardened] state: ok | 'repositories.detected.count'=3;;;0; 'fake-01#repository.state.count'=1;;;0; 'fake-01#repository.space.usage.bytes'=-12201897B;;;0;12345 'fake-01#repository.space.free.bytes'=12214242B;;;0;12345 'fake-01#repository.space.usage.percentage'=-98840.80%;;;0;100 'fake-02#repository.state.count'=1;;;0; 'fake-02#repository.space.usage.bytes'=1313B;;;0;123434 'fake-02#repository.space.free.bytes'=122121B;;;0;123434 'fake-02#repository.space.usage.percentage'=1.06%;;;0;100 'fake-03#repository.state.count'=1;;;0; 'fake-03#repository.space.usage.bytes'=111111B;;;0;123456 'fake-03#repository.space.free.bytes'=12345B;;;0;123456 'fake-03#repository.space.usage.percentage'=90.00%;;;0;100
    ...    6
    ...    --critical-repository-status='%\\\{state\\\} =~ /ok/'
    ...    CRITICAL: repository 'fake-01' [type: LinuxHardened] state: ok - repository 'fake-02' [type: MicrosoftWindows] state: ok - repository 'fake-03' [type: LinuxHardened] state: ok | 'repositories.detected.count'=3;;;0; 'fake-01#repository.state.count'=1;;;0; 'fake-01#repository.space.usage.bytes'=-12201897B;;;0;12345 'fake-01#repository.space.free.bytes'=12214242B;;;0;12345 'fake-01#repository.space.usage.percentage'=-98840.80%;;;0;100 'fake-02#repository.state.count'=1;;;0; 'fake-02#repository.space.usage.bytes'=1313B;;;0;123434 'fake-02#repository.space.free.bytes'=122121B;;;0;123434 'fake-02#repository.space.usage.percentage'=1.06%;;;0;100 'fake-03#repository.state.count'=1;;;0; 'fake-03#repository.space.usage.bytes'=111111B;;;0;123456 'fake-03#repository.space.free.bytes'=12345B;;;0;123456 'fake-03#repository.space.usage.percentage'=90.00%;;;0;100
    ...    7
    ...    --warning-repositories-detected=:1
    ...    WARNING: Number of repositories detected: 3 | 'repositories.detected.count'=3;0:1;;0; 'fake-01#repository.state.count'=1;;;0; 'fake-01#repository.space.usage.bytes'=-12201897B;;;0;12345 'fake-01#repository.space.free.bytes'=12214242B;;;0;12345 'fake-01#repository.space.usage.percentage'=-98840.80%;;;0;100 'fake-02#repository.state.count'=1;;;0; 'fake-02#repository.space.usage.bytes'=1313B;;;0;123434 'fake-02#repository.space.free.bytes'=122121B;;;0;123434 'fake-02#repository.space.usage.percentage'=1.06%;;;0;100 'fake-03#repository.state.count'=1;;;0; 'fake-03#repository.space.usage.bytes'=111111B;;;0;123456 'fake-03#repository.space.free.bytes'=12345B;;;0;123456 'fake-03#repository.space.usage.percentage'=90.00%;;;0;100
    ...    8
    ...    --critical-repositories-detected=:1
    ...    CRITICAL: Number of repositories detected: 3 | 'repositories.detected.count'=3;;0:1;0; 'fake-01#repository.state.count'=1;;;0; 'fake-01#repository.space.usage.bytes'=-12201897B;;;0;12345 'fake-01#repository.space.free.bytes'=12214242B;;;0;12345 'fake-01#repository.space.usage.percentage'=-98840.80%;;;0;100 'fake-02#repository.state.count'=1;;;0; 'fake-02#repository.space.usage.bytes'=1313B;;;0;123434 'fake-02#repository.space.free.bytes'=122121B;;;0;123434 'fake-02#repository.space.usage.percentage'=1.06%;;;0;100 'fake-03#repository.state.count'=1;;;0; 'fake-03#repository.space.usage.bytes'=111111B;;;0;123456 'fake-03#repository.space.free.bytes'=12345B;;;0;123456 'fake-03#repository.space.usage.percentage'=90.00%;;;0;100
    ...    9
    ...    --warning-space-usage=:1
    ...    WARNING: repository 'fake-01' [type: LinuxHardened] space usage total: 12.06 KB used: -11.64 MB (-98840.80%) free: 11.65 MB (98940.80%) - repository 'fake-02' [type: MicrosoftWindows] space usage total: 120.54 KB used: 1.28 KB (1.06%) free: 119.26 KB (98.94%) - repository 'fake-03' [type: LinuxHardened] space usage total: 120.56 KB used: 108.51 KB (90.00%) free: 12.06 KB (10.00%) | 'repositories.detected.count'=3;;;0; 'fake-01#repository.state.count'=1;;;0; 'fake-01#repository.space.usage.bytes'=-12201897B;0:1;;0;12345 'fake-01#repository.space.free.bytes'=12214242B;;;0;12345 'fake-01#repository.space.usage.percentage'=-98840.80%;;;0;100 'fake-02#repository.state.count'=1;;;0; 'fake-02#repository.space.usage.bytes'=1313B;0:1;;0;123434 'fake-02#repository.space.free.bytes'=122121B;;;0;123434 'fake-02#repository.space.usage.percentage'=1.06%;;;0;100 'fake-03#repository.state.count'=1;;;0; 'fake-03#repository.space.usage.bytes'=111111B;0:1;;0;123456 'fake-03#repository.space.free.bytes'=12345B;;;0;123456 'fake-03#repository.space.usage.percentage'=90.00%;;;0;100
    ...    10
    ...    --critical-space-usage=:1
    ...    CRITICAL: repository 'fake-01' [type: LinuxHardened] space usage total: 12.06 KB used: -11.64 MB (-98840.80%) free: 11.65 MB (98940.80%) - repository 'fake-02' [type: MicrosoftWindows] space usage total: 120.54 KB used: 1.28 KB (1.06%) free: 119.26 KB (98.94%) - repository 'fake-03' [type: LinuxHardened] space usage total: 120.56 KB used: 108.51 KB (90.00%) free: 12.06 KB (10.00%) | 'repositories.detected.count'=3;;;0; 'fake-01#repository.state.count'=1;;;0; 'fake-01#repository.space.usage.bytes'=-12201897B;;0:1;0;12345 'fake-01#repository.space.free.bytes'=12214242B;;;0;12345 'fake-01#repository.space.usage.percentage'=-98840.80%;;;0;100 'fake-02#repository.state.count'=1;;;0; 'fake-02#repository.space.usage.bytes'=1313B;;0:1;0;123434 'fake-02#repository.space.free.bytes'=122121B;;;0;123434 'fake-02#repository.space.usage.percentage'=1.06%;;;0;100 'fake-03#repository.state.count'=1;;;0; 'fake-03#repository.space.usage.bytes'=111111B;;0:1;0;123456 'fake-03#repository.space.free.bytes'=12345B;;;0;123456 'fake-03#repository.space.usage.percentage'=90.00%;;;0;100
    ...    11
    ...    --warning-space-usage-free=:1
    ...    WARNING: repository 'fake-01' [type: LinuxHardened] space usage total: 12.06 KB used: -11.64 MB (-98840.80%) free: 11.65 MB (98940.80%) - repository 'fake-02' [type: MicrosoftWindows] space usage total: 120.54 KB used: 1.28 KB (1.06%) free: 119.26 KB (98.94%) - repository 'fake-03' [type: LinuxHardened] space usage total: 120.56 KB used: 108.51 KB (90.00%) free: 12.06 KB (10.00%) | 'repositories.detected.count'=3;;;0; 'fake-01#repository.state.count'=1;;;0; 'fake-01#repository.space.usage.bytes'=-12201897B;;;0;12345 'fake-01#repository.space.free.bytes'=12214242B;0:1;;0;12345 'fake-01#repository.space.usage.percentage'=-98840.80%;;;0;100 'fake-02#repository.state.count'=1;;;0; 'fake-02#repository.space.usage.bytes'=1313B;;;0;123434 'fake-02#repository.space.free.bytes'=122121B;0:1;;0;123434 'fake-02#repository.space.usage.percentage'=1.06%;;;0;100 'fake-03#repository.state.count'=1;;;0; 'fake-03#repository.space.usage.bytes'=111111B;;;0;123456 'fake-03#repository.space.free.bytes'=12345B;0:1;;0;123456 'fake-03#repository.space.usage.percentage'=90.00%;;;0;100
    ...    12
    ...    --critical-space-usage-free=:1
    ...    CRITICAL: repository 'fake-01' [type: LinuxHardened] space usage total: 12.06 KB used: -11.64 MB (-98840.80%) free: 11.65 MB (98940.80%) - repository 'fake-02' [type: MicrosoftWindows] space usage total: 120.54 KB used: 1.28 KB (1.06%) free: 119.26 KB (98.94%) - repository 'fake-03' [type: LinuxHardened] space usage total: 120.56 KB used: 108.51 KB (90.00%) free: 12.06 KB (10.00%) | 'repositories.detected.count'=3;;;0; 'fake-01#repository.state.count'=1;;;0; 'fake-01#repository.space.usage.bytes'=-12201897B;;;0;12345 'fake-01#repository.space.free.bytes'=12214242B;;0:1;0;12345 'fake-01#repository.space.usage.percentage'=-98840.80%;;;0;100 'fake-02#repository.state.count'=1;;;0; 'fake-02#repository.space.usage.bytes'=1313B;;;0;123434 'fake-02#repository.space.free.bytes'=122121B;;0:1;0;123434 'fake-02#repository.space.usage.percentage'=1.06%;;;0;100 'fake-03#repository.state.count'=1;;;0; 'fake-03#repository.space.usage.bytes'=111111B;;;0;123456 'fake-03#repository.space.free.bytes'=12345B;;0:1;0;123456 'fake-03#repository.space.usage.percentage'=90.00%;;;0;100
    ...    13
    ...    --warning-space-usage-prct=:1
    ...    WARNING: repository 'fake-01' [type: LinuxHardened] space usage total: 12.06 KB used: -11.64 MB (-98840.80%) free: 11.65 MB (98940.80%) - repository 'fake-02' [type: MicrosoftWindows] space usage total: 120.54 KB used: 1.28 KB (1.06%) free: 119.26 KB (98.94%) - repository 'fake-03' [type: LinuxHardened] space usage total: 120.56 KB used: 108.51 KB (90.00%) free: 12.06 KB (10.00%) | 'repositories.detected.count'=3;;;0; 'fake-01#repository.state.count'=1;;;0; 'fake-01#repository.space.usage.bytes'=-12201897B;;;0;12345 'fake-01#repository.space.free.bytes'=12214242B;;;0;12345 'fake-01#repository.space.usage.percentage'=-98840.80%;0:1;;0;100 'fake-02#repository.state.count'=1;;;0; 'fake-02#repository.space.usage.bytes'=1313B;;;0;123434 'fake-02#repository.space.free.bytes'=122121B;;;0;123434 'fake-02#repository.space.usage.percentage'=1.06%;0:1;;0;100 'fake-03#repository.state.count'=1;;;0; 'fake-03#repository.space.usage.bytes'=111111B;;;0;123456 'fake-03#repository.space.free.bytes'=12345B;;;0;123456 'fake-03#repository.space.usage.percentage'=90.00%;0:1;;0;100
    ...    14
    ...    --critical-space-usage-prct=:1
    ...    CRITICAL: repository 'fake-01' [type: LinuxHardened] space usage total: 12.06 KB used: -11.64 MB (-98840.80%) free: 11.65 MB (98940.80%) - repository 'fake-02' [type: MicrosoftWindows] space usage total: 120.54 KB used: 1.28 KB (1.06%) free: 119.26 KB (98.94%) - repository 'fake-03' [type: LinuxHardened] space usage total: 120.56 KB used: 108.51 KB (90.00%) free: 12.06 KB (10.00%) | 'repositories.detected.count'=3;;;0; 'fake-01#repository.state.count'=1;;;0; 'fake-01#repository.space.usage.bytes'=-12201897B;;;0;12345 'fake-01#repository.space.free.bytes'=12214242B;;;0;12345 'fake-01#repository.space.usage.percentage'=-98840.80%;;0:1;0;100 'fake-02#repository.state.count'=1;;;0; 'fake-02#repository.space.usage.bytes'=1313B;;;0;123434 'fake-02#repository.space.free.bytes'=122121B;;;0;123434 'fake-02#repository.space.usage.percentage'=1.06%;;0:1;0;100 'fake-03#repository.state.count'=1;;;0; 'fake-03#repository.space.usage.bytes'=111111B;;;0;123456 'fake-03#repository.space.free.bytes'=12345B;;;0;123456 'fake-03#repository.space.usage.percentage'=90.00%;;0:1;0;100
    ...    15
    ...    --disco-format
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <element>uid</element> <element>name</element> <element>type</element> <element>state</element> </data>
    ...    16
    ...    --disco-show --filter-name=fake-03
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label name="fake-03" state="ok" type="LinuxHardened" uid="7654322-788999"/> </data>
