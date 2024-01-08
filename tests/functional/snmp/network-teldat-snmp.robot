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
...                         result=CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] | 'modules.cellradio.detected.count'=3;;;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;;;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;;;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;;;0;

# Test cellsradio mode with filter-cell-id option set to a fake value
&{teldat_cellsradio_test2}
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
...                         filtercellid='359072066403821'
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
...                         result=CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] | 'modules.cellradio.detected.count'=3;;;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;;;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;;;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;;;0;

# Test cellsradio mode with custom-perfdata-instances option set to '%(cellId) %(simIcc)'
&{teldat_cellsradio_test4}
...                         filtercellid=
...                         customperfdatainstances='%(cellId) %(simIcc)'
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
...                         result=CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] | 'modules.cellradio.detected.count'=3;;;0; '359072066403821~89330122115801091660#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~89330122115801091660#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~89330122115801091660#module.cellradio.snr.db'=-1;;;0; '359072066403821~89330122115801091660#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~89330122115801091660#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~89330122115801091660#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~89330122115801091660#module.cellradio.snr.db'=-1;;;0; '359072066403821~89330122115801091660#module.cellradio.csq.dbm'=-73;;;0;

# Test cellsradio mode with warning-modules-cellradio-detected option set to a 2
&{teldat_cellsradio_test5}
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
...                         result=CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: Number of cellular radio modules detected: 3 - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] | 'modules.cellradio.detected.count'=3;0:2;;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;;;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;;;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;;;0;

# Test cellsradio mode with critical-modules-cellradio-detected option set to a 2
&{teldat_cellsradio_test6}
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
...                         result=CRITICAL: Number of cellular radio modules detected: 3 - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] | 'modules.cellradio.detected.count'=3;;0:2;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;;;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;;;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;;;0;

# Test cellsradio mode with warning-module-cellradio-rsrp option set to a -100
&{teldat_cellsradio_test7}
...                         filtercellid=
...                         customperfdatainstances=
...                         unknownstatus=
...                         warningstatus=
...                         criticalstatus=
...                         warningmodulescellradiodetected=
...                         criticalmodulescellradiodetected=
...                         warningmodulecellradiorsrp=-100
...                         criticalmodulecellradiorsrp=
...                         warningmodulecellradiorsrq=
...                         criticalmodulecellradiorsrq=
...                         warningmodulecellradiorscp=
...                         criticalmodulecellradiorscp=
...                         warningmodulecellradiocsq=
...                         criticalmodulecellradiocsq=
...                         warningmodulecellradiosnr=
...                         criticalmodulecellradiosnr=
...                         result=CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] - rsrp: -114 dBm - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] rsrp: -114 dBm | 'modules.cellradio.detected.count'=3;;;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;0:-100;;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;;;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;0:-100;;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;;;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;;;0;

# Test cellsradio mode with critical-module-cellradio-rsrp option set to a -100
&{teldat_cellsradio_test8}
...                         filtercellid=
...                         customperfdatainstances=
...                         unknownstatus=
...                         warningstatus=
...                         criticalstatus=
...                         warningmodulescellradiodetected=
...                         criticalmodulescellradiodetected=
...                         warningmodulecellradiorsrp=
...                         criticalmodulecellradiorsrp=-100
...                         warningmodulecellradiorsrq=
...                         criticalmodulecellradiorsrq=
...                         warningmodulecellradiorscp=
...                         criticalmodulecellradiorscp=
...                         warningmodulecellradiocsq=
...                         criticalmodulecellradiocsq=
...                         warningmodulecellradiosnr=
...                         criticalmodulecellradiosnr=
...                         result=CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] rsrp: -114 dBm - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - rsrp: -114 dBm - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] | 'modules.cellradio.detected.count'=3;;;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;;0:-100;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;;;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;;0:-100;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;;;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;;;0;

# Test cellsradio mode with warning-module-cellradio-rsrq option set to a -10
&{teldat_cellsradio_test9}
...                         filtercellid=
...                         customperfdatainstances=
...                         unknownstatus=
...                         warningstatus=
...                         criticalstatus=
...                         warningmodulescellradiodetected=
...                         criticalmodulescellradiodetected=
...                         warningmodulecellradiorsrp=
...                         criticalmodulecellradiorsrp=
...                         warningmodulecellradiorsrq=-10
...                         criticalmodulecellradiorsrq=
...                         warningmodulecellradiorscp=
...                         criticalmodulecellradiorscp=
...                         warningmodulecellradiocsq=
...                         criticalmodulecellradiocsq=
...                         warningmodulecellradiosnr=
...                         criticalmodulecellradiosnr=
...                         result=CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] - rsrq: -18 dBm - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] rsrq: -18 dBm | 'modules.cellradio.detected.count'=3;;;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;0:-10;;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;;;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;0:-10;;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;;;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;;;0;

# Test cellsradio mode with critical-module-cellradio-rsrq option set to a -10
&{teldat_cellsradio_test10}
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
...                         criticalmodulecellradiorsrq=-10
...                         warningmodulecellradiorscp=
...                         criticalmodulecellradiorscp=
...                         warningmodulecellradiocsq=
...                         criticalmodulecellradiocsq=
...                         warningmodulecellradiosnr=
...                         criticalmodulecellradiosnr=
...                         result=CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] rsrq: -18 dBm - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - rsrq: -18 dBm - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] | 'modules.cellradio.detected.count'=3;;;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;;0:-10;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;;;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;;0:-10;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;;;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;;;0;

@{teldat_cellsradio_tests}
...                         &{teldat_cellsradio_test1}
...                         &{teldat_cellsradio_test2}
...                         &{teldat_cellsradio_test3}
...                         &{teldat_cellsradio_test4}
...                         &{teldat_cellsradio_test5}
...                         &{teldat_cellsradio_test6}
...                         &{teldat_cellsradio_test7}
...                         &{teldat_cellsradio_test8}
...                         &{teldat_cellsradio_test9}
...                         &{teldat_cellsradio_test10}

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
        ...    --snmp-community=network-teldat-snmp
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
        ${length}    Get Length    ${teldat_cellsradio_test.warningmodulecellradiorsrp}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --warning-module-cellradio-rsrp=${teldat_cellsradio_test.warningmodulecellradiorsrp}
        END
        ${length}    Get Length    ${teldat_cellsradio_test.criticalmodulecellradiorsrp}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --critical-module-cellradio-rsrp=${teldat_cellsradio_test.criticalmodulecellradiorsrp}
        END
        ${length}    Get Length    ${teldat_cellsradio_test.warningmodulecellradiorsrq}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --warning-module-cellradio-rsrq=${teldat_cellsradio_test.warningmodulecellradiorsrq}
        END
        ${length}    Get Length    ${teldat_cellsradio_test.criticalmodulecellradiorsrq}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --critical-module-cellradio-rsrq=${teldat_cellsradio_test.criticalmodulecellradiorsrq}
        END
        ${output}    Run    ${command}
        Log To Console    ${command}
        ${output}    Strip String    ${output}
        Should Be Equal As Strings
        ...    ${output}
        ...    ${teldat_cellsradio_test.result}
        ...    Wrong output result for compliance of ${teldat_cellsradio_test.result}{\n}Command output:{\n}${output}{\n}{\n}{\n}
    END