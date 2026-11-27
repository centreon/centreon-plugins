*** Settings ***
Documentation       Check local Windows operating system.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::windows::local::plugin --mode=sessions --command-path=${CURDIR}


*** Test Cases ***
sessions options ${tc}
    [Tags]    os    windows
    # Single run: total counters are in buffer creation, only current sessions are checked
    ${command}    Catenate
    ...    ${CMD}
    ...    --statefile-suffix=options-${tc}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Sessions sessions-created : Buffer creation, sessions-disconnected : Buffer creation, sessions-reconnected : Buffer creation, current active : 2, current disconnected : 1 | 'sessions_active'=2;;;0; 'sessions_disconnected_current'=1;;;0;
    ...    2
    ...    --command-options="/COUNTER de"
    ...    UNKNOWN: Cannot find information in command output
    ...    3
    ...    --command-options="/COUNTER en" --language=xx
    ...    UNKNOWN: Cannot find language 'xx' in config file
    ...    4
    ...    --command-options="/COUNTER en" --config=${CURDIR}/qwinsta_config.xml --language=custom
    ...    OK: Sessions sessions-created : Buffer creation, sessions-disconnected : Buffer creation, sessions-reconnected : Buffer creation, current active : 3, current disconnected : 2 | 'sessions_active'=3;;;0; 'sessions_disconnected_current'=2;;;0;
    ...    5
    ...    --command-options="/COUNTER en" --config=${CURDIR}/qwinsta_config.xml
    ...    UNKNOWN: Cannot find language 'en' in config file
    ...    6
    ...    --command-options="/COUNTER en" --config=${CURDIR}/nonexistent.xml
    ...    UNKNOWN: Could not open file ${CURDIR}/nonexistent.xml : No such file or directory
    ...    7
    ...    --command-options="/COUNTER en slow" --timeout=1
    ...    UNKNOWN: Command too long to execute (timeout)...

