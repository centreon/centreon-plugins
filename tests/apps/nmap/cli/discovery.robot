*** Settings ***
Documentation       Test the Podman container-usage mode
Library             Collections

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown

*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}podman.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::nmap::cli::plugin
...                 --mode=discovery

*** Test Cases ***
Container usage ${tc}
    [Documentation]    Check nmap discovery
    [Tags]    apps    nmap
    Log To Console    \n
    ${command}    Catenate
    ...    ${cmd}
    ...    --subnet='127.0.0.1/32'
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Json    ${command}    ${expected_result}

    Examples:         tc    extraoptions          expected_result    --
    ...       1     ${EMPTY}                       {"end_time":1747232859,"discovered_items":1,"results":[{"hostname":"localhost","ip":"127.0.0.1","hostnames":[{"type":"PTR","name":"localhost"}],"vendor":null,"status":"up","addresses":[{"address":"127.0.0.1","type":"ipv4"}],"os_accuracy":null,"os":null,"services":null,"type":"unknown"}],"duration":0,"start_time":1747232859}
    ...       2     --nmap-options='-sS -sU -R -O --osscan-limit --osscan-guess -p U:161,162,T:21-25,80,139,443,3306,5985,5986,8080,8443 -oX - '                   {"end_time":1747232859,"discovered_items":1,"results":[{"hostname":"localhost","ip":"127.0.0.1","hostnames":[{"type":"PTR","name":"localhost"}],"vendor":null,"status":"up","addresses":[{"address":"127.0.0.1","type":"ipv4"}],"os_accuracy":null,"os":null,"services":null,"type":"unknown"}],"duration":1,"start_time":1747232859}
    ...       3     --nmap-options='-sS -oX - '    {"results":[{"ip":"127.0.0.1","type":"unknown","os_accuracy":null,"status":"up","services":null,"hostnames":[{"type":"PTR","name":"localhost"}],"os":null,"hostname":"localhost","vendor":null,"addresses":[{"address":"127.0.0.1","type":"ipv4"}]}],"duration":0,"discovered_items":1,"start_time":1747234100,"end_time":1747234100}

*** Keywords ***
