*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${INJECT_PERL}     -Mcertificates_date -I${CURDIR}
${CMD}             ${CENTREON_PLUGINS} --plugin=network::f5::bigip::snmp::plugin
...                --mode=certificates
...                --hostname=${HOSTNAME}
...                --snmp-version=${SNMPVERSION}
...                --snmp-port=${SNMPPORT}
...                --snmp-community=network/f5/bigip/snmp/certificates

*** Test Cases ***
certificates ${tc}
    [Tags]    network

    ${OLD_PERL5OPT}=    Get Environment Variable     PERL5OPT   default=
    Set Environment Variable    PERL5OPT    ${INJECT_PERL} ${OLD_PERL5OPT}

    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                       expected_result    --
            ...      1     ${EMPTY}                                                                            CRITICAL: Certificate 'Anonymized 165' has expired - Certificate 'Anonymized 186' has expired | 'certificates-count'=9;;;0; '_Anonymized 981'=212738332s;;@0:0;0; '_Anonymized 165'=0s;;@0:0;0; '_Anonymized 982'=384058793s;;@0:0;0; '_Anonymized 983'=145466616s;;@0:0;0; '_Anonymized 196'=122214889s;;@0:0;0; '_Anonymized 141'=67955030s;;@0:0;0; '_Anonymized 881'=68447205s;;@0:0;0; '_Anonymized 068'=145466616s;;@0:0;0; '_Anonymized 186'=0s;;@0:0;0;
            ...      2     --include-name="Anonymized 068"                                                     OK: number of certificates: 1 - Certificate 'Anonymized 068' expires in 4y 7M 1w 2d 14h 45m 11s | 'certificates-count'=1;;;0; '_Anonymized 068'=145466616s;;@0:0;0;
            ...      3     --include-name=Anonym --exclude-name="Anonymized 035"                               CRITICAL: Certificate 'Anonymized 165' has expired - Certificate 'Anonymized 186' has expired | 'certificates-count'=9;;;0; '_Anonymized 981'=212738332s;;@0:0;0; '_Anonymized 165'=0s;;@0:0;0; '_Anonymized 982'=384058793s;;@0:0;0; '_Anonymized 983'=145466616s;;@0:0;0; '_Anonymized 196'=122214889s;;@0:0;0; '_Anonymized 141'=67955030s;;@0:0;0; '_Anonymized 881'=68447205s;;@0:0;0; '_Anonymized 068'=145466616s;;@0:0;0; '_Anonymized 186'=0s;;@0:0;0;
            ...      4     --unit=w --warning-certificate-expires=150: --include-name="Anonymized 141"         WARNING: Certificate 'Anonymized 141' expires in 2y 1M 3w 4d 14h 17m 15s | 'certificates-count'=1;;;0; '_Anonymized 141'=112w;150:;@0:0;0;
            ...      5     --unit=m --critical-certificate-expires=:1111111 --include-name="Anonymized 141"    CRITICAL: Certificate 'Anonymized 141' expires in 2y 1M 3w 4d 14h 17m 15s | 'certificates-count'=1;;;0; '_Anonymized 141'=1132583m;;0:1111111;0;
            ...      6     --filter-counters=certificates-count --warning-certificates-count=10:               WARNING: number of certificates: 9 | 'certificates-count'=9;10:;;0;
