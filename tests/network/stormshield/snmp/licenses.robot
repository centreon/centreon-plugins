*** Settings ***
Documentation       network::stormshield::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${INJECT_PERL}      -Mfixed_date -I${CURDIR}
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=network::stormshield::snmp::plugin
...                 --mode=licenses
...                 --hostname=${HOSTNAME}
...                 --snmp-port=${SNMPPORT}
...                 --snmp-version=${SNMPVERSION}
...                 --snmp-community=network/stormshield/snmp/sn910


*** Test Cases ***
Licenses ${tc}
    [Tags]    network    stormshield    snmp
    ${OLD_PERL5OPT}=    Get Environment Variable    PERL5OPT    default=${EMPTY}
    Set Environment Variable    PERL5OPT    ${INJECT_PERL} ${OLD_PERL5OPT}

    ${command}=    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All licences of the cluster are up to date | 'fw_1~Industrial#license.expiration.days'=1285d;60:;0:;; 'fw_1~NotAfter#license.expiration.days'=4171d;60:;0:;; 'fw_1~Pattern#license.expiration.days'=1285d;60:;0:;; 'fw_1~SPAMVendor#license.expiration.days'=1285d;60:;0:;; 'fw_1~Sandboxing#license.expiration.days'=1285d;60:;0:;; 'fw_1~URLVendor#license.expiration.days'=1285d;60:;0:;; 'fw_1~Update#license.expiration.days'=1285d;60:;0:;; 'fw_1~VirusVendor#license.expiration.days'=1285d;60:;0:;; 'fw_1~Warranty#license.expiration.days'=1285d;60:;0:;; 'fw_2~Industrial#license.expiration.days'=1285d;60:;0:;; 'fw_2~NotAfter#license.expiration.days'=4171d;60:;0:;; 'fw_2~Pattern#license.expiration.days'=1285d;60:;0:;; 'fw_2~SPAMVendor#license.expiration.days'=1285d;60:;0:;; 'fw_2~Sandboxing#license.expiration.days'=1285d;60:;0:;; 'fw_2~URLVendor#license.expiration.days'=1285d;60:;0:;; 'fw_2~Update#license.expiration.days'=1285d;60:;0:;; 'fw_2~VirusVendor#license.expiration.days'=1285d;60:;0:;; 'fw_2~Warranty#license.expiration.days'=1285d;60:;0:;;
    ...    2
    ...    --warning-expires-days=1
    ...    WARNING: Licence: Industrial (Expires in 1285 days: 2030-02-05) - Licence: NotAfter (Expires in 4171 days: 2037-12-31) - Licence: Pattern (Expires in 1285 days: 2030-02-05) - Licence: SPAMVendor (Expires in 1285 days: 2030-02-05) - Licence: Sandboxing (Expires in 1285 days: 2030-02-05) - Licence: URLVendor (Expires in 1285 days: 2030-02-05) - Licence: Update (Expires in 1285 days: 2030-02-05) - Licence: VirusVendor (Expires in 1285 days: 2030-02-05) - Licence: Warranty (Expires in 1285 days: 2030-02-05) - Licence: Industrial (Expires in 1285 days: 2030-02-05) - Licence: NotAfter (Expires in 4171 days: 2037-12-31) - Licence: Pattern (Expires in 1285 days: 2030-02-05) - Licence: SPAMVendor (Expires in 1285 days: 2030-02-05) - Licence: Sandboxing (Expires in 1285 days: 2030-02-05) - Licence: URLVendor (Expires in 1285 days: 2030-02-05) - Licence: Update (Expires in 1285 days: 2030-02-05) - Licence: VirusVendor (Expires in 1285 days: 2030-02-05) - Licence: Warranty (Expires in 1285 days: 2030-02-05) | 'fw_1~Industrial#license.expiration.days'=1285d;0:1;0:;; 'fw_1~NotAfter#license.expiration.days'=4171d;0:1;0:;; 'fw_1~Pattern#license.expiration.days'=1285d;0:1;0:;; 'fw_1~SPAMVendor#license.expiration.days'=1285d;0:1;0:;; 'fw_1~Sandboxing#license.expiration.days'=1285d;0:1;0:;; 'fw_1~URLVendor#license.expiration.days'=1285d;0:1;0:;; 'fw_1~Update#license.expiration.days'=1285d;0:1;0:;; 'fw_1~VirusVendor#license.expiration.days'=1285d;0:1;0:;; 'fw_1~Warranty#license.expiration.days'=1285d;0:1;0:;; 'fw_2~Industrial#license.expiration.days'=1285d;0:1;0:;; 'fw_2~NotAfter#license.expiration.days'=4171d;0:1;0:;; 'fw_2~Pattern#license.expiration.days'=1285d;0:1;0:;; 'fw_2~SPAMVendor#license.expiration.days'=1285d;0:1;0:;; 'fw_2~Sandboxing#license.expiration.days'=1285d;0:1;0:;; 'fw_2~URLVendor#license.expiration.days'=1285d;0:1;0:;; 'fw_2~Update#license.expiration.days'=1285d;0:1;0:;; 'fw_2~VirusVendor#license.expiration.days'=1285d;0:1;0:;; 'fw_2~Warranty#license.expiration.days'=1285d;0:1;0:;;
    ...    3
    ...    --critical-expires-days=1
    ...    CRITICAL: Licence: Industrial (Expires in 1285 days: 2030-02-05) - Licence: NotAfter (Expires in 4171 days: 2037-12-31) - Licence: Pattern (Expires in 1285 days: 2030-02-05) - Licence: SPAMVendor (Expires in 1285 days: 2030-02-05) - Licence: Sandboxing (Expires in 1285 days: 2030-02-05) - Licence: URLVendor (Expires in 1285 days: 2030-02-05) - Licence: Update (Expires in 1285 days: 2030-02-05) - Licence: VirusVendor (Expires in 1285 days: 2030-02-05) - Licence: Warranty (Expires in 1285 days: 2030-02-05) - Licence: Industrial (Expires in 1285 days: 2030-02-05) - Licence: NotAfter (Expires in 4171 days: 2037-12-31) - Licence: Pattern (Expires in 1285 days: 2030-02-05) - Licence: SPAMVendor (Expires in 1285 days: 2030-02-05) - Licence: Sandboxing (Expires in 1285 days: 2030-02-05) - Licence: URLVendor (Expires in 1285 days: 2030-02-05) - Licence: Update (Expires in 1285 days: 2030-02-05) - Licence: VirusVendor (Expires in 1285 days: 2030-02-05) - Licence: Warranty (Expires in 1285 days: 2030-02-05) | 'fw_1~Industrial#license.expiration.days'=1285d;60:;0:1;; 'fw_1~NotAfter#license.expiration.days'=4171d;60:;0:1;; 'fw_1~Pattern#license.expiration.days'=1285d;60:;0:1;; 'fw_1~SPAMVendor#license.expiration.days'=1285d;60:;0:1;; 'fw_1~Sandboxing#license.expiration.days'=1285d;60:;0:1;; 'fw_1~URLVendor#license.expiration.days'=1285d;60:;0:1;; 'fw_1~Update#license.expiration.days'=1285d;60:;0:1;; 'fw_1~VirusVendor#license.expiration.days'=1285d;60:;0:1;; 'fw_1~Warranty#license.expiration.days'=1285d;60:;0:1;; 'fw_2~Industrial#license.expiration.days'=1285d;60:;0:1;; 'fw_2~NotAfter#license.expiration.days'=4171d;60:;0:1;; 'fw_2~Pattern#license.expiration.days'=1285d;60:;0:1;; 'fw_2~SPAMVendor#license.expiration.days'=1285d;60:;0:1;; 'fw_2~Sandboxing#license.expiration.days'=1285d;60:;0:1;; 'fw_2~URLVendor#license.expiration.days'=1285d;60:;0:1;; 'fw_2~Update#license.expiration.days'=1285d;60:;0:1;; 'fw_2~VirusVendor#license.expiration.days'=1285d;60:;0:1;; 'fw_2~Warranty#license.expiration.days'=1285d;60:;0:1;;
    ...    4
    ...    --timezone=Asia/Tokyo
    ...    OK: All licences of the cluster are up to date | 'fw_1~Industrial#license.expiration.days'=1284d;60:;0:;; 'fw_1~NotAfter#license.expiration.days'=4170d;60:;0:;; 'fw_1~Pattern#license.expiration.days'=1284d;60:;0:;; 'fw_1~SPAMVendor#license.expiration.days'=1284d;60:;0:;; 'fw_1~Sandboxing#license.expiration.days'=1284d;60:;0:;; 'fw_1~URLVendor#license.expiration.days'=1284d;60:;0:;; 'fw_1~Update#license.expiration.days'=1284d;60:;0:;; 'fw_1~VirusVendor#license.expiration.days'=1284d;60:;0:;; 'fw_1~Warranty#license.expiration.days'=1284d;60:;0:;; 'fw_2~Industrial#license.expiration.days'=1284d;60:;0:;; 'fw_2~NotAfter#license.expiration.days'=4170d;60:;0:;; 'fw_2~Pattern#license.expiration.days'=1284d;60:;0:;; 'fw_2~SPAMVendor#license.expiration.days'=1284d;60:;0:;; 'fw_2~Sandboxing#license.expiration.days'=1284d;60:;0:;; 'fw_2~URLVendor#license.expiration.days'=1284d;60:;0:;; 'fw_2~Update#license.expiration.days'=1284d;60:;0:;; 'fw_2~VirusVendor#license.expiration.days'=1284d;60:;0:;; 'fw_2~Warranty#license.expiration.days'=1284d;60:;0:;;
