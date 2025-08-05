*** Settings ***


Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s
Test Setup          Ctn Cleanup Cache

*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}vmware8-restapi.mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::esx::plugin
...                 --mode=disk-io
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000
...                 --esx-id=host-22

*** Test Cases ***
Disk-Io ${tc}
    [Tags]    apps    api    vmware   vsphere8    esx
    ${command}    Catenate    ${CMD} ${extraoptions}

    Ctn Run Command Without Connector And Check Result As Strings    ${tc}    ${command}    ${expected_result}

    Examples:    tc    extraoptions                              expected_result   --
        ...      1     ${EMPTY}                                  OK: usage-bps : skipped (no value(s)), contention-ms : skipped (no value(s)) - no data for host host-22 counter disk.throughput.usage.HOST at the moment. - no data for host host-22 counter disk.throughput.contention.HOST at the moment.
        ...      2     ${EMPTY}                                  OK: Disk throughput usage: 125.88 MB/s, Disk throughput contention is 0.19 ms | 'disk.throughput.usage.bytespersecond'=131992094.72Bps;;;; 'disk.throughput.contention.milliseconds'=0.19ms;;;;
        ...      3     --warning-contention-ms=0:0               WARNING: Disk throughput contention is 0.19 ms | 'disk.throughput.usage.bytespersecond'=131992094.72Bps;;;; 'disk.throughput.contention.milliseconds'=0.19ms;0:0;;;
        ...      4     --critical-contention-ms=0:0              CRITICAL: Disk throughput contention is 0.19 ms | 'disk.throughput.usage.bytespersecond'=131992094.72Bps;;;; 'disk.throughput.contention.milliseconds'=0.19ms;;0:0;;
        ...      5     --warning-usage-bps=0:0                   WARNING: Disk throughput usage: 125.88 MB/s | 'disk.throughput.usage.bytespersecond'=131992094.72Bps;0:0;;; 'disk.throughput.contention.milliseconds'=0.19ms;;;;
        ...      6     --critical-usage-bps=0:0                  CRITICAL: Disk throughput usage: 125.88 MB/s | 'disk.throughput.usage.bytespersecond'=131992094.72Bps;;0:0;; 'disk.throughput.contention.milliseconds'=0.19ms;;;;
