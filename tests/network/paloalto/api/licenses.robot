*** Settings ***
Documentation       Check PaloAlto licenses status and expiration.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${INJECT_PERL}     -Mfixed_date -I${CURDIR}
${MOCKOON_JSON}     ${CURDIR}${/}mockoon-paloalto-api.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=network::paloalto::api::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --mode=licenses

*** Test Cases ***
paloalto-licenses ${tc}
    [Tags]    network    paloalto    api    licenses

    ${OLD_PERL5OPT}=    Get Environment Variable     PERL5OPT   default=
    Set Environment Variable    PERL5OPT    ${INJECT_PERL} ${OLD_PERL5OPT}

    ${command}    Catenate
    ...    ${CMD}
    ...    --auth-type=api-key
    ...    --api-key=D@pAs$W@rD
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                   expected_result    --
            ...      1     ${EMPTY}                                                                        CRITICAL: license 'Standard' expired: yes, 0 days left | 'licenses.count'=13;;;0; 'Advanced DNS Security#license.empiration.days'=185d;;@0:0;-1; 'Advanced Threat Prevention#license.empiration.days'=185d;;@0:0;-1; 'Advanced URL Filtering#license.empiration.days'=185d;;@0:0;-1; 'Advanced WildFire License#license.empiration.days'=185d;;@0:0;-1; 'DNS Security#license.empiration.days'=185d;;@0:0;-1; 'GlobalProtect Gateway#license.empiration.days'=185d;;@0:0;-1; 'GlobalProtect Portal#license.empiration.days'=-1d;;@0:0;-1; 'Logging Service#license.empiration.days'=1180d;;@0:0;-1; 'PAN-DB URL Filtering#license.empiration.days'=185d;;@0:0;-1; 'SD WAN#license.empiration.days'=185d;;@0:0;-1; 'Standard#license.empiration.days'=0d;;@0:0;-1; 'Threat Prevention#license.empiration.days'=185d;;@0:0;-1; 'WildFire License#license.empiration.days'=185d;;@0:0;-1;
            ...      2     --include-license-name=Logging --warning-status='\\\%{expired}=~/no/'           WARNING: license 'Logging Service' expired: no | 'licenses.count'=1;;;0; 'Logging Service#license.empiration.days'=1180d;;@0:0;-1;
            ...      3     --include-license-name=Logging --critical-status='\\\%{expired}=~/no/'          CRITICAL: license 'Logging Service' expired: no | 'licenses.count'=1;;;0; 'Logging Service#license.empiration.days'=1180d;;@0:0;-1;
            ...      4     --include-license-name=GlobalProtect                                            OK: Licenses count: 2 - All licenses are ok | 'licenses.count'=2;;;0; 'GlobalProtect Gateway#license.empiration.days'=185d;;@0:0;-1; 'GlobalProtect Portal#license.empiration.days'=-1d;;@0:0;-1;
            ...      5     --warning-licenses-count=1000: --include-license-name=Logging                   WARNING: Licenses count: 1 | 'licenses.count'=1;1000:;;0; 'Logging Service#license.empiration.days'=1180d;;@0:0;-1;
            ...      6     --critical-licenses-count=1000: --include-license-name=Logging                  CRITICAL: Licenses count: 1 | 'licenses.count'=1;;1000:;0; 'Logging Service#license.empiration.days'=1180d;;@0:0;-1;
            ...      7     --include-license-name=SD                                                       OK: Licenses count: 1 - license 'SD WAN' expired: no, 185 days left | 'licenses.count'=1;;;0; 'SD WAN#license.empiration.days'=185d;;@0:0;-1;
            ...      8     --include-license-name=Logging --warning-expiration-days=1000                   WARNING: license 'Logging Service' 1180 days left | 'licenses.count'=1;;;0; 'Logging Service#license.empiration.days'=1180d;0:1000;@0:0;-1;
            ...      9     --include-license-name=Logging --critical-expiration-days=1000                  CRITICAL: license 'Logging Service' 1180 days left | 'licenses.count'=1;;;0; 'Logging Service#license.empiration.days'=1180d;;0:1000;-1;
            ...      10    --include-license-name=Standard                                                 CRITICAL: license 'Standard' expired: yes, 0 days left | 'licenses.count'=1;;;0; 'Standard#license.empiration.days'=0d;;@0:0;-1;
            ...      11    --include-license-name=Portal                                                   OK: Licenses count: 1 - license 'GlobalProtect Portal' expired: no, never expire | 'licenses.count'=1;;;0; 'GlobalProtect Portal#license.empiration.days'=-1d;;@0:0;-1;
