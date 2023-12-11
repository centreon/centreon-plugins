*** Settings ***
Documentation       Network Teldat SNMP plugin

Library             OperatingSystem
Library             String

Test Timeout        120s


*** Variables ***
${CENTREON_PLUGINS}         ${CURDIR}${/}..${/}..${/}..${/}src${/}centreon_plugins.pl

${CMD}                      perl ${CENTREON_PLUGINS} --plugin=network::teldat::snmp::plugin

# Test simple usage of the cellsradio mode
&{teldat_cellsradio_test1}
...                         snmpcommunity=network-teldat-snmp
...                         filtercellid=
...                         customperfdatainstances=
...                         unknownstatus=
...                         warningstatus=
...                         criticalstatus=
...                         warningmodulescellradiodetected=
...                         criticalmodulescellradiodetected=
...                         warningmodulecellradiorsrp=
...                         criticalmodulecellradiorsrp=
...                         warningmodulecellradiorsrq=
...                         criticalmodulecellradiorsrq=
...                         warningmodulecellradiorscp=
...                         criticalmodulecellradiorscp=
...                         warningmodulecellradiocsq=
...                         criticalmodulecellradiocsq=
...                         warningmodulecellradiosnr=
...                         criticalmodulecellradiosnr=
...                         result=CRITICAL: cellular radio module '359072066403821'sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] [cellular active SIM ID: ] WARNING: cellular radio module '359072066403821'sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] [cellular active SIM ID: 89330122115801091660] - cellular radio module '359072066403821'sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] [cellular active SIM ID: 89330122115801091660] | 'modules.cellradio.detected.count'=3;;;0; 'module.cellradio.rsrp.dbm'=-114dBm;;;0; 'module.cellradio.rsrq.dbm'=-18dBm;;;0; 'module.cellradio.snr.db'=-1dBm;;;0; 'module.cellradio.rscp.dbm'=0dBm;;;0; 'module.cellradio.csq.dbm'=-73dBm;;;0; 'module.cellradio.rsrp.dbm'=-114dBm;;;0; 'module.cellradio.rsrq.dbm'=-18dBm;;;0; 'module.cellradio.snr.db'=-1dBm;;;0; 'module.cellradio.rscp.dbm'=0dBm;;;0; 'module.cellradio.csq.dbm'=-73dBm;;;0;

# Test cellsradio mode with filter-cell-id option set to a fake value
&{teldat_cellsradio_test2}
...                         snmpcommunity=network-teldat-snmp
...                         filtercellid=toto
...                         customperfdatainstances=
...                         unknownstatus=
...                         warningstatus=
...                         criticalstatus=
...                         warningmodulescellradiodetected=
...                         criticalmodulescellradiodetected=
...                         warningmodulecellradiorsrp=
...                         criticalmodulecellradiorsrp=
...                         warningmodulecellradiorsrq=
...                         criticalmodulecellradiorsrq=
...                         warningmodulecellradiorscp=
...                         criticalmodulecellradiorscp=
...                         warningmodulecellradiocsq=
...                         criticalmodulecellradiocsq=
...                         warningmodulecellradiosnr=
...                         criticalmodulecellradiosnr=
...                         result=UNKNOWN: No Cell ID found matching with filter : toto

# Test cellsradio mode with filter-cell-id option set to a imei value
&{teldat_cellsradio_test3}
...                         snmpcommunity=network-teldat-snmp
...                         filtercellid=359072066403821
...                         customperfdatainstances=
...                         unknownstatus=
...                         warningstatus=
...                         criticalstatus=
...                         warningmodulescellradiodetected=
...                         criticalmodulescellradiodetected=
...                         warningmodulecellradiorsrp=
...                         criticalmodulecellradiorsrp=
...                         warningmodulecellradiorsrq=
...                         criticalmodulecellradiorsrq=
...                         warningmodulecellradiorscp=
...                         criticalmodulecellradiorscp=
...                         warningmodulecellradiocsq=
...                         criticalmodulecellradiocsq=
...                         warningmodulecellradiosnr=
...                         criticalmodulecellradiosnr=
...                         result=CRITICAL: cellular radio module '359072066403821'sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] [cellular active SIM ID: ] WARNING: cellular radio module '359072066403821'sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] [cellular active SIM ID: 89330122115801091660] - cellular radio module '359072066403821'sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] [cellular active SIM ID: 89330122115801091660] | 'modules.cellradio.detected.count'=3;;;0; 'module.cellradio.rsrp.dbm'=-114dBm;;;0; 'module.cellradio.rsrq.dbm'=-18dBm;;;0; 'module.cellradio.snr.db'=-1dBm;;;0; 'module.cellradio.rscp.dbm'=0dBm;;;0; 'module.cellradio.csq.dbm'=-73dBm;;;0; 'module.cellradio.rsrp.dbm'=-114dBm;;;0; 'module.cellradio.rsrq.dbm'=-18dBm;;;0; 'module.cellradio.snr.db'=-1dBm;;;0; 'module.cellradio.rscp.dbm'=0dBm;;;0; 'module.cellradio.csq.dbm'=-73dBm;;;0;

