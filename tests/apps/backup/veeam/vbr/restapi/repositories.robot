*** Settings ***
Documentation     apps::backup::veeam::vbr::restapi::plugin

Resource          ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Start Mockoon    ${MOCKOON_JSON}
Suite Teardown    Stop Mockoon
Test Timeout      120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}veeam-vbr.mockoon.json

${CMD}             ${CENTREON_PLUGINS}
...                --plugin=apps::backup::veeam::vbr::restapi::plugin
...                --mode=repositories
...                --http-peer-addr=${HOSTNAME}
...                --port=${APIPORT}
...                --proto=http
...                --api-username=username
...                --api-password=password


*** Test Cases ***
Repositories ${tc}
    [Tags]    apps    backup    veeam    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    --hostname=${hostname}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    hostname
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    vbr.example.com
    ...    ${EMPTY}
    ...    CRITICAL: repository 'Hardened Repository' [type: LinuxHardened] state: offline WARNING: repository 'Default Backup Repository' [type: WinLocal] state: outOfDate | 'repositories.detected.count'=5;;;0; 'Backup Repository 1#repository.space.usage.bytes'=87617332838B;;;0;321478302105 'Backup Repository 1#repository.space.free.bytes'=233860969267B;;;0;321478302105 'Backup Repository 1#repository.space.usage.percentage'=27.25%;;;0;100 'Default Backup Repository#repository.space.usage.bytes'=89120571392B;;;0;106729937305 'Default Backup Repository#repository.space.free.bytes'=17609365913B;;;0;106729937305 'Default Backup Repository#repository.space.usage.percentage'=83.50%;;;0;100 'Hardened Repository#repository.space.usage.bytes'=992137445376B;;;0;1099511627776 'Hardened Repository#repository.space.free.bytes'=107374182400B;;;0;1099511627776 'Hardened Repository#repository.space.usage.percentage'=90.23%;;;0;100 'Scale-out extent 1#repository.space.usage.bytes'=268435456000B;;;0;536870912000 'Scale-out extent 1#repository.space.free.bytes'=268435456000B;;;0;536870912000 'Scale-out extent 1#repository.space.usage.percentage'=50.00%;;;0;100
    ...    2
    ...    vbr.example.com
    ...    --exclude-extents
    ...    CRITICAL: repository 'Hardened Repository' [type: LinuxHardened] state: offline WARNING: repository 'Default Backup Repository' [type: WinLocal] state: outOfDate | 'repositories.detected.count'=4;;;0; 'Backup Repository 1#repository.space.usage.bytes'=87617332838B;;;0;321478302105 'Backup Repository 1#repository.space.free.bytes'=233860969267B;;;0;321478302105 'Backup Repository 1#repository.space.usage.percentage'=27.25%;;;0;100 'Default Backup Repository#repository.space.usage.bytes'=89120571392B;;;0;106729937305 'Default Backup Repository#repository.space.free.bytes'=17609365913B;;;0;106729937305 'Default Backup Repository#repository.space.usage.percentage'=83.50%;;;0;100 'Hardened Repository#repository.space.usage.bytes'=992137445376B;;;0;1099511627776 'Hardened Repository#repository.space.free.bytes'=107374182400B;;;0;1099511627776 'Hardened Repository#repository.space.usage.percentage'=90.23%;;;0;100
    ...    3
    ...    vbr.example.com
    ...    --include-type=Win --exclude-name=Default
    ...    OK: repository 'Backup Repository 1' [type: WinLocal] state: online - space usage total: 299.40 GB used: 81.60 GB (27.25%) free: 217.80 GB (72.75%) | 'repositories.detected.count'=1;;;0; 'Backup Repository 1#repository.space.usage.bytes'=87617332838B;;;0;321478302105 'Backup Repository 1#repository.space.free.bytes'=233860969267B;;;0;321478302105 'Backup Repository 1#repository.space.usage.percentage'=27.25%;;;0;100
    ...    4
    ...    vbr.example.com
    ...    --include-name=Default --warning-repository-status=''
    ...    OK: repository 'Default Backup Repository' [type: WinLocal] state: outOfDate - space usage total: 99.40 GB used: 83.00 GB (83.50%) free: 16.40 GB (16.50%) | 'repositories.detected.count'=1;;;0; 'Default Backup Repository#repository.space.usage.bytes'=89120571392B;;;0;106729937305 'Default Backup Repository#repository.space.free.bytes'=17609365913B;;;0;106729937305 'Default Backup Repository#repository.space.usage.percentage'=83.50%;;;0;100
    ...    5
    ...    vbr.example.com
    ...    --include-name='Repository 1' --warning-space-usage-prct=20
    ...    WARNING: repository 'Backup Repository 1' [type: WinLocal] space usage total: 299.40 GB used: 81.60 GB (27.25%) free: 217.80 GB (72.75%) | 'repositories.detected.count'=1;;;0; 'Backup Repository 1#repository.space.usage.bytes'=87617332838B;;;0;321478302105 'Backup Repository 1#repository.space.free.bytes'=233860969267B;;;0;321478302105 'Backup Repository 1#repository.space.usage.percentage'=27.25%;0:20;;0;100
    ...    6
    ...    vbr.example.com
    ...    --include-name='Repository 1' --critical-space-usage-free=300000000000:
    ...    CRITICAL: repository 'Backup Repository 1' [type: WinLocal] space usage total: 299.40 GB used: 81.60 GB (27.25%) free: 217.80 GB (72.75%) | 'repositories.detected.count'=1;;;0; 'Backup Repository 1#repository.space.usage.bytes'=87617332838B;;;0;321478302105 'Backup Repository 1#repository.space.free.bytes'=233860969267B;;300000000000:;0;321478302105 'Backup Repository 1#repository.space.usage.percentage'=27.25%;;;0;100
    ...    7
    ...    vbr.example.com
    ...    --include-type=AmazonS3
    ...    OK: repository 'Object Storage Repository' [type: AmazonS3] state: online | 'repositories.detected.count'=1;;;0;
    ...    8
    ...    no-repositories.example.com
    ...    ${EMPTY}
    ...    UNKNOWN: Number of repositories detected: 0 | 'repositories.detected.count'=0;;;0;
    ...    9
    ...    vbr.example.com
    ...    --include-id='^22222222-0000-0000-0000-000000000002$'
    ...    WARNING: repository 'Default Backup Repository' [type: WinLocal] state: outOfDate | 'repositories.detected.count'=1;;;0; 'Default Backup Repository#repository.space.usage.bytes'=89120571392B;;;0;106729937305 'Default Backup Repository#repository.space.free.bytes'=17609365913B;;;0;106729937305 'Default Backup Repository#repository.space.usage.percentage'=83.50%;;;0;100
    ...    10
    ...    vbr.example.com
    ...    --exclude-id='^22222222-0000-0000-0000-00000000000[2-9]$'
    ...    OK: repository 'Backup Repository 1' [type: WinLocal] state: online - space usage total: 299.40 GB used: 81.60 GB (27.25%) free: 217.80 GB (72.75%) | 'repositories.detected.count'=1;;;0; 'Backup Repository 1#repository.space.usage.bytes'=87617332838B;;;0;321478302105 'Backup Repository 1#repository.space.free.bytes'=233860969267B;;;0;321478302105 'Backup Repository 1#repository.space.usage.percentage'=27.25%;;;0;100

