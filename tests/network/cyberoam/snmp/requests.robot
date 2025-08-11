*** Settings ***
Documentation       Check request statistics.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cyberoam::snmp::plugin


*** Test Cases ***
requests ${tc}
    [Tags]    network    cyberoam
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=requests
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cyberoam/snmp/slim_sophos
    ...    --snmp-timeout=1
    ...    ${extra_options}   

    # first run to build cache
    Run    ${command}
    # second run to control the output
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                                                                             expected_result    --
            ...      1     --filter-counters=''                                                                                      OK: Requests live users: 38, http hits: 0, ftp hits: 0, pop3 hits: 0, imap hits: 0, smtp hits: 0 | 'live_users'=38;;;0; 'http_hits'=0;;;0; 'ftp_hits'=0;;;0; 'pop3_hits'=0;;;0; 'imap_hits'=0;;;0; 'smtp_hits'=0;;;0;
            ...      2     --filter-counters='http'                                                                                  OK: Requests http hits: 0 | 'http_hits'=0;;;0;
            ...      3     --warning-live-users=0 --critical-live-users=0                                                            CRITICAL: Requests live users: 38 | 'live_users'=38;0:0;0:0;0; 'http_hits'=0;;;0; 'ftp_hits'=0;;;0; 'pop3_hits'=0;;;0; 'imap_hits'=0;;;0; 'smtp_hits'=0;;;0;
            ...      4     --warning-http-hits=0 --critical-http-hits=10                                                             OK: Requests live users: 38, http hits: 0, ftp hits: 0, pop3 hits: 0, imap hits: 0, smtp hits: 0 | 'live_users'=38;;;0; 'http_hits'=0;0:0;0:10;0; 'ftp_hits'=0;;;0; 'pop3_hits'=0;;;0; 'imap_hits'=0;;;0; 'smtp_hits'=0;;;0;
            ...      5     --warning-ftp-hits=5 --critical-ftp-hits=10                                                               OK: Requests live users: 38, http hits: 0, ftp hits: 0, pop3 hits: 0, imap hits: 0, smtp hits: 0 | 'live_users'=38;;;0; 'http_hits'=0;;;0; 'ftp_hits'=0;0:5;0:10;0; 'pop3_hits'=0;;;0; 'imap_hits'=0;;;0; 'smtp_hits'=0;;;0;
            ...      6     --warning-smtp-hits=20 --critical-smtp-hits=10                                                            OK: Requests live users: 38, http hits: 0, ftp hits: 0, pop3 hits: 0, imap hits: 0, smtp hits: 0 | 'live_users'=38;;;0; 'http_hits'=0;;;0; 'ftp_hits'=0;;;0; 'pop3_hits'=0;;;0; 'imap_hits'=0;;;0; 'smtp_hits'=0;0:20;0:10;0;
            ...      7     --warning-pop3-hits=80 --critical-pop3-hits=100                                                           OK: Requests live users: 38, http hits: 0, ftp hits: 0, pop3 hits: 0, imap hits: 0, smtp hits: 0 | 'live_users'=38;;;0; 'http_hits'=0;;;0; 'ftp_hits'=0;;;0; 'pop3_hits'=0;0:80;0:100;0; 'imap_hits'=0;;;0; 'smtp_hits'=0;;;0;
            ...      8     --warning-imap-hits=50 --critical-imap-hits=50                                                            OK: Requests live users: 38, http hits: 0, ftp hits: 0, pop3 hits: 0, imap hits: 0, smtp hits: 0 | 'live_users'=38;;;0; 'http_hits'=0;;;0; 'ftp_hits'=0;;;0; 'pop3_hits'=0;;;0; 'imap_hits'=0;0:50;0:50;0; 'smtp_hits'=0;;;0;