# Test cellsradio mode with filter-cell-id option set to a simId value
&{teldat_cellsradio_test4}
...                         snmpcommunity=network-teldat-snmp
...                         filtercellid=89330122115801091660
...                         customperfdatainstances=
...                         unknownstatus=
...                         warningstatus=
...                         criticalstatus=
...                         warningmodulescellradiodetected=
...                         criticalmodulescellradiodetected=
...                         warningmodulecellradiorsrp=
...                         criticalmodulecellradiorsrp=
...                         warningmodulecellradiorsrq=
...                         criticalmodulecellradiorsrq=
...                         warningmodulecellradiorscp=
...                         criticalmodulecellradiorscp=
...                         warningmodulecellradiocsq=
...                         criticalmodulecellradiocsq=
...                         warningmodulecellradiosnr=
...                         criticalmodulecellradiosnr=
...                         result=WARNING: cellular radio module '359072066403821'sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] [cellular active SIM ID: 89330122115801091660] - cellular radio module '359072066403821'sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] [cellular active SIM ID: 89330122115801091660] | 'modules.cellradio.detected.count'=2;;;0; 'module.cellradio.rsrp.dbm'=-114dBm;;;0; 'module.cellradio.rsrq.dbm'=-18dBm;;;0; 'module.cellradio.snr.db'=-1dBm;;;0; 'module.cellradio.rscp.dbm'=0dBm;;;0; 'module.cellradio.csq.dbm'=-73dBm;;;0; 'module.cellradio.rsrp.dbm'=-114dBm;;;0; 'module.cellradio.rsrq.dbm'=-18dBm;;;0; 'module.cellradio.snr.db'=-1dBm;;;0; 'module.cellradio.rscp.dbm'=0dBm;;;0; 'module.cellradio.csq.dbm'=-73dBm;;;0;

# Test cellsradio mode with warning-modules-cellradio-detected option set to a 2
&{teldat_cellsradio_test5}
...                         snmpcommunity=network-teldat-snmp
...                         filtercellid=
...                         customperfdatainstances=
...                         unknownstatus=
...                         warningstatus=
...                         criticalstatus=
...                         warningmodulescellradiodetected=2
...                         criticalmodulescellradiodetected=
...                         warningmodulecellradiorsrp=
...                         criticalmodulecellradiorsrp=
...                         warningmodulecellradiorsrq=
...                         criticalmodulecellradiorsrq=
...                         warningmodulecellradiorscp=
...                         criticalmodulecellradiorscp=
...                         warningmodulecellradiocsq=
...                         criticalmodulecellradiocsq=
...                         warningmodulecellradiosnr=
...                         criticalmodulecellradiosnr=
...                         result=CRITICAL: cellular radio module '359072066403821'sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] [cellular active SIM ID: ] WARNING: Number of cellular radio modules detected: 3 - cellular radio module '359072066403821'sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] [cellular active SIM ID: 89330122115801091660] - cellular radio module '359072066403821'sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] [cellular active SIM ID: 89330122115801091660] | 'modules.cellradio.detected.count'=3;0:2;;0; 'module.cellradio.rsrp.dbm'=-114dBm;;;0; 'module.cellradio.rsrq.dbm'=-18dBm;;;0; 'module.cellradio.snr.db'=-1dBm;;;0; 'module.cellradio.rscp.dbm'=0dBm;;;0; 'module.cellradio.csq.dbm'=-73dBm;;;0; 'module.cellradio.rsrp.dbm'=-114dBm;;;0; 'module.cellradio.rsrq.dbm'=-18dBm;;;0; 'module.cellradio.snr.db'=-1dBm;;;0; 'module.cellradio.rscp.dbm'=0dBm;;;0; 'module.cellradio.csq.dbm'=-73dBm;;;0;

