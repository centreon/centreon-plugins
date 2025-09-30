*** Settings ***


Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s

*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::vm::plugin
...                 --mode=network
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000

*** Test Cases ***
Network ${tc}
    [Tags]    apps    api    vmware   vsphere8    esx
    ${command}    Catenate    ${CMD} ${filter_option} ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    filter_option                extraoptions                         expected_result   --
        ...       1    --vm-id=vm-1234              ${EMPTY}                             UNKNOWN: no data for resource vm-1234 counter net.throughput.contention.VM at the moment. - get_vm_stats function failed to retrieve stats The counter net.throughput.contention.VM was not recorded for resource vm-1234 before. It will now (creating acq_spec). The counter net.throughput.usage.VM was not recorded for resource vm-1234 before. It will now (creating acq_spec).
        ...       2    --vm-id=vm-1234              ${EMPTY}                             OK: Network throughput usage: 2.48 KB/s - 0 packet(s) dropped | 'network.throughput.usage.bitspersecond'=2539.52nps;;;0; 'network.throughput.contention.count'=0;;;;
        ...       3    --vm-id=vm-1234              --warning-contention-count=1:1       WARNING: 0 packet(s) dropped | 'network.throughput.usage.bitspersecond'=2539.52nps;;;0; 'network.throughput.contention.count'=0;1:1;;;
        ...       4    --vm-id=vm-1234              --critical-contention-count=1:1      CRITICAL: 0 packet(s) dropped | 'network.throughput.usage.bitspersecond'=2539.52nps;;;0; 'network.throughput.contention.count'=0;;1:1;;
        ...       5    --vm-id=vm-1234              --warning-usage-bps=1:1              WARNING: Network throughput usage: 2.48 KB/s | 'network.throughput.usage.bitspersecond'=2539.52nps;1:1;;0; 'network.throughput.contention.count'=0;;;;
        ...       6    --vm-id=vm-1234              --critical-usage-bps=1:1             CRITICAL: Network throughput usage: 2.48 KB/s | 'network.throughput.usage.bitspersecond'=2539.52nps;;1:1;0; 'network.throughput.contention.count'=0;;;;
        ...       7    --vm-name=web-server-02      ${EMPTY}                             OK: Network throughput usage: 2.48 KB/s - 0 packet(s) dropped | 'network.throughput.usage.bitspersecond'=2539.52nps;;;0; 'network.throughput.contention.count'=0;;;;
        ...       8    --vm-name=web-server-02      --warning-contention-count=1:1       WARNING: 0 packet(s) dropped | 'network.throughput.usage.bitspersecond'=2539.52nps;;;0; 'network.throughput.contention.count'=0;1:1;;;
        ...       9    --vm-name=web-server-02      --critical-contention-count=1:1      CRITICAL: 0 packet(s) dropped | 'network.throughput.usage.bitspersecond'=2539.52nps;;;0; 'network.throughput.contention.count'=0;;1:1;;
        ...      10    --vm-name=web-server-02      --warning-usage-bps=1:1              WARNING: Network throughput usage: 2.48 KB/s | 'network.throughput.usage.bitspersecond'=2539.52nps;1:1;;0; 'network.throughput.contention.count'=0;;;;
        ...      11    --vm-name=web-server-02      --critical-usage-bps=1:1             CRITICAL: Network throughput usage: 2.48 KB/s | 'network.throughput.usage.bitspersecond'=2539.52nps;;1:1;0; 'network.throughput.contention.count'=0;;;;
