*** Settings ***
Documentation       Application Microsoft HyperV 2022

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=apps::microsoft::hyperv::2012::local::plugin
...         --mode=scvmm-discovery
...         --scvmm-username='username'
...         --scvmm-password='password'
...         --command=cat
...         --command-path=/usr/bin
...         --no-ps


*** Test Cases ***
HyperV 2022-2 ${tc}
    [Documentation]    Apps Microsoft HyperV 2022
    [Tags]    applications    microsoft    hyperv    virtualization
    ${command}    Catenate
    ...    ${CMD}
    ...    --command-options=${CURDIR}/scvmmdiscovery.json
    ...    --resource-type='${resource_type}'
    ...    | jq -c --sort-keys

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:        tc    resource_type       expected_result    --
            ...      1     ${EMPTY}            \\\\{"discovered_items":1,"duration":0,"end_time":\\\\d+,"results":\\\\[\\\\{"cluster_name":null,"computer_name":"computer1.centreon.local","description":"description","enabled":"yes","hostgroup_path":"Hostgroup1","id":"VM-123","ipv4_address":"10.0.0.1","ipv4_addresses":\\\\["10.0.0.1"\\\\],"name":"Computer1","operating_system":"Windows Server 2022 Standard","status":"Running","tag":"\\\\(aucun\\\\)","type":"vm","vmhost_name":null\\\\}\\\\],"start_time":\\\\d+\\\\}
            ...      2     vm                  \\\\{"discovered_items":1,"duration":0,"end_time":\\\\d+,"results":\\\\[\\\\{"cluster_name":null,"computer_name":"computer1.centreon.local","description":"description","enabled":"yes","hostgroup_path":"Hostgroup1","id":"VM-123","ipv4_address":"10.0.0.1","ipv4_addresses":\\\\["10.0.0.1"\\\\],"name":"Computer1","operating_system":"Windows Server 2022 Standard","status":"Running","tag":"\\\\(aucun\\\\)","type":"vm","vmhost_name":null\\\\}\\\\],"start_time":\\\\d+\\\\}
            ...      3     host                \\\\{"discovered_items":1,"duration":0,"end_time":\\\\d+,"results":\\\\[\\\\{"cluster_name":"cluster.centreon.local","description":"description","fqdn":null,"id":"CL-456","name":"host.centreon.local","operating_system":"Windows Server 2022 Standard","type":"host"\\\\}\\\\],"start_time":\\\\d+\\\\}