# Test cellsradio mode with critical-modules-cellradio-detected option set to a 2
&{teldat_cellsradio_test5}
...                         snmpcommunity=network-teldat-snmp
...                         filtercellid=
...                         customperfdatainstances=
...                         unknownstatus=
...                         warningstatus=
...                         criticalstatus=
...                         warningmodulescellradiodetected=
...                         criticalmodulescellradiodetected=2
...                         warningmodulecellradiorsrp=
...                         criticalmodulecellradiorsrp=
...                         warningmodulecellradiorsrq=
...                         criticalmodulecellradiorsrq=
...                         warningmodulecellradiorscp=
...                         criticalmodulecellradiorscp=
...                         warningmodulecellradiocsq=
...                         criticalmodulecellradiocsq=
...                         warningmodulecellradiosnr=
...                         criticalmodulecellradiosnr=
...                         result=CRITICAL: Number of cellular radio modules detected: 3 - cellular radio module '359072066403821'sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] [cellular active SIM ID: ] WARNING: cellular radio module '359072066403821'sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] [cellular active SIM ID: 89330122115801091660] - cellular radio module '359072066403821'sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] [cellular active SIM ID: 89330122115801091660] | 'modules.cellradio.detected.count'=3;;0:2;0; 'module.cellradio.rsrp.dbm'=-114dBm;;;0; 'module.cellradio.rsrq.dbm'=-18dBm;;;0; 'module.cellradio.snr.db'=-1dBm;;;0; 'module.cellradio.rscp.dbm'=0dBm;;;0; 'module.cellradio.csq.dbm'=-73dBm;;;0; 'module.cellradio.rsrp.dbm'=-114dBm;;;0; 'module.cellradio.rsrq.dbm'=-18dBm;;;0; 'module.cellradio.snr.db'=-1dBm;;;0; 'module.cellradio.rscp.dbm'=0dBm;;;0; 'module.cellradio.csq.dbm'=-73dBm;;;0;

@{teldat_cellsradio_tests}
...                         &{teldat_cellsradio_test1}
...                         &{teldat_cellsradio_test2}
...                         &{teldat_cellsradio_test3}
...                         &{teldat_cellsradio_test4}
...                         &{teldat_cellsradio_test5}
...                         &{teldat_cellsradio_test6}

*** Test Cases ***
Network Teldat SNMP cells radio
    [Documentation]    Network Teldat SNMP cells radio
    [Tags]    network    Teldat    snmp
    FOR    ${teldat_cellsradio_test}    IN    @{teldat_cellsradio_tests}
        ${command}    Catenate
        ...    ${CMD}
        ...    --mode=cells-radio
        ...    --hostname=127.0.0.1
        ...    --snmp-version=2c
        ...    --snmp-port=2024
        ...    --snmp-community=${teldat_cellsradio_test.snmpcommunity}
        ${length}    Get Length    ${teldat_cellsradio_test.filtercellid}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --filter-cell-id=${teldat_cellsradio_test.filtercellid}
        END
        ${length}    Get Length    ${teldat_cellsradio_test.customperfdatainstances}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --custom-perfdata-instances=${teldat_cellsradio_test.customperfdatainstances}
        END
        ${length}    Get Length    ${teldat_cellsradio_test.unknownstatus}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --unknown-status=${teldat_cellsradio_test.unknownstatus}
        END
        ${length}    Get Length    ${teldat_cellsradio_test.warningstatus}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --warning-status=${teldat_cellsradio_test.warningstatus}
        END
        ${length}    Get Length    ${teldat_cellsradio_test.criticalstatus}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --critical-status=${teldat_cellsradio_test.criticalstatus}
        END
        ${length}    Get Length    ${teldat_cellsradio_test.warningmodulescellradiodetected}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --warning-modules-cellradio-detected=${teldat_cellsradio_test.warningmodulescellradiodetected}
        END
        ${length}    Get Length    ${teldat_cellsradio_test.criticalmodulescellradiodetected}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --critical-modules-cellradio-detected=${teldat_cellsradio_test.criticalmodulescellradiodetected}
        END
        ${output}    Run    ${command}
        ${output}    Strip String    ${output}
        Should Be Equal As Strings
        ...    ${output}
        ...    ${teldat_cellsradio_test.result}
        ...    Wrong output result for compliance of ${teldat_cellsradio_test.result}{\n}Command output:{\n}${output}{\n}{\n}{\n}
    END