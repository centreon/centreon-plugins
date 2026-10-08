*** Settings ***
Resource          ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Ctn Generic Suite Setup
Suite Teardown    Ctn Generic Suite Teardown
Test Timeout      120s


*** Variables ***
${CMD}    ${CENTREON_PLUGINS} --plugin=os::f5os::snmp::plugin


*** Test Cases ***
disks ${tc}
    [Tags]    os    f5os    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=disks
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --snmp-community=os/f5os/snmp/f5os
    ...    OK: All disks are ok | 'controller-1-nvme0n1#disk.space.usage.percentage'=45.00%;;;0;100 'controller-2-nvme0n1#disk.space.usage.percentage'=82.00%;;;0;100
    ...    2
    ...    --snmp-community=os/f5os/snmp/f5os
    ...    OK: All disks are ok | 'controller-1-nvme0n1#disk.space.usage.percentage'=45.00%;;;0;100 'controller-1-nvme0n1#disk.io.read.usage.iops'=0.00iops;;;0; 'controller-1-nvme0n1#disk.io.write.usage.iops'=0.00iops;;;0; 'controller-1-nvme0n1#disk.io.read.usage.bytespersecond'=0B/s;;;0; 'controller-1-nvme0n1#disk.io.write.usage.bytespersecond'=0B/s;;;0; 'controller-1-nvme0n1#disk.io.read.latency.milliseconds'=0.00ms;;;0; 'controller-1-nvme0n1#disk.io.write.latency.milliseconds'=0.00ms;;;0; 'controller-2-nvme0n1#disk.space.usage.percentage'=82.00%;;;0;100 'controller-2-nvme0n1#disk.io.read.usage.iops'=0.00iops;;;0; 'controller-2-nvme0n1#disk.io.write.usage.iops'=0.00iops;;;0; 'controller-2-nvme0n1#disk.io.read.usage.bytespersecond'=0B/s;;;0; 'controller-2-nvme0n1#disk.io.write.usage.bytespersecond'=0B/s;;;0; 'controller-2-nvme0n1#disk.io.read.latency.milliseconds'=0.00ms;;;0; 'controller-2-nvme0n1#disk.io.write.latency.milliseconds'=0.00ms;;;0;
    ...    3
    ...    --snmp-community=os/f5os/snmp/f5os --include-name='^controller-1-'
    ...    OK: Disk 'controller-1-nvme0n1' space used: 45.00 % | 'controller-1-nvme0n1#disk.space.usage.percentage'=45.00%;;;0;100
    ...    4
    ...    --snmp-community=os/f5os/snmp/f5os --exclude-name='^controller-1-'
    ...    OK: Disk 'controller-2-nvme0n1' space used: 82.00 % | 'controller-2-nvme0n1#disk.space.usage.percentage'=82.00%;;;0;100
    ...    5
    ...    --snmp-community=os/f5os/snmp/f5os --include-name='-nvme0n1$' --critical-space-usage-prct=80
    ...    CRITICAL: Disk 'controller-2-nvme0n1' space used: 82.00 % | 'controller-1-nvme0n1#disk.space.usage.percentage'=45.00%;;0:80;0;100 'controller-2-nvme0n1#disk.space.usage.percentage'=82.00%;;0:80;0;100
    ...    6
    ...    --snmp-community=os/f5os/snmp/f5os --exclude-name='nvme'
    ...    UNKNOWN: No disk found. Can be: filters, cache file.
    ...    7
    ...    --snmp-community=os/f5os/snmp/f5os --warning-space-usage-prct=40
    ...    WARNING: Disk 'controller-1-nvme0n1' space used: 45.00 % - Disk 'controller-2-nvme0n1' space used: 82.00 % | 'controller-1-nvme0n1#disk.space.usage.percentage'=45.00%;0:40;;0;100 'controller-1-nvme0n1#disk.io.read.usage.iops'=0.00iops;;;0; 'controller-1-nvme0n1#disk.io.write.usage.iops'=0.00iops;;;0; 'controller-1-nvme0n1#disk.io.read.usage.bytespersecond'=0B/s;;;0; 'controller-1-nvme0n1#disk.io.write.usage.bytespersecond'=0B/s;;;0; 'controller-1-nvme0n1#disk.io.read.latency.milliseconds'=0.00ms;;;0; 'controller-1-nvme0n1#disk.io.write.latency.milliseconds'=0.00ms;;;0; 'controller-2-nvme0n1#disk.space.usage.percentage'=82.00%;0:40;;0;100 'controller-2-nvme0n1#disk.io.read.usage.iops'=0.00iops;;;0; 'controller-2-nvme0n1#disk.io.write.usage.iops'=0.00iops;;;0; 'controller-2-nvme0n1#disk.io.read.usage.bytespersecond'=0B/s;;;0; 'controller-2-nvme0n1#disk.io.write.usage.bytespersecond'=0B/s;;;0; 'controller-2-nvme0n1#disk.io.read.latency.milliseconds'=0.00ms;;;0; 'controller-2-nvme0n1#disk.io.write.latency.milliseconds'=0.00ms;;;0;
    ...    8
    ...    --snmp-community=os/f5os/snmp/f5os --filter-counters='latency'
    ...    OK: All disks are ok
    ...    9
    ...    --snmp-community=os/f5os/snmp/f5os-disks-delta --filter-counters='latency' --warning-read-latency=4 --critical-write-latency=1
    ...    CRITICAL: Disk 'controller-1-nvme0n1' read latency: 5.00 ms, write latency: 2.00 ms | 'controller-1-nvme0n1#disk.io.read.latency.milliseconds'=5.00ms;0:4;;0; 'controller-1-nvme0n1#disk.io.write.latency.milliseconds'=2.00ms;;0:1;0; 'controller-2-nvme0n1#disk.io.read.latency.milliseconds'=0.00ms;0:4;;0; 'controller-2-nvme0n1#disk.io.write.latency.milliseconds'=0.00ms;;0:1;0;

disks discovery ${tc}
    [Tags]    os    f5os    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=disks
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/f5os/snmp/f5os
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --disco-format
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <element>name</element> <element>model</element> <element>vendor</element> <element>serial</element> <element>size</element> <element>type</element> </data>
    ...    2
    ...    --disco-show
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label model="Anonymized 301" name="controller-1-nvme0n1" serial="Anonymized 331" size="683.00GB" type="nvme" vendor="Anonymized 311"/> <label model="Anonymized 302" name="controller-2-nvme0n1" serial="Anonymized 332" size="733.00GB" type="nvme" vendor="Anonymized 312"/> </data>
    ...    3
    ...    --disco-show --include-name='^controller-2-'
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label model="Anonymized 302" name="controller-2-nvme0n1" serial="Anonymized 332" size="733.00GB" type="nvme" vendor="Anonymized 312"/> </data>
