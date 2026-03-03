*** Settings ***
Documentation       os::windows::wsman::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup
Suite Teardown
Test Timeout        120s


*** Variables ***
${INJECT_PERL}      -Mfakewsman -I${CURDIR}
${CMD}              ${CENTREON_PLUGINS}
...         --plugin=os::windows::wsman::plugin
...         --mode=certificates
...         --hostname=${HOSTNAME}
...         --wsman-username=XXXXX --wsman-password=XXXXX


*** Test Cases ***
Certificates ${tc}
    [Tags]    os    windows    wsman    notauto
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_regexp
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    ^OK: number of certificates: \\\\d+
    ...    2
    ...    --include-subject='Microsoft Development Root Certificate Authority'
    ...    Microsoft Development Root Certificate Authority
    ...    3
    ...    --exclude-subject='Microsoft Development Root Certificate Authority'
    ...    ^(?!.*Microsoft Development Root Certificate Authority).*$
    ...    4
    ...    --include-path='Microsoft.PowerShell.Security'
    ...    Microsoft Development Root Certificate Authority
    ...    5
    ...    --exclude-path='Microsoft.PowerShell.Security'
    ...    ^(?!.*Microsoft Development Root Certificate Authority).*$
    ...    6
    ...    --warning-certificate-expires=1
    ...    WARNING:
    ...    7
    ...    --critical-certificate-expires=1
    ...    CRITICAL:
    ...    8
    ...    --warning-certificates-detected=1
    ...    WARNING:
    ...    9
    ...    --critical-certificates-detected=1
    ...    CRITICAL:


*** Test Cases ***
EmptyCerticicates ${tc}
   [Tags]    os    windows    wsman

   ${OLD_PERL5OPT}=    Get Environment Variable     PERL5OPT   default=
   Set Environment Variable    PERL5OPT    ${INJECT_PERL} ${OLD_PERL5OPT}

   ${command}    Catenate
   ...    ${CMD}
   ...    ${extra_options}

   Ctn Run Command Without Connector And Check Result As Regexp   ${command}    ${expected_regexp}

   Examples:
   ...    tc
   ...    extraoptions
   ...    expected_regexp
   ...    --
   ...    1
   ...    --help
   ...    ^Plugin Description:
   ...    2
   ...    --disco-format
   ...    xml version
