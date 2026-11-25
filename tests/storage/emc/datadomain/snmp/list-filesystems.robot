*** Settings ***
Documentation       Check EMC DataDomain in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=storage::emc::datadomain::snmp::plugin


*** Test Cases ***
list-filesystems ${tc}
    [Tags]    snmp    storage
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-filesystems
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=storage/emc/datadomain/snmp/${community}
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    community
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    slim-datadomain
    ...    --verbose
    ...    List filesystems: [name = /ddvar][tier = Active Tier][total = 50036368998][used = 11274289152] [name = /ddvar/core][tier = Active Tier][total = 584867171532][used = 107374182] [name = Anonymized 056][tier = Active Tier][total = 90263462189465][used = 53328461430784] [name = Anonymized 157][tier = Active Tier][total = 755377373183][used = 533971809075] [name = Anonymized 246][tier = Active Tier][total = 988878746314342][used = 988878746314342]
    ...    2
    ...    datadomain-cloud-tier
    ...    --verbose
    ...    List filesystems: [name = /data][tier = Active Tier][total = 164694708558233][used = 149447252534886] [name = /data][tier = Cloud Tier][total = 343897387145625][used = 125095539585843] [name = /data][tier = Total][total = 508592095703858][used = 274542792120729] [name = /ddvar][tier = Active Tier][total = 80101140069][used = 28132035788] [name = /ddvar/core][tier = Active Tier][total = 256731670117][used = 124446677401] [name = /ddvar/core][tier = Total][total = 256731670117][used = 124446677401] [name = /ddvar][tier = Total][total = 80101140069][used = 28132035788] [name = Index][tier = Active Tier][total = 2424079541862][used = 1356243297894] [name = Index][tier = Total][total = 2424079541862][used = 1356243297894]