Repositories discovery ${tc}
    [Tags]    apps    backup    veeam    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    --hostname=${hostname}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    hostname
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    vbr.example.com
    ...    --disco-format
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <element>id</element> <element>name</element> <element>type</element> <element>host_name</element> <element>path</element> </data>
    ...    2
    ...    vbr.example.com
    ...    --disco-show
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label host_name="backup01.example.com" id="22222222-0000-0000-0000-000000000001" name="Backup Repository 1" path="C:\\\\Backup Repository" type="WinLocal"/> <label host_name="backup02.example.com" id="22222222-0000-0000-0000-000000000002" name="Default Backup Repository" path="C:\\\\Backup" type="WinLocal"/> <label host_name="backup03.example.com" id="22222222-0000-0000-0000-000000000003" name="Hardened Repository" path="/mnt/backup" type="LinuxHardened"/> <label host_name="" id="22222222-0000-0000-0000-000000000004" name="Object Storage Repository" path="bucket01" type="AmazonS3"/> <label host_name="backup04.example.com" id="22222222-0000-0000-0000-000000000005" name="Scale-out extent 1" path="/mnt/extent1" type="LinuxLocal"/> </data>
    ...    3
    ...    vbr.example.com
    ...    --disco-show --exclude-extents
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label host_name="backup01.example.com" id="22222222-0000-0000-0000-000000000001" name="Backup Repository 1" path="C:\\\\Backup Repository" type="WinLocal"/> <label host_name="backup02.example.com" id="22222222-0000-0000-0000-000000000002" name="Default Backup Repository" path="C:\\\\Backup" type="WinLocal"/> <label host_name="backup03.example.com" id="22222222-0000-0000-0000-000000000003" name="Hardened Repository" path="/mnt/backup" type="LinuxHardened"/> <label host_name="" id="22222222-0000-0000-0000-000000000004" name="Object Storage Repository" path="bucket01" type="AmazonS3"/> </data>
