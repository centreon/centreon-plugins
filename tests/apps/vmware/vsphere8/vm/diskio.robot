*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::vm::plugin
...                 --mode=disk-io
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000
...                 --vm-name=web-server-02


*** Test Cases ***
Disk-Io ${tc}
    [Tags]    apps    api    vmware    vsphere8    vm
    ${command}    Catenate    ${CMD} ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extraoptions                              expected_result   --
        ...      1     ${EMPTY}                                  UNKNOWN: no data for resource vm-1234 counter disk.throughput.usage.VM at the moment. - get_vm_stats function failed to retrieve stats get_vm_id method called to get web-server-02's id: vm-1234. Prefer using --vm-id to spare a query to the API. The counter disk.throughput.usage.VM was not recorded for resource vm-1234 before. It will now (creating acq_spec). The counter disk.throughput.contention.VM was not recorded for resource vm-1234 before. It will now (creating acq_spec).
        ...      2     ${EMPTY}                                  OK: Disk throughput usage: 20.29 KB/s, Disk throughput contention is 0.14 ms | 'disk.throughput.usage.bytespersecond'=20776.96Bps;;;; 'disk.throughput.contention.milliseconds'=0.14ms;;;;
        ...      3     --warning-contention-ms=0:0               WARNING: Disk throughput contention is 0.14 ms | 'disk.throughput.usage.bytespersecond'=20776.96Bps;;;; 'disk.throughput.contention.milliseconds'=0.14ms;0:0;;;
        ...      4     --critical-contention-ms=0:0              CRITICAL: Disk throughput contention is 0.14 ms | 'disk.throughput.usage.bytespersecond'=20776.96Bps;;;; 'disk.throughput.contention.milliseconds'=0.14ms;;0:0;;
        ...      5     --warning-usage-bps=0:0                   WARNING: Disk throughput usage: 20.29 KB/s | 'disk.throughput.usage.bytespersecond'=20776.96Bps;0:0;;; 'disk.throughput.contention.milliseconds'=0.14ms;;;;
        ...      6     --critical-usage-bps=0:0                  CRITICAL: Disk throughput usage: 20.29 KB/s | 'disk.throughput.usage.bytespersecond'=20776.96Bps;;0:0;; 'disk.throughput.contention.milliseconds'=0.14ms;;;;
