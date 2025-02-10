*** Settings ***
Documentation       Check Chapsvision antivirus
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::chapsvision::crossing::snmp::plugin


*** Test Cases ***
Antivirus ${tc}
    [Tags]    network    chapvision    crossing
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=antivirus
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/chapsvision/crossing/snmp/chapsvision_old_oids
    ...    --snmp-timeout=1
    ...    ${extra_options}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Match Regexp    ${output}    ${expected_result}

    Examples:        tc    extra_options                         expected_result    --
            ...      1     ${empty}                              OK: All antivirus are ok \\\\| 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 008-old#antivirus.license.expires.seconds'=\\\\d+s;;;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 106-old#antivirus.license.expires.seconds'=\\\\d+s;;;0;
            ...      2     --warning-version='1'                 WARNING: antivirus 'Anonymized 008-old' version: 27031 - antivirus 'Anonymized 106-old' version: 26868 \\\\| 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 008-old#antivirus.license.expires.seconds'=\\\\d+s;;;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 106-old#antivirus.license.expires.seconds'=\\\\d+s;;;0;
            ...      3     --critical-version='2'                CRITICAL: antivirus 'Anonymized 008-old' version: 27031 - antivirus 'Anonymized 106-old' version: 26868 \\\\| 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 008-old#antivirus.license.expires.seconds'=\\\\d+s;;;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 106-old#antivirus.license.expires.seconds'=\\\\d+s;;;0;
            ...      4     --warning-license-expires='1'         WARNING: antivirus 'Anonymized 008-old' license expires in \\\\d+y \\\\d+M \\\\d+w \\\\d+d \\\\d+h \\\\d+m \\\\d+s - antivirus 'Anonymized 106-old' license expires in \\\\d+y \\\\d+M \\\\d+w \\\\d+d \\\\d+h \\\\d+m \\\\d+s \\\\| 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 008-old#antivirus.license.expires.seconds'=\\\\d+s;0:1;;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 106-old#antivirus.license.expires.seconds'=\\\\d+s;0:1;;0;
            ...      5     --critical-license-expires='1'        CRITICAL: antivirus 'Anonymized 008-old' license expires in \\\\d+y \\\\d+M \\\\d+w \\\\d+d \\\\d+h \\\\d+m \\\\d+s - antivirus 'Anonymized 106-old' license expires in \\\\d+y \\\\d+M \\\\d+w \\\\d+d \\\\d+h \\\\d+m \\\\d+s \\\\| 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 008-old#antivirus.license.expires.seconds'=\\\\d+s;;0:1;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 106-old#antivirus.license.expires.seconds'=\\\\d+s;;0:1;0;
            ...      6     --warning-database-last-update='1'    WARNING: antivirus 'Anonymized 008-old' database last update \\\\d+M \\\\d+w \\\\d+d \\\\d+h \\\\d+m \\\\d+s - antivirus 'Anonymized 106-old' database last update \\\\d+M \\\\d+w \\\\d+d \\\\d+h \\\\d+m \\\\d+s \\\\| 'antivirus.database.lastupdate.seconds'=\\\\d+s;0:1;;0; 'Anonymized 008-old#antivirus.license.expires.seconds'=\\\\d+s;;;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;0:1;;0; 'Anonymized 106-old#antivirus.license.expires.seconds'=\\\\d+s;;;0;
            ...      7     --critical-database-last-update='1'   CRITICAL: antivirus 'Anonymized 008-old' database last update \\\\d+M \\\\d+w \\\\d+d \\\\d+h \\\\d+m \\\\d+s - antivirus 'Anonymized 106-old' database last update \\\\d+M \\\\d+w \\\\d+d \\\\d+h \\\\d+m \\\\d+s \\\\| 'antivirus.database.lastupdate.seconds'=\\\\d+s;;0:1;0; 'Anonymized 008-old#antivirus.license.expires.seconds'=\\\\d+s;;;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;;0:1;0; 'Anonymized 106-old#antivirus.license.expires.seconds'=\\\\d+s;;;0;