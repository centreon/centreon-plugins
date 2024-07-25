*** Settings ***
Documentation       Network Teldat SNMP plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                          ${CENTREON_PLUGINS} --plugin=network::teldat::snmp::plugin


*** Test Cases ***
Network Teldat SNMP cells radio ${tc}
    [Documentation]    Network Teldat SNMP cells radio
    [Tags]    network    teldat    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cells-radio
    ...    --hostname=127.0.0.1
    ...    --snmp-version=2c
    ...    --snmp-port=2024
    ...    --snmp-community=network/teldat/snmp/teldat
    ${length}    Get Length    ${filtercellid}
    IF    ${length} > 0
        ${command}    Catenate    ${command}    --filter-cell-id=${filtercellid}
    END
    ${length}    Get Length    ${customperfdatainstances}
    IF    ${length} > 0
        ${command}    Catenate
        ...    ${command}
        ...    --custom-perfdata-instances=${customperfdatainstances}
    END
    ${length}    Get Length    ${unknownstatus}
    IF    ${length} > 0
        ${command}    Catenate    ${command}    --unknown-status=${unknownstatus}
    END
    ${length}    Get Length    ${warningstatus}
    IF    ${length} > 0
        ${command}    Catenate    ${command}    --warning-status=${warningstatus}
    END
    ${length}    Get Length    ${criticalstatus}
    IF    ${length} > 0
        ${command}    Catenate    ${command}    --critical-status=${criticalstatus}
    END
    ${length}    Get Length    ${warningmodulescellradiodetected}
    IF    ${length} > 0
        ${command}    Catenate
        ...    ${command}
        ...    --warning-modules-cellradio-detected=${warningmodulescellradiodetected}
    END
    ${length}    Get Length    ${criticalmodulescellradiodetected}
    IF    ${length} > 0
        ${command}    Catenate
        ...    ${command}
        ...    --critical-modules-cellradio-detected=${criticalmodulescellradiodetected}
    END
    ${length}    Get Length    ${warningmodulecellradiorsrp}
    IF    ${length} > 0
        ${command}    Catenate
        ...    ${command}
        ...    --warning-module-cellradio-rsrp=${warningmodulecellradiorsrp}
    END
    ${length}    Get Length    ${criticalmodulecellradiorsrp}
    IF    ${length} > 0
        ${command}    Catenate
        ...    ${command}
        ...    --critical-module-cellradio-rsrp=${criticalmodulecellradiorsrp}
    END
    ${length}    Get Length    ${warningmodulecellradiorsrq}
    IF    ${length} > 0
        ${command}    Catenate
        ...    ${command}
        ...    --warning-module-cellradio-rsrq=${warningmodulecellradiorsrq}
    END
    ${length}    Get Length    ${criticalmodulecellradiorsrq}
    IF    ${length} > 0
        ${command}    Catenate
        ...    ${command}
        ...    --critical-module-cellradio-rsrq=${criticalmodulecellradiorsrq}
    END
    ${length}    Get Length    ${warningmodulecellradiorscp}
    IF    ${length} > 0
        ${command}    Catenate
        ...    ${command}
        ...    --warning-module-cellradio-rscp=${warningmodulecellradiorscp}
    END
    ${length}    Get Length    ${criticalmodulecellradiorscp}
    IF    ${length} > 0
        ${command}    Catenate
        ...    ${command}
        ...    --critical-module-cellradio-rscp=${criticalmodulecellradiorscp}
    END
    ${length}    Get Length    ${warningmodulecellradiocsq}
    IF    ${length} > 0
        ${command}    Catenate
        ...    ${command}
        ...    --warning-module-cellradio-csq=${warningmodulecellradiocsq}
    END
    ${length}    Get Length    ${criticalmodulecellradiocsq}
    IF    ${length} > 0
        ${command}    Catenate
        ...    ${command}
        ...    --critical-module-cellradio-csq=${criticalmodulecellradiocsq}
    END
    ${length}    Get Length    ${warningmodulecellradiosnr}
    IF    ${length} > 0
        ${command}    Catenate
        ...    ${command}
        ...    --warning-module-cellradio-snr=${warningmodulecellradiosnr}
    END
    ${length}    Get Length    ${criticalmodulecellradiosnr}
    IF    ${length} > 0
        ${command}    Catenate
        ...    ${command}
        ...    --critical-module-cellradio-snr=${criticalmodulecellradiosnr}
    END
    ${output}    Run    ${command}
    Log To Console    .    no_newline=true
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${result}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected:\n${result}\n
    ...    values=False
    ...    collapse_spaces=True
    
    
    Examples:    tc   filtercellid        customperfdatainstances     unknownstatus    warningstatus    criticalstatus                                warningmodulescellradiodetected    criticalmodulescellradiodetected    warningmodulecellradiorsrp    criticalmodulecellradiorsrp    warningmodulecellradiorsrq    criticalmodulecellradiorsrq    warningmodulecellradiorscp    criticalmodulecellradiorscp    warningmodulecellradiocsq    criticalmodulecellradiocsq    warningmodulecellradiosnr    criticalmodulecellradiosnr    result    --
            ...  1    ${EMPTY}            ${EMPTY}                    ${EMPTY}         ${EMPTY}         ${EMPTY}                                      ${EMPTY}                           ${EMPTY}                            ${EMPTY}                      ${EMPTY}                       ${EMPTY}                      ${EMPTY}                       ${EMPTY}                       ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] | 'modules.cellradio.detected.count'=3;;;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;;;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;;;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;;;0;
            ...  2    toto                ${EMPTY}                    ${EMPTY}         ${EMPTY}         ${EMPTY}                                      ${EMPTY}                           ${EMPTY}                            ${EMPTY}                      ${EMPTY}                       ${EMPTY}                      ${EMPTY}                       ${EMPTY}                       ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      UNKNOWN: No Cell ID found matching with filter : toto
            ...  3    '359072066403821'   ${EMPTY}                    ${EMPTY}         ${EMPTY}         ${EMPTY}                                      ${EMPTY}                           ${EMPTY}                            ${EMPTY}                      ${EMPTY}                       ${EMPTY}                      ${EMPTY}                       ${EMPTY}                       ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] | 'modules.cellradio.detected.count'=3;;;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;;;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;;;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;;;0;
            ...  4    ${EMPTY}            '%(cellId) %(simIcc)'       ${EMPTY}         ${EMPTY}         ${EMPTY}                                      ${EMPTY}                           ${EMPTY}                            ${EMPTY}                      ${EMPTY}                       ${EMPTY}                      ${EMPTY}                       ${EMPTY}                       ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] | 'modules.cellradio.detected.count'=3;;;0; '359072066403821~89330122115801091660#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~89330122115801091660#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~89330122115801091660#module.cellradio.snr.db'=-1;;;0; '359072066403821~89330122115801091660#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~89330122115801091660#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~89330122115801091660#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~89330122115801091660#module.cellradio.snr.db'=-1;;;0; '359072066403821~89330122115801091660#module.cellradio.csq.dbm'=-73;;;0;
            ...  5    ${EMPTY}            ${EMPTY}                    ${EMPTY}         ${EMPTY}         ${EMPTY}                                      2                                  ${EMPTY}                            ${EMPTY}                      ${EMPTY}                       ${EMPTY}                      ${EMPTY}                       ${EMPTY}                       ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: Number of cellular radio modules detected: 3 - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] | 'modules.cellradio.detected.count'=3;0:2;;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;;;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;;;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;;;0;
            ...  6    ${EMPTY}            ${EMPTY}                    ${EMPTY}         ${EMPTY}         ${EMPTY}                                      ${EMPTY}                           2                                   ${EMPTY}                      ${EMPTY}                       ${EMPTY}                      ${EMPTY}                       ${EMPTY}                       ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      CRITICAL: Number of cellular radio modules detected: 3 - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] | 'modules.cellradio.detected.count'=3;;0:2;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;;;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;;;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;;;0;
            ...  7    ${EMPTY}            ${EMPTY}                    ${EMPTY}         ${EMPTY}         ${EMPTY}                                      ${EMPTY}                           ${EMPTY}                            -100                          ${EMPTY}                       ${EMPTY}                      ${EMPTY}                       ${EMPTY}                       ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] - rsrp: -114 dBm - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] rsrp: -114 dBm | 'modules.cellradio.detected.count'=3;;;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;0:-100;;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;;;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;0:-100;;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;;;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;;;0;         
            ...  8    ${EMPTY}            ${EMPTY}                    ${EMPTY}         ${EMPTY}         ${EMPTY}                                      ${EMPTY}                           ${EMPTY}                            ${EMPTY}                      -100                           ${EMPTY}                      ${EMPTY}                       ${EMPTY}                       ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] rsrp: -114 dBm - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - rsrp: -114 dBm - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] | 'modules.cellradio.detected.count'=3;;;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;;0:-100;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;;;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;;0:-100;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;;;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;;;0;           
            ...  9    ${EMPTY}            ${EMPTY}                    ${EMPTY}         ${EMPTY}         ${EMPTY}                                      ${EMPTY}                           ${EMPTY}                            ${EMPTY}                      ${EMPTY}                       10                            ${EMPTY}                       ${EMPTY}                       ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] - rsrq: -18 dBm - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] rsrq: -18 dBm | 'modules.cellradio.detected.count'=3;;;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;0:10;;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;;;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;0:10;;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;;;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;;;0;          
            ...  10   ${EMPTY}            ${EMPTY}                    ${EMPTY}         ${EMPTY}         ${EMPTY}                                      ${EMPTY}                           ${EMPTY}                            ${EMPTY}                      ${EMPTY}                       ${EMPTY}                      10                             ${EMPTY}                       ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] rsrq: -18 dBm - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - rsrq: -18 dBm - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] | 'modules.cellradio.detected.count'=3;;;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;;0:10;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;;;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;;0:10;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;;;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;;;0;          
            ...  11   ${EMPTY}            ${EMPTY}                    ${EMPTY}         ${EMPTY}         ${EMPTY}                                      ${EMPTY}                           ${EMPTY}                            ${EMPTY}                      ${EMPTY}                       ${EMPTY}                      ${EMPTY}                       ${EMPTY}                       ${EMPTY}                      10                           ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] - csq: -73 dBm - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] csq: -73 dBm | 'modules.cellradio.detected.count'=3;;;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;;;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;0:10;;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;;;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;0:10;;0;          
            ...  12   ${EMPTY}            ${EMPTY}                    ${EMPTY}         ${EMPTY}         ${EMPTY}                                      ${EMPTY}                           ${EMPTY}                            ${EMPTY}                      ${EMPTY}                       ${EMPTY}                      ${EMPTY}                       ${EMPTY}                       ${EMPTY}                      ${EMPTY}                     10                            ${EMPTY}                     ${EMPTY}                      CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] csq: -73 dBm - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - csq: -73 dBm - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] | 'modules.cellradio.detected.count'=3;;;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;;;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;;0:10;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;;;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;;0:10;0;      
            ...  13   ${EMPTY}            ${EMPTY}                    ${EMPTY}         ${EMPTY}         ${EMPTY}                                      ${EMPTY}                           ${EMPTY}                            ${EMPTY}                      ${EMPTY}                       ${EMPTY}                      ${EMPTY}                       ${EMPTY}                       ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      0                            ${EMPTY}                      CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] - snr: -1 dB - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] snr: -1 dB | 'modules.cellradio.detected.count'=3;;;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;0:0;;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;0:0;;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;;;0;      
            ...  14   ${EMPTY}            ${EMPTY}                    ${EMPTY}         ${EMPTY}         ${EMPTY}                                      ${EMPTY}                           ${EMPTY}                            ${EMPTY}                      ${EMPTY}                       ${EMPTY}                      ${EMPTY}                       ${EMPTY}                       ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      ${EMPTY}                     0                             CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] snr: -1 dB - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: PHENIX] sim status: LOCKED [imsi: 208015606540916] [interface state: connect(9)] - snr: -1 dB - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] WARNING: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] | 'modules.cellradio.detected.count'=3;;;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;;0:0;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;;0:0;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;;;0;
            ...  15   ${EMPTY}            ${EMPTY}                    ${EMPTY}         ${EMPTY}         '\%{interfaceState} =~ /disconnect/'          ${EMPTY}                           ${EMPTY}                            ${EMPTY}                      ${EMPTY}                       ${EMPTY}                      ${EMPTY}                       ${EMPTY}                       ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      ${EMPTY}                     ${EMPTY}                      CRITICAL: cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: OK [imsi: 208015606540916] [interface state: disconnect(1)] - cellular radio module '359072066403821' [sim icc: 89330122115801091660, operator: N/A] sim status: DETECTING [imsi: 208015606540916] [interface state: disconnect(1)] | 'modules.cellradio.detected.count'=3;;;0; '359072066403821~N/A#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~N/A#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~N/A#module.cellradio.snr.db'=-1;;;0; '359072066403821~N/A#module.cellradio.csq.dbm'=-73;;;0; '359072066403821~PHENIX#module.cellradio.rsrp.dbm'=-114;;;0; '359072066403821~PHENIX#module.cellradio.rsrq.dbm'=-18;;;0; '359072066403821~PHENIX#module.cellradio.snr.db'=-1;;;0; '359072066403821~PHENIX#module.cellradio.csq.dbm'=-73;;;0;
        
