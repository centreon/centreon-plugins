*** Settings ***
Documentation       Check Windows certificates.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Setup Certificates Tests
Suite Teardown      Teardown Certificates Tests
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=os::windows::local::plugin
...         --mode=certificates
...         --command=cat
...         --command-path=/usr/bin
...         --no-ps


*** Keywords ***
Setup Certificates Tests
    Ctn Generic Suite Setup
    ${OLD_PERL5OPT}=    Get Environment Variable    PERL5OPT    default=
    Set Suite Variable    ${OLD_PERL5OPT}
    Set Environment Variable    PERL5OPT    -Mfixed_date -I${CURDIR} ${OLD_PERL5OPT}

Teardown Certificates Tests
    Set Environment Variable    PERL5OPT    ${OLD_PERL5OPT}
    Ctn Generic Suite Teardown


*** Test Cases ***
certificates ${tc}
    [Tags]    os    windows    certificates
    ${command}    Catenate
    ...    ${CMD}
    ...    --command-options=${CURDIR}/certificates.json
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options    expected_result    --
        ...      1     ${EMPTY}                                                OK: number of certificates: 3 - All certificates are ok | 'certificates.detected.count'=3;;;0; 'certificate.expires.seconds~CN=Expired Cert'=0s;;;0; 'certificate.expires.seconds~CN=Soon Expiring'=2592000s;;;0; 'certificate.expires.seconds~CN=Valid Cert'=31556926s;;;0;
        ...      2     --filter-subject='Soon'                                 OK: number of certificates: 1 - All certificates are ok | 'certificates.detected.count'=1;;;0; 'certificate.expires.seconds~CN=Soon Expiring'=2592000s;;;0;
        ...      3     --filter-thumbprint='CCCC'                              OK: number of certificates: 1 - All certificates are ok | 'certificates.detected.count'=1;;;0; 'certificate.expires.seconds~CN=Valid Cert'=31556926s;;;0;
        ...      4     --filter-path='My'                                      OK: number of certificates: 2 - All certificates are ok | 'certificates.detected.count'=2;;;0; 'certificate.expires.seconds~CN=Expired Cert'=0s;;;0; 'certificate.expires.seconds~CN=Soon Expiring'=2592000s;;;0;
        ...      5     --unit=d --critical-certificate-expires='31:'           CRITICAL: number of certificates: 3 - Certificate 'CN=Expired Cert' [path: cert:\LocalMachine\My] expired - Certificate 'CN=Soon Expiring' [path: cert:\LocalMachine\My] expires in 4w 2d | 'certificates.detected.count'=3;;;0; 'certificate.expires.days~CN=Expired Cert'=0d;;31:;0; 'certificate.expires.days~CN=Soon Expiring'=30d;;31:;0; 'certificate.expires.days~CN=Valid Cert'=365d;;31:;0;
        ...      6     --warning-certificates-detected='2'                     WARNING: number of certificates: 3 - All certificates are ok | 'certificates.detected.count'=3;0:2;;0; 'certificate.expires.seconds~CN=Expired Cert'=0s;;;0; 'certificate.expires.seconds~CN=Soon Expiring'=2592000s;;;0; 'certificate.expires.seconds~CN=Valid Cert'=31556926s;;;0;
