# Here we only check that the plugin is correctly loaded and the mode works
# More tests are done with api.t file

*** Settings ***
Documentation       Storable IBM Storwize SSH

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=storage::ibm::storwize::ssh::plugin


*** Test Cases ***
Mode ${tc}
    [Tags]    storage    ibm    storwize    ssh
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_string}

    Examples:      tc       extra_options             expected_string     --
        ...        1        ${EMPTY}                  UNKNOWN: Need to specify '--mode' or '--dyn-mode' option.
        ...        2        --mode=eventlog           UNKNOWN: please set --hostname option for ssh connection (or --command for local) 
        ...        3        --mode=pool-usage         UNKNOWN: please set --hostname option for ssh connection (or --command for local)
        ...        4        --mode=replication        UNKNOWN: please set --hostname option for ssh connection (or --command for local)
        ...        5        --mode=components         UNKNOWN: please set --hostname option for ssh connection (or --command for local)