Network Teldat SNMP CPU ${tc}
    [Documentation]    Network Teldat SNMP CPU
    [Tags]    network    teldat    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cpu
    ...    --hostname=127.0.0.1
    ...    --snmp-version=2c
    ...    --snmp-port=2024
    ...    --snmp-community=network/teldat/snmp/teldat
    ${length}    Get Length    ${warningcpuutilization5s}
    IF    ${length} > 0
        ${command}    Catenate
        ...    ${command}
        ...    --warning-cpu-utilization-5s=${warningcpuutilization5s}
        END
    ${length}    Get Length    ${criticalcpuutilization5s}
    IF    ${length} > 0
        ${command}    Catenate
        ...    ${command}
        ...    --critical-cpu-utilization-5s=${criticalcpuutilization5s}
    END
    ${length}    Get Length    ${warningcpuutilization1m}
    IF    ${length} > 0
        ${command}    Catenate
        ...    ${command}
        ...    --warning-cpu-utilization-1m=${warningcpuutilization1m}
    END
    ${length}    Get Length    ${criticalcpuutilization1m}
    IF    ${length} > 0
        ${command}    Catenate
        ...    ${command}
        ...    --critical-cpu-utilization-1m=${criticalcpuutilization1m}
    END
    ${length}    Get Length    ${warningcpuutilization5m}
    IF    ${length} > 0
        ${command}    Catenate
        ...    ${command}
        ...    --warning-cpu-utilization-5m=${warningcpuutilization5m}
    END
    ${length}    Get Length    ${criticalcpuutilization5m}
    IF    ${length} > 0
        ${command}    Catenate
        ...    ${command}
        ...    --critical-cpu-utilization-5m=${criticalcpuutilization5m}
    END
    ${output}    Run    ${command}
    Log To Console    .    no_newline=true
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${result}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected:\n${result}\n
    ...    values=False
    ...    collapse_spaces=True

    Examples:         tc  warningcpuutilization5s  criticalcpuutilization5s  warningcpuutilization1m  criticalcpuutilization1m  warningcpuutilization5m  criticalcpuutilization5m  result    --
            ...       1   ${EMPTY}                 ${EMPTY}                  ${EMPTY}                 ${EMPTY}                  ${EMPTY}                 ${EMPTY}                  OK: cpu average usage: 1.00 % (5s), 1.00 % (1m), 1.00 % (5m) | 'cpu.utilization.5s.percentage'=1.00%;;;0;100 'cpu.utilization.1m.percentage'=1.00%;;;0;100 'cpu.utilization.15m.percentage'=1.00%;;;0;100
            ...       2   0.5                      ${EMPTY}                  ${EMPTY}                 ${EMPTY}                  ${EMPTY}                 ${EMPTY}                  WARNING: cpu average usage: 1.00 % (5s) | 'cpu.utilization.5s.percentage'=1.00%;0:0.5;;0;100 'cpu.utilization.1m.percentage'=1.00%;;;0;100 'cpu.utilization.15m.percentage'=1.00%;;;0;100
            ...       3   ${EMPTY}                 0.5                       ${EMPTY}                 ${EMPTY}                  ${EMPTY}                 ${EMPTY}                  CRITICAL: cpu average usage: 1.00 % (5s) | 'cpu.utilization.5s.percentage'=1.00%;;0:0.5;0;100 'cpu.utilization.1m.percentage'=1.00%;;;0;100 'cpu.utilization.15m.percentage'=1.00%;;;0;100
            ...       4   ${EMPTY}                 ${EMPTY}                  0.5                      ${EMPTY}                  ${EMPTY}                 ${EMPTY}                  WARNING: cpu average usage: 1.00 % (1m) | 'cpu.utilization.5s.percentage'=1.00%;;;0;100 'cpu.utilization.1m.percentage'=1.00%;0:0.5;;0;100 'cpu.utilization.15m.percentage'=1.00%;;;0;100
            ...       5   ${EMPTY}                 ${EMPTY}                  ${EMPTY}                 0.5                       ${EMPTY}                 ${EMPTY}                  CRITICAL: cpu average usage: 1.00 % (1m) | 'cpu.utilization.5s.percentage'=1.00%;;;0;100 'cpu.utilization.1m.percentage'=1.00%;;0:0.5;0;100 'cpu.utilization.15m.percentage'=1.00%;;;0;100
            ...       6   ${EMPTY}                 ${EMPTY}                  ${EMPTY}                 ${EMPTY}                  0.5                      ${EMPTY}                  WARNING: cpu average usage: 1.00 % (5m) | 'cpu.utilization.5s.percentage'=1.00%;;;0;100 'cpu.utilization.1m.percentage'=1.00%;;;0;100 'cpu.utilization.15m.percentage'=1.00%;0:0.5;;0;100
            ...       7   ${EMPTY}                 ${EMPTY}                  ${EMPTY}                 ${EMPTY}                  ${EMPTY}                 0.5                       CRITICAL: cpu average usage: 1.00 % (5m) | 'cpu.utilization.5s.percentage'=1.00%;;;0;100 'cpu.utilization.1m.percentage'=1.00%;;;0;100 'cpu.utilization.15m.percentage'=1.00%;;0:0.5;0;100