sessions details ${tc}
    [Tags]    os    windows
    # Check how sessions are parsed (session name and user name columns, current session marker '>')
    ${command}    Catenate
    ...    ${CMD}
    ...    --command-options="/COUNTER ${lang} ${format}"
    ...    --language=${lang}
    ...    --statefile-suffix=details-${lang}-${format}
    ...    --verbose

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    format
    ...    lang
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    en
    ...    OK: Sessions sessions-created : Buffer creation, sessions-disconnected : Buffer creation, sessions-reconnected : Buffer creation, current active : 2, current disconnected : 1 | 'sessions_active'=2;;;0; 'sessions_disconnected_current'=1;;;0; [DEVICE => -] [ID => 0] [SESSIONNAME => console] [STATE => Active] [TYPE => wdcon] [USERNAME => Administrator1] [DEVICE => rdpdr] [ID => 1] [SESSIONNAME => rdp-tcp#1] [STATE => Active] [TYPE => wdtshare] [USERNAME => User1] [DEVICE => COM1] [ID => 4] [SESSIONNAME => -] [STATE => Disc] [TYPE => -] [USERNAME => User4]
    ...    2
    ...    crlf
    ...    en
    ...    OK: Sessions sessions-created : Buffer creation, sessions-disconnected : Buffer creation, sessions-reconnected : Buffer creation, current active : 2, current disconnected : 1 | 'sessions_active'=2;;;0; 'sessions_disconnected_current'=1;;;0; [DEVICE => -] [ID => 0] [SESSIONNAME => console] [STATE => Active] [TYPE => wdcon] [USERNAME => Administrator1] [DEVICE => rdpdr] [ID => 1] [SESSIONNAME => rdp-tcp#1] [STATE => Active] [TYPE => wdtshare] [USERNAME => User1] [DEVICE => COM1] [ID => 4] [SESSIONNAME => -] [STATE => Disc] [TYPE => -] [USERNAME => User4]
    ...    3
    ...    ${EMPTY}
    ...    de
    ...    OK: Sessions sessions-created : Buffer creation, sessions-disconnected : Buffer creation, sessions-reconnected : Buffer creation, current active : 2, current disconnected : 1 | 'sessions_active'=2;;;0; 'sessions_disconnected_current'=1;;;0; [BENUTZERNAME => -] [GERÄT => COM1] [ID => 0] [SITZUNGSNAME => services] [STATUS => Getr.] [TYP => -] [BENUTZERNAME => eSievers] [GERÄT => COM3] [ID => 5] [SITZUNGSNAME => ica-cgp#2] [STATUS => Aktiv] [TYP => wdica] [BENUTZERNAME => shaaske] [GERÄT => -] [ID => 6] [SITZUNGSNAME => ica-cgp#3] [STATUS => Aktiv] [TYP => wdica]
    ...    4
    ...    crlf
    ...    de
    ...    OK: Sessions sessions-created : Buffer creation, sessions-disconnected : Buffer creation, sessions-reconnected : Buffer creation, current active : 2, current disconnected : 1 | 'sessions_active'=2;;;0; 'sessions_disconnected_current'=1;;;0; [BENUTZERNAME => -] [GERÄT => COM1] [ID => 0] [SITZUNGSNAME => services] [STATUS => Getr.] [TYP => -] [BENUTZERNAME => eSievers] [GERÄT => COM3] [ID => 5] [SITZUNGSNAME => ica-cgp#2] [STATUS => Aktiv] [TYP => wdica] [BENUTZERNAME => shaaske] [GERÄT => -] [ID => 6] [SITZUNGSNAME => ica-cgp#3] [STATUS => Aktiv] [TYP => wdica]
    ...    5
    ...    ${EMPTY}
    ...    fr
    ...    OK: Sessions sessions-created : Buffer creation, sessions-disconnected : Buffer creation, sessions-reconnected : Buffer creation, current active : 2, current disconnected : 2 | 'sessions_active'=2;;;0; 'sessions_disconnected_current'=2;;;0; [ID => 1] [PÉRIPHÉRIQUE => -] [SESSION => console] [TYPE => wdcon] [UTILISATEUR => Utilisateur1] [ÉTAT => Actif] [ID => 2] [PÉRIPHÉRIQUE => rdpdr] [SESSION => rdp-tcp#2] [TYPE => wdtshare] [UTILISATEUR => Utilisateur2] [ÉTAT => Actif] [ID => 3] [PÉRIPHÉRIQUE => COM1] [SESSION => -] [TYPE => -] [UTILISATEUR => Utilisateur3] [ÉTAT => Déco] [ID => 0] [PÉRIPHÉRIQUE => -] [SESSION => services] [TYPE => -] [UTILISATEUR => -] [ÉTAT => Déco]
    ...    6
    ...    crlf
    ...    fr
    ...    OK: Sessions sessions-created : Buffer creation, sessions-disconnected : Buffer creation, sessions-reconnected : Buffer creation, current active : 2, current disconnected : 2 | 'sessions_active'=2;;;0; 'sessions_disconnected_current'=2;;;0; [ID => 1] [PÉRIPHÉRIQUE => -] [SESSION => console] [TYPE => wdcon] [UTILISATEUR => Utilisateur1] [ÉTAT => Actif] [ID => 2] [PÉRIPHÉRIQUE => rdpdr] [SESSION => rdp-tcp#2] [TYPE => wdtshare] [UTILISATEUR => Utilisateur2] [ÉTAT => Actif] [ID => 3] [PÉRIPHÉRIQUE => COM1] [SESSION => -] [TYPE => -] [UTILISATEUR => Utilisateur3] [ÉTAT => Déco] [ID => 0] [PÉRIPHÉRIQUE => -] [SESSION => services] [TYPE => -] [UTILISATEUR => -] [ÉTAT => Déco]
    ...    7
    ...    ${EMPTY}
    ...    it
    ...    OK: Sessions sessions-created : Buffer creation, sessions-disconnected : Buffer creation, sessions-reconnected : Buffer creation, current active : 2, current disconnected : 2 | 'sessions_active'=2;;;0; 'sessions_disconnected_current'=2;;;0; [DISPOSITIVO => -] [ID => 1] [NOMESESSIONE => console] [NOMEUTENTE => Utente1] [STATO => Attivo] [TIPO => wdcon] [DISPOSITIVO => rdpdr] [ID => 2] [NOMESESSIONE => rdp-tcp#2] [NOMEUTENTE => Utente2] [STATO => Attivo] [TIPO => wdtshare] [DISPOSITIVO => COM1] [ID => 3] [NOMESESSIONE => -] [NOMEUTENTE => Utente3] [STATO => Disc] [TIPO => -] [DISPOSITIVO => -] [ID => 0] [NOMESESSIONE => services] [NOMEUTENTE => -] [STATO => Disc] [TIPO => -]
    ...    8
    ...    crlf
    ...    it
    ...    OK: Sessions sessions-created : Buffer creation, sessions-disconnected : Buffer creation, sessions-reconnected : Buffer creation, current active : 2, current disconnected : 2 | 'sessions_active'=2;;;0; 'sessions_disconnected_current'=2;;;0; [DISPOSITIVO => -] [ID => 1] [NOMESESSIONE => console] [NOMEUTENTE => Utente1] [STATO => Attivo] [TIPO => wdcon] [DISPOSITIVO => rdpdr] [ID => 2] [NOMESESSIONE => rdp-tcp#2] [NOMEUTENTE => Utente2] [STATO => Attivo] [TIPO => wdtshare] [DISPOSITIVO => COM1] [ID => 3] [NOMESESSIONE => -] [NOMEUTENTE => Utente3] [STATO => Disc] [TIPO => -] [DISPOSITIVO => -] [ID => 0] [NOMESESSIONE => services] [NOMEUTENTE => -] [STATO => Disc] [TIPO => -]

sessions counters ${tc}
    [Tags]    os    windows
    # First run stores the total counters read from the tested output (crlf: CRLF line endings,
    # cp850: CRLF line endings and CP850 encoding, as on Windows), second run (output 2) checks the delta
    ${command}    Catenate
    ...    ${CMD}
    ...    --language=${lang}
    ...    --statefile-suffix=counters-${lang}-${format}

    Run    ${command} --command-options="/COUNTER ${lang} ${format}"
    Ctn Run Command And Check Result As Strings
    ...    ${command} --command-options="/COUNTER ${lang} 2"
    ...    ${expected_result}

    Examples:
    ...    tc
    ...    lang
    ...    format
    ...    expected_result
    ...    --
    ...    1
    ...    en
    ...    ${EMPTY}
    ...    OK: Sessions created: 7, disconnected: 2, reconnected : 2, current active : 3, current disconnected : 1 | 'sessions_created'=7;;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=3;;;0; 'sessions_disconnected_current'=1;;;0;
    ...    2
    ...    de
    ...    ${EMPTY}
    ...    OK: Sessions created: 11, disconnected: 5, reconnected : 2, current active : 2, current disconnected : 1 | 'sessions_created'=11;;;0; 'sessions_disconnected'=5;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=2;;;0; 'sessions_disconnected_current'=1;;;0;
    ...    3
    ...    fr
    ...    ${EMPTY}
    ...    OK: Sessions created: 6, disconnected: 2, reconnected : 2, current active : 3, current disconnected : 1 | 'sessions_created'=6;;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=3;;;0; 'sessions_disconnected_current'=1;;;0;
    ...    4
    ...    it
    ...    ${EMPTY}
    ...    OK: Sessions created: 6, disconnected: 2, reconnected : 2, current active : 3, current disconnected : 1 | 'sessions_created'=6;;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=3;;;0; 'sessions_disconnected_current'=1;;;0;
    ...    5
    ...    en
    ...    crlf
    ...    OK: Sessions created: 7, disconnected: 2, reconnected : 2, current active : 3, current disconnected : 1 | 'sessions_created'=7;;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=3;;;0; 'sessions_disconnected_current'=1;;;0;
    ...    6
    ...    de
    ...    crlf
    ...    OK: Sessions created: 11, disconnected: 5, reconnected : 2, current active : 2, current disconnected : 1 | 'sessions_created'=11;;;0; 'sessions_disconnected'=5;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=2;;;0; 'sessions_disconnected_current'=1;;;0;
    ...    7
    ...    de
    ...    cp850
    ...    OK: Sessions created: 11, disconnected: 5, reconnected : 2, current active : 2, current disconnected : 1 | 'sessions_created'=11;;;0; 'sessions_disconnected'=5;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=2;;;0; 'sessions_disconnected_current'=1;;;0;
    ...    8
    ...    fr
    ...    crlf
    ...    OK: Sessions created: 6, disconnected: 2, reconnected : 2, current active : 3, current disconnected : 1 | 'sessions_created'=6;;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=3;;;0; 'sessions_disconnected_current'=1;;;0;
    ...    9
    ...    fr
    ...    cp850
    ...    OK: Sessions created: 6, disconnected: 2, reconnected : 2, current active : 3, current disconnected : 1 | 'sessions_created'=6;;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=3;;;0; 'sessions_disconnected_current'=1;;;0;
    ...    10
    ...    it
    ...    crlf
    ...    OK: Sessions created: 6, disconnected: 2, reconnected : 2, current active : 3, current disconnected : 1 | 'sessions_created'=6;;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=3;;;0; 'sessions_disconnected_current'=1;;;0;

sessions filter ${tc}
    [Tags]    os    windows
    # The filter applies to current sessions, total counters are not filtered.
    # Each filtered case follows the same language without filter, to show the difference.
    ${command}    Catenate
    ...    ${CMD}
    ...    --language=${lang}
    ...    --statefile-suffix=${lang}
    ...    --filter-sessionname=${filter}

    Run    ${command} --command-options="/COUNTER ${lang}"
    Ctn Run Command And Check Result As Strings
    ...    ${command} --command-options="/COUNTER ${lang} 2"
    ...    ${expected_result}

    Examples:
    ...    tc
    ...    lang
    ...    filter
    ...    expected_result
    ...    --
    ...    1
    ...    en
    ...    ${EMPTY}
    ...    OK: Sessions created: 7, disconnected: 2, reconnected : 2, current active : 3, current disconnected : 1 | 'sessions_created'=7;;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=3;;;0; 'sessions_disconnected_current'=1;;;0;
    ...    2
    ...    en
    ...    rdp
    ...    OK: Sessions created: 7, disconnected: 2, reconnected : 2, current active : 2, current disconnected : 0 | 'sessions_created'=7;;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=2;;;0; 'sessions_disconnected_current'=0;;;0;
    ...    3
    ...    de
    ...    ${EMPTY}
    ...    OK: Sessions created: 11, disconnected: 5, reconnected : 2, current active : 2, current disconnected : 1 | 'sessions_created'=11;;;0; 'sessions_disconnected'=5;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=2;;;0; 'sessions_disconnected_current'=1;;;0;
    ...    4
    ...    de
    ...    services
    ...    OK: Sessions created: 11, disconnected: 5, reconnected : 2, current active : 0, current disconnected : 1 | 'sessions_created'=11;;;0; 'sessions_disconnected'=5;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=0;;;0; 'sessions_disconnected_current'=1;;;0;
    ...    5
    ...    fr
    ...    ${EMPTY}
    ...    OK: Sessions created: 6, disconnected: 2, reconnected : 2, current active : 3, current disconnected : 1 | 'sessions_created'=6;;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=3;;;0; 'sessions_disconnected_current'=1;;;0;
    ...    6
    ...    fr
    ...    '^services$'
    ...    OK: Sessions created: 6, disconnected: 2, reconnected : 2, current active : 0, current disconnected : 1 | 'sessions_created'=6;;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=0;;;0; 'sessions_disconnected_current'=1;;;0;
    ...    7
    ...    it
    ...    ${EMPTY}
    ...    OK: Sessions created: 6, disconnected: 2, reconnected : 2, current active : 3, current disconnected : 1 | 'sessions_created'=6;;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=3;;;0; 'sessions_disconnected_current'=1;;;0;
    ...    8
    ...    it
    ...    rdp
    ...    OK: Sessions created: 6, disconnected: 2, reconnected : 2, current active : 2, current disconnected : 0 | 'sessions_created'=6;;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=2;;;0; 'sessions_disconnected_current'=0;;;0;

sessions thresholds ${tc}
    [Tags]    os    windows
    # Two runs to get all counters: one threshold (warning or critical) per counter
    ${command}    Catenate
    ...    ${CMD}
    ...    --statefile-suffix=thresholds-${tc}
    ...    ${extra_options}

    Run    ${command} --command-options="/COUNTER en"
    Ctn Run Command And Check Result As Strings
    ...    ${command} --command-options="/COUNTER en 2"
    ...    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --warning-sessions-active=1
    ...    WARNING: Sessions current active : 3 | 'sessions_created'=7;;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=3;0:1;;0; 'sessions_disconnected_current'=1;;;0;
    ...    2
    ...    --critical-sessions-disconnected-current=0
    ...    CRITICAL: Sessions current disconnected : 1 | 'sessions_created'=7;;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=3;;;0; 'sessions_disconnected_current'=1;;0:0;0;
    ...    3
    ...    --warning-sessions-created=5
    ...    WARNING: Sessions created: 7 | 'sessions_created'=7;0:5;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=3;;;0; 'sessions_disconnected_current'=1;;;0;
    ...    4
    ...    --critical-sessions-disconnected=1
    ...    CRITICAL: Sessions disconnected: 2 | 'sessions_created'=7;;;0; 'sessions_disconnected'=2;;0:1;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=3;;;0; 'sessions_disconnected_current'=1;;;0;
    ...    5
    ...    --warning-sessions-reconnected=1
    ...    WARNING: Sessions reconnected : 2 | 'sessions_created'=7;;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;0:1;;0; 'sessions_active'=3;;;0; 'sessions_disconnected_current'=1;;;0;
