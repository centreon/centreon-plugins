*** Settings ***
Documentation       OpenStack Volume

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
...                 --mode=volume
...                 --identity-url=http://${HOSTNAME}:${APIPORT}/v3
...                 --username=xxx
...                 --password=P@s$WoRdZ


*** Test Cases ***
Volume ${tc}
    [Tags]    cloud     openstack     api
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings   ${command}    ${expected_string}

    Examples:        tc    extraoptions                                             expected_string    --
            ...      1     ${EMPTY}                                                 OK: Volume count: 2 - All volumes are ok | 'volume.count'=2;;;0;
            ...      2     --disco-format                                           <?xml version="1.0" encoding="utf-8"?> <data> <element>id</element> <element>status</element> <element>name</element> <element>type</element> <element>description</element> <element>size</element> <element>project_id</element> <element>bootable</element> <element>encrypted</element> <element>zone</element> <element>attachments</element> </data>
            ...      3     --disco-show                                             <?xml version="1.0" encoding="utf-8"?> <data> <label attachments="0" bootable="0" description="un volume non admin" encrypted="0" id="b510453a-6727-4392-947c-7431aa31250e" name="vol-a-amoi" project_id="dd2cef13c210457d9cdf06e24c2c37b0" size="1" status="available" type="__DEFAULT__" zone="nova"/> <label attachments="0" bootable="0" description="un volume non admin 2" encrypted="0" id="ca382d6d-53a7-45e0-97d8-fec68abbdcc0" name="vol-a-amoi-2" project_id="dd2cef13c210457d9cdf06e24c2c37b0" size="1" status="available" type="__DEFAULT__" zone="nova"/> </data>
            ...      4     --include-name=vol-a-amoi-2                              OK: Volume count: 1 - Volume vol-a-amoi-2 is in available state, Id: ca382d6d-53a7-45e0-97d8-fec68abbdcc0, Type: __DEFAULT__, Description: un volume non admin 2, Size: 1, Project_id: dd2cef13c210457d9cdf06e24c2c37b0, Bootable: 0, Encrypted: 0, Zone: nova, Attachments count: 0 | 'volume.count'=1;;;0;
            ...      5     --include-id=b510453a-6727-4392-947c-7431aa31250e        OK: Volume count: 1 - Volume vol-a-amoi is in available state, Id: b510453a-6727-4392-947c-7431aa31250e, Type: __DEFAULT__, Description: un volume non admin, Size: 1, Project_id: dd2cef13c210457d9cdf06e24c2c37b0, Bootable: 0, Encrypted: 0, Zone: nova, Attachments count: 0 | 'volume.count'=1;;;0;
            ...      6     --exclude-status=available                               UNKNOWN: Volume count: 0 | 'volume.count'=0;;;0;
            ...      7     --include-description="non admin 2"                      OK: Volume count: 1 - Volume vol-a-amoi-2 is in available state, Id: ca382d6d-53a7-45e0-97d8-fec68abbdcc0, Type: __DEFAULT__, Description: un volume non admin 2, Size: 1, Project_id: dd2cef13c210457d9cdf06e24c2c37b0, Bootable: 0, Encrypted: 0, Zone: nova, Attachments count: 0 | 'volume.count'=1;;;0;
            ...      8     --include-bootable=1                                     UNKNOWN: Volume count: 0 | 'volume.count'=0;;;0;
            ...      9     --include-encrypted=1                                    UNKNOWN: Volume count: 0 | 'volume.count'=0;;;0;
            ...      10    --exclude-zone=nova                                      UNKNOWN: Volume count: 0 | 'volume.count'=0;;;0;
            ...      11    --exclude-id=b510453a-6727-4392-947c-7431aa31250e        OK: Volume count: 1 - Volume vol-a-amoi-2 is in available state, Id: ca382d6d-53a7-45e0-97d8-fec68abbdcc0, Type: __DEFAULT__, Description: un volume non admin 2, Size: 1, Project_id: dd2cef13c210457d9cdf06e24c2c37b0, Bootable: 0, Encrypted: 0, Zone: nova, Attachments count: 0 | 'volume.count'=1;;;0;
            ...      12    --include-type=fake                                      UNKNOWN: Volume count: 0 | 'volume.count'=0;;;0;
            ...      13    --critical-attachments=1:                                CRITICAL: Attachments count: 0 - Attachments count: 0 | 'volume.count'=2;;;0;
            ...      14    --warning-attachments=1:                                 WARNING: Attachments count: 0 - Attachments count: 0 | 'volume.count'=2;;;0;
            ...      15    --critical-status='%\\\{status\\\} =~ /available/'       CRITICAL: Volume vol-a-amoi is in available state - Volume vol-a-amoi-2 is in available state | 'volume.count'=2;;;0;
            ...      16    --warning-status='%\\\{status\\\} =~ /available/'        WARNING: Volume vol-a-amoi is in available state - Volume vol-a-amoi-2 is in available state | 'volume.count'=2;;;0;