Network Teldat SNMP Memory ${tc}
    [Documentation]    Network Teldat SNMP memory
    [Tags]    network    teldat    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=memory
    ...    --hostname=127.0.0.1
    ...    --snmp-version=2c
    ...    --snmp-port=2024
    ...    --snmp-community=network/teldat/snmp/teldat
    ${length}    Get Length    ${warningusage}
    IF    ${length} > 0
        ${command}    Catenate    ${command}    --warning-usage=${warningusage}
    END
    ${length}    Get Length    ${criticalusage}
    IF    ${length} > 0
        ${command}    Catenate    ${command}    --critical-usage=${criticalusage}
    END
    ${length}    Get Length    ${warningusagefree}
    IF    ${length} > 0
        ${command}    Catenate    ${command}    --warning-usage-free=${warningusagefree}
    END
    ${length}    Get Length    ${criticalusagefree}
    IF    ${length} > 0
        ${command}    Catenate    ${command}    --critical-usage-free=${criticalusagefree}
    END
    ${length}    Get Length    ${warningusageprct}
    IF    ${length} > 0
        ${command}    Catenate    ${command}    --warning-usage-prct=${warningusageprct}
    END
    ${length}    Get Length    ${criticalusageprct}
    IF    ${length} > 0
        ${command}    Catenate    ${command}    --critical-usage-prct=${criticalusageprct}
    END
    ${output}    Run    ${command}
    Log To Console    .    no_newline=true
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True

    Examples:         tc  warningusage  criticalusage  warningusagefree  criticalusagefree  warningusageprct  criticalusageprct    expected_result    --
            ...       1   ${EMPTY}      ${EMPTY}       ${EMPTY}          ${EMPTY}           ${EMPTY}           ${EMPTY}            OK: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;;;0;268435456 'system#memory.free.bytes'=163015856B;;;0;268435456 'system#memory.usage.percentage'=39.27%;;;0;100
            ...       2   100           ${EMPTY}       ${EMPTY}          ${EMPTY}           ${EMPTY}           ${EMPTY}            WARNING: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;0:100;;0;268435456 'system#memory.free.bytes'=163015856B;;;0;268435456 'system#memory.usage.percentage'=39.27%;;;0;100
            ...       3   ${EMPTY}      100            ${EMPTY}          ${EMPTY}           ${EMPTY}           ${EMPTY}            CRITICAL: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;;0:100;0;268435456 'system#memory.free.bytes'=163015856B;;;0;268435456 'system#memory.usage.percentage'=39.27%;;;0;100
            ...       4   ${EMPTY}      ${EMPTY}       100               ${EMPTY}           ${EMPTY}           ${EMPTY}            WARNING: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;;;0;268435456 'system#memory.free.bytes'=163015856B;0:100;;0;268435456 'system#memory.usage.percentage'=39.27%;;;0;100
            ...       5   ${EMPTY}      ${EMPTY}       ${EMPTY}          100                ${EMPTY}           ${EMPTY}            CRITICAL: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;;;0;268435456 'system#memory.free.bytes'=163015856B;;0:100;0;268435456 'system#memory.usage.percentage'=39.27%;;;0;100
            ...       6   ${EMPTY}      ${EMPTY}       ${EMPTY}          ${EMPTY}           30                 ${EMPTY}            WARNING: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;;;0;268435456 'system#memory.free.bytes'=163015856B;;;0;268435456 'system#memory.usage.percentage'=39.27%;0:30;;0;100
            ...       7   ${EMPTY}      ${EMPTY}       ${EMPTY}          ${EMPTY}           ${EMPTY}           30                  CRITICAL: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;;;0;268435456 'system#memory.free.bytes'=163015856B;;;0;268435456 'system#memory.usage.percentage'=39.27%;;0:30;0;100                 