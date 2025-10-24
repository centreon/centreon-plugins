*** Settings ***
Documentation       OpenStack Instance

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}openstack.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS} 
...                 --plugin=cloud::openstack::restapi::plugin
...                 --mode=instance
...                 --identity-url=http://${HOSTNAME}:${APIPORT}/v3
...                 --username=xxx
...                 --password=P@s$WoRdZ


*** Test Cases ***
Discovery ${tc}
    [Tags]    cloud     openstack     api
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings   ${command}    ${expected_string}

    Examples:        tc    extraoptions                                             expected_string    --
            ...      1     ${EMPTY}                                                 OK: Instance count: 2 - All instances are ok | 'instance.count'=2;;;0;
            ...      2     --disco-format                                           <?xml version="1.0" encoding="utf-8"?> <data> <element>id</element> <element>host</element> <element>name</element> <element>status</element> <element>image</element> <element>flavor</element> <element>ip</element> <element>bookmark</element> <element>project_id</element> <element>instance_name</element> <element>zone</element> <element>vm_state</element> </data>
            ...      3     --disco-show                                             <?xml version="1.0" encoding="utf-8"?> <data> <label bookmark="http://127.0.0.1:8764/servers/489e5eaf-eab5-48ba-b7f6-1e4b29d4d473" flavor="1" host="localhost.com" id="489e5eaf-eab5-48ba-b7f6-1e4b29d4d473" image="97061229-2e66-4486-98b8-ce8f835248d1" instance_name="instance-00000001" ip="192.168.222.218" name="da-test" project_id="3903cb485951437bb6638ec42f46d8ab" status="ACTIVE" vm_state="active" zone="nova"/> <label bookmark="http://127.0.0.1:8764/servers/489e5eaf-eab5-48ba-aaaa-1e4b29d4d473" flavor="1" host="localhost.com" id="aaaa-eab5-48ba-b7f6-1e4b29d4d473" image="97061229-2e66-4486-98b8-ce8f835248d1" instance_name="instance-00000001" ip="192.168.222.218" name="other_name" project_id="3903cb485951437bb6638ec42f46d8ab" status="ACTIVE" vm_state="paused" zone="nova"/> </data>
            ...      4     --include-name=test                                      OK: Instance count: 1 - Instance da-test is in ACTIVE state (vm_state: active), Id: 489e5eaf-eab5-48ba-b7f6-1e4b29d4d473, Host: localhost.com, Image: 97061229-2e66-4486-98b8-ce8f835248d1, Flavor: 1, Ip: 192.168.222.218, Bookmark: http://127.0.0.1:8764/servers/489e5eaf-eab5-48ba-b7f6-1e4b29d4d473, Project_id: 3903cb485951437bb6638ec42f46d8ab, Instance_name: instance-00000001, Zone: nova | 'instance.count'=1;;;0;
            ...      5     --include-id=489e5eaf-eab5-48ba-b7f6-1e4b29d4d473        OK: Instance count: 1 - Instance da-test is in ACTIVE state (vm_state: active), Id: 489e5eaf-eab5-48ba-b7f6-1e4b29d4d473, Host: localhost.com, Image: 97061229-2e66-4486-98b8-ce8f835248d1, Flavor: 1, Ip: 192.168.222.218, Bookmark: http://127.0.0.1:8764/servers/489e5eaf-eab5-48ba-b7f6-1e4b29d4d473, Project_id: 3903cb485951437bb6638ec42f46d8ab, Instance_name: instance-00000001, Zone: nova | 'instance.count'=1;;;0;
            ...      6     --exclude-status=ACTIVE                                  OK: Instance count: 0 | 'instance.count'=0;;;0;
            ...      7     --exclude-image=97061229-2e66-4486-98b8-ce8f835248d1     OK: Instance count: 0 | 'instance.count'=0;;;0;
            ...      8     --exclude-flavor=1                                       OK: Instance count: 0 | 'instance.count'=0;;;0;
            ...      9     --exclude-zone=nova                                      OK: Instance count: 0 | 'instance.count'=0;;;0;
            ...      10    --exclude-host=localhost                                 OK: Instance count: 0 | 'instance.count'=0;;;0;
            ...      11    --exclude-instance-name=instance                         OK: Instance count: 0 | 'instance.count'=0;;;0;
            ...      12    --exclude-ip=192.168.222.218                             OK: Instance count: 0 | 'instance.count'=0;;;0;
            ...      14    --warning-count=:1                                       WARNING: Instance count: 2 | 'instance.count'=2;0:1;;0;
            ...      15    --critical-status='%\\\{status\\\} =~ /ACTIVE/'          CRITICAL: Instance da-test is in ACTIVE state (vm_state: active) - Instance other_name is in ACTIVE state (vm_state: paused) | 'instance.count'=2;;;0;
            ...      16    --warning-status='%\\\{status\\\} =~ /ACTIVE/'           WARNING: Instance da-test is in ACTIVE state (vm_state: active) - Instance other_name is in ACTIVE state (vm_state: paused) | 'instance.count'=2;;;0;
