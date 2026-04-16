*** Settings ***
Documentation       Check Chapsvision antivirus

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${cmd}      ${CENTREON_PLUGINS}
...         --plugin=network::chapsvision::crossing::snmp::plugin
...         --mode=antivirus
...         --hostname=${HOSTNAME}
...         --snmp-version=${SNMPVERSION}
...         --snmp-port=${SNMPPORT}
...         --snmp-timeout=1


*** Test Cases ***
Antivirus new ${tc}
    [Documentation]    Check the antivirus with the new OIDs
    [Tags]    network    chapvision    crossing
    ${command}    Catenate
    ...    ${cmd}
    ...    --snmp-community=network/chapsvision/crossing/snmp/chapsvision
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:        tc    extra_options                         expected_result    --
            ...      1     ${empty}                              OK: All antivirus are ok | 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 008#antivirus.license.expires.seconds'=\\\\d+s;;;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 106#antivirus.license.expires.seconds'=\\\\d+s;;;0;
            ...      2     --warning-version='1'                 WARNING: antivirus 'Anonymized 008' version: 27031 - antivirus 'Anonymized 106' version: 26868 | 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 008#antivirus.license.expires.seconds'=\\\\d+s;;;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 106#antivirus.license.expires.seconds'=\\\\d+s;;;0;
            ...      3     --critical-version='2'                CRITICAL: antivirus 'Anonymized 008' version: 27031 - antivirus 'Anonymized 106' version: 26868 | 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 008#antivirus.license.expires.seconds'=\\\\d+s;;;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 106#antivirus.license.expires.seconds'=\\\\d+s;;;0;
            ...      4     --warning-license-expires='1'         WARNING: antivirus 'Anonymized 008' license expires in [\\\\dyMwdms ]*- antivirus 'Anonymized 106' license expires in [\\\\dyMwdms ]*| 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 008#antivirus.license.expires.seconds'=\\\\d+s;0:1;;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 106#antivirus.license.expires.seconds'=\\\\d+s;0:1;;0;
            ...      5     --critical-license-expires='1'        CRITICAL: antivirus 'Anonymized 008' license expires in [\\\\dyMwdms ]*- antivirus 'Anonymized 106' license expires in [\\\\dyMwdms ]*| 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 008#antivirus.license.expires.seconds'=\\\\d+s;;0:1;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 106#antivirus.license.expires.seconds'=\\\\d+s;;0:1;0;
            ...      6     --warning-database-last-update='1'    WARNING: antivirus 'Anonymized 008' database last update [\\\\dyMwdms ]*- antivirus 'Anonymized 106' database last update [\\\\dyMwdms ]*| 'antivirus.database.lastupdate.seconds'=\\\\d+s;0:1;;0; 'Anonymized 008#antivirus.license.expires.seconds'=\\\\d+s;;;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;0:1;;0; 'Anonymized 106#antivirus.license.expires.seconds'=\\\\d+s;;;0;
            ...      7     --critical-database-last-update='1'   CRITICAL: antivirus 'Anonymized 008' database last update [\\\\dyMwdms ]*- antivirus 'Anonymized 106' database last update [\\\\dyMwdms ]*| 'antivirus.database.lastupdate.seconds'=\\\\d+s;;0:1;0; 'Anonymized 008#antivirus.license.expires.seconds'=\\\\d+s;;;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;;0:1;0; 'Anonymized 106#antivirus.license.expires.seconds'=\\\\d+s;;;0;

Antivirus old ${tc}
    [Documentation]    Check the antivirus with the old OIDs
    [Tags]    network    chapvision    crossing
    ${command}    Catenate
    ...    ${cmd}
    ...    --snmp-community=network/chapsvision/crossing/snmp/chapsvision_old_oids
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:        tc    extra_options                         expected_result    --
            ...      1     ${empty}                              OK: All antivirus are ok | 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 008-old#antivirus.license.expires.seconds'=\\\\d+s;;;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 106-old#antivirus.license.expires.seconds'=\\\\d+s;;;0;
            ...      2     --warning-version='1'                 WARNING: antivirus 'Anonymized 008-old' version: 27031 - antivirus 'Anonymized 106-old' version: 26868 | 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 008-old#antivirus.license.expires.seconds'=\\\\d+s;;;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 106-old#antivirus.license.expires.seconds'=\\\\d+s;;;0;
            ...      3     --critical-version='2'                CRITICAL: antivirus 'Anonymized 008-old' version: 27031 - antivirus 'Anonymized 106-old' version: 26868 | 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 008-old#antivirus.license.expires.seconds'=\\\\d+s;;;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 106-old#antivirus.license.expires.seconds'=\\\\d+s;;;0;
            ...      4     --warning-license-expires='1'         WARNING: antivirus 'Anonymized 008-old' license expires in [\\\\dyMwdms ]* - antivirus 'Anonymized 106-old' license expires in [\\\\dyMwdms ]*| 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 008-old#antivirus.license.expires.seconds'=\\\\d+s;0:1;;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 106-old#antivirus.license.expires.seconds'=\\\\d+s;0:1;;0;
            ...      5     --critical-license-expires='1'        CRITICAL: antivirus 'Anonymized 008-old' license expires in [\\\\dyMwdms ]* - antivirus 'Anonymized 106-old' license expires in [\\\\dyMwdms ]*| 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 008-old#antivirus.license.expires.seconds'=\\\\d+s;;0:1;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;;;0; 'Anonymized 106-old#antivirus.license.expires.seconds'=\\\\d+s;;0:1;0;
            ...      6     --warning-database-last-update='1'    WARNING: antivirus 'Anonymized 008-old' database last update [\\\\dyMwdms ]*- antivirus 'Anonymized 106-old' database last update [\\\\dyMwdms ]*| 'antivirus.database.lastupdate.seconds'=\\\\d+s;0:1;;0; 'Anonymized 008-old#antivirus.license.expires.seconds'=\\\\d+s;;;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;0:1;;0; 'Anonymized 106-old#antivirus.license.expires.seconds'=\\\\d+s;;;0;
            ...      7     --critical-database-last-update='1'   CRITICAL: antivirus 'Anonymized 008-old' database last update [\\\\dyMwdms ]*- antivirus 'Anonymized 106-old' database last update [\\\\dyMwdms ]*| 'antivirus.database.lastupdate.seconds'=\\\\d+s;;0:1;0; 'Anonymized 008-old#antivirus.license.expires.seconds'=\\\\d+s;;;0; 'antivirus.database.lastupdate.seconds'=\\\\d+s;;0:1;0; 'Anonymized 106-old#antivirus.license.expires.seconds'=\\\\d+s;;;0;
