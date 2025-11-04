*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::esx::plugin
...                 --mode=swap
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000
...                 --esx-id=host-22


*** Test Cases ***
Swap ${tc}
    [Tags]    apps    api    vmware    vsphere8    esx
    ${command}    Catenate    ${CMD} --http-backend=curl ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extraoptions                                        expected_result   --
        ...      1     ${EMPTY}                                            UNKNOWN: no data for resource host-22 counter mem.swap.current.HOST at the moment. - get_esx_stats function failed to retrieve stats The counter mem.swap.current.HOST was not recorded for resource host-22 before. It will now (creating acq_spec). The counter mem.swap.target.HOST was not recorded for resource host-22 before. It will now (creating acq_spec).
        ...      2     ${EMPTY}                                            OK: Swap usage: 120.56 MB (max available is 1.00 TB), Percent used: 0.01% | 'swap.usage.bytes'=126419660.8B;;;;1099511627776 'swap.usage.percent'=0.0114978011697531%;;;0;100
        ...      3     --add-rates                                         OK: Swap usage: 120.56 MB (max available is 1.00 TB), Percent used: 0.01% - Swap read rate is: 6.39 MB/s, Swap write rate is: 1.21 MB/s | 'swap.usage.bytes'=126419660.8B;;;;1099511627776 'swap.usage.percent'=0.0114978011697531%;;;0;100 'swap.read-rate.bytespersecond'=6700236.8Bps;;;; 'swap.write-rate.bytespersecond'=1264128Bps;;;;
        ...      4     --warning-read-rate-bps=1                           WARNING: Swap read rate is: 6.39 MB/s | 'swap.usage.bytes'=126419660.8B;;;;1099511627776 'swap.usage.percent'=0.0114978011697531%;;;0;100 'swap.read-rate.bytespersecond'=6700236.8Bps;0:1;;; 'swap.write-rate.bytespersecond'=1264128Bps;;;;
        ...      5     --critical-read-rate-bps=1                          CRITICAL: Swap read rate is: 6.39 MB/s | 'swap.usage.bytes'=126419660.8B;;;;1099511627776 'swap.usage.percent'=0.0114978011697531%;;;0;100 'swap.read-rate.bytespersecond'=6700236.8Bps;;0:1;; 'swap.write-rate.bytespersecond'=1264128Bps;;;;
        ...      6     --warning-write-rate-bps=1                          WARNING: Swap write rate is: 1.21 MB/s | 'swap.usage.bytes'=126419660.8B;;;;1099511627776 'swap.usage.percent'=0.0114978011697531%;;;0;100 'swap.read-rate.bytespersecond'=6700236.8Bps;;;; 'swap.write-rate.bytespersecond'=1264128Bps;0:1;;;
        ...      7     --critical-write-rate-bps=1                         CRITICAL: Swap write rate is: 1.21 MB/s | 'swap.usage.bytes'=126419660.8B;;;;1099511627776 'swap.usage.percent'=0.0114978011697531%;;;0;100 'swap.read-rate.bytespersecond'=6700236.8Bps;;;; 'swap.write-rate.bytespersecond'=1264128Bps;;0:1;;
        ...      8     --warning-usage-bytes=1                             WARNING: Swap usage: 120.56 MB (max available is 1.00 TB) | 'swap.usage.bytes'=126419660.8B;0:1;;;1099511627776 'swap.usage.percent'=0.0114978011697531%;;;0;100
        ...      9     --critical-usage-bytes=1                            CRITICAL: Swap usage: 120.56 MB (max available is 1.00 TB) | 'swap.usage.bytes'=126419660.8B;;0:1;;1099511627776 'swap.usage.percent'=0.0114978011697531%;;;0;100
        ...      10    --warning-usage-prct=1:                             WARNING: Percent used: 0.01% | 'swap.usage.bytes'=126419660.8B;;;;1099511627776 'swap.usage.percent'=0.0114978011697531%;1:;;0;100
        ...      11    --critical-usage-prct=1:                            CRITICAL: Percent used: 0.01% | 'swap.usage.bytes'=126419660.8B;;;;1099511627776 'swap.usage.percent'=0.0114978011697531%;;1:;0;100
