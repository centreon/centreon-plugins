*** Settings ***
Documentation       Check Dell Me4 interfaces

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}me4.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=storage::dell::me4::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --proto=http
...                 --port=${APIPORT}
...                 --mode=interfaces


*** Test Cases ***
Interfaces ${tc}
    [Tags]    storage    dell    me4    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options                                                                  expected_result    --
         ...     1     --api-username=test --api-password=test                                        OK: All interfaces are ok | 'A0~phy-0#port.interface.disparity.errors.count'=3;;;0; 'A0~phy-0#port.interface.lost.dwords.count'=1;;;0; 'A0~phy-0#port.interface.invalid.dwords.count'=12;;;0; 'A0~phy-1#port.interface.disparity.errors.count'=0;;;0; 'A0~phy-1#port.interface.lost.dwords.count'=0;;;0; 'A0~phy-1#port.interface.invalid.dwords.count'=0;;;0; 'B0~phy-0#port.interface.disparity.errors.count'=1;;;0; 'B0~phy-0#port.interface.lost.dwords.count'=0;;;0; 'B0~phy-0#port.interface.invalid.dwords.count'=5;;;0;
         ...     2     --api-username=test --api-password=test --omit-phy-statistics                  OK: All interfaces are ok | 'A0#port.io.read.usage.iops'=0.00iops;;;0; 'A0#port.io.write.usage.iops'=0.00iops;;;0; 'A0#port.traffic.read.usage.bitspersecond'=0b/s;;;0; 'A0#port.traffic.write.usage.bitspersecond'=0b/s;;;0; 'B0#port.io.read.usage.iops'=0.00iops;;;0; 'B0#port.io.write.usage.iops'=0.00iops;;;0; 'B0#port.traffic.read.usage.bitspersecond'=0b/s;;;0; 'B0#port.traffic.write.usage.bitspersecond'=0b/s;;;0;
         ...     3     --api-username=testdellsan --api-password=testdellsan                          UNKNOWN: Cannot decode response (add --debug option to display returned content)
         ...     4     --api-username=testdellsan --api-password=testdellsan --omit-phy-statistics    OK: All interfaces are ok | 'A0#port.io.read.usage.iops'=0.00iops;;;0; 'A0#port.io.write.usage.iops'=0.00iops;;;0; 'A0#port.traffic.read.usage.bitspersecond'=0b/s;;;0; 'A0#port.traffic.write.usage.bitspersecond'=0b/s;;;0; 'B0#port.io.read.usage.iops'=0.00iops;;;0; 'B0#port.io.write.usage.iops'=0.00iops;;;0; 'B0#port.traffic.read.usage.bitspersecond'=0b/s;;;0; 'B0#port.traffic.write.usage.bitspersecond'=0b/s;;;0;
