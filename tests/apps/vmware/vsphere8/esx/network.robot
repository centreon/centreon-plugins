*** Settings ***


Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s
Test Setup          Ctn Cleanup Cache

*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}vmware8-restapi.mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::esx::plugin
...                 --mode=network
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000
...                 --esx-id=host-22

*** Test Cases ***
Network ${tc}
    [Tags]    apps    api    vmware   vsphere8    esx
    ${command}    Catenate    ${CMD} ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:    tc    extraoptions                         expected_result   --
        ...      1     ${EMPTY}                             OK: usage-bps : skipped (no value(s)), usage-prct : skipped (no value(s)) - no data for host host-22 counter net.throughput.usable.HOST at the moment.
        ...      2     ${EMPTY}                             OK: Network throughput usage: 184.96 KB/s of 953.67 MB/s usable, 0.02% of usable network throughput used | 'network.throughput.usage.bytespersecond'=189399.04Bps;;;0;1000000000 'network.throughput.usage.percent'=0.018939904%;;;0;100
        ...      3     --warning-contention-count=1:1       WARNING: 0 packet(s) dropped | 'network.throughput.usage.bytespersecond'=189399.04Bps;;;0;1000000000 'network.throughput.usage.percent'=0.018939904%;;;0;100 'network.throughput.contention.count'=0;1:1;;;
        ...      4     --critical-contention-count=1:1      CRITICAL: 0 packet(s) dropped | 'network.throughput.usage.bytespersecond'=189399.04Bps;;;0;1000000000 'network.throughput.usage.percent'=0.018939904%;;;0;100 'network.throughput.contention.count'=0;;1:1;;
        ...      5     --warning-usage-bps=1:1              WARNING: Network throughput usage: 184.96 KB/s of 953.67 MB/s usable | 'network.throughput.usage.bytespersecond'=189399.04Bps;1:1;;0;1000000000 'network.throughput.usage.percent'=0.018939904%;;;0;100
        ...      6     --critical-usage-bps=1:1             CRITICAL: Network throughput usage: 184.96 KB/s of 953.67 MB/s usable | 'network.throughput.usage.bytespersecond'=189399.04Bps;;1:1;0;1000000000 'network.throughput.usage.percent'=0.018939904%;;;0;100
        ...      7     --warning-usage-prct=1:1             WARNING: 0.02% of usable network throughput used | 'network.throughput.usage.bytespersecond'=189399.04Bps;;;0;1000000000 'network.throughput.usage.percent'=0.018939904%;1:1;;0;100
        ...      8     --critical-usage-prct=1:1            CRITICAL: 0.02% of usable network throughput used | 'network.throughput.usage.bytespersecond'=189399.04Bps;;;0;1000000000 'network.throughput.usage.percent'=0.018939904%;;1:1;0;100

