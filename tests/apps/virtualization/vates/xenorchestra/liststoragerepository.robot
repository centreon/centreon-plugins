*** Settings ***
Documentation       apps::virtualization::vates::xenorchestra::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}             ${CURDIR}${/}..${/}mockoon.json
${CMD}                      ${CENTREON_PLUGINS}
...                         --plugin=apps::virtualization::vates::xenorchestra::plugin
...                         --mode=list-storage-repository
...                         --password=C3POR2P2
...                         --username=obi-wan
...                         --hostname=127.0.0.1
...                         --proto=http
...                         --port=3000

${EXPECTED_RUN_OUTPUT}
...                         List storage repository:
...                         ${SPACE}DVD drives [uuid=2b080701-641c-c1ba-6320-7631a0c8b452] [type=SR] [content_type=iso] [allocationStrategy=thick] [inMaintenanceMode=false] [name_description=Physical DVD drives] [shared=false] [SR_type=udev] [pool_uuid=00969214-df4d-83cb-78d5-bec9181903d4] [tags=]
...                         ${SPACE}Local storage [uuid=6c9bb023-f6da-0fe5-647c-23aae1dca3c7] [type=SR] [content_type=user] [allocationStrategy=thin] [inMaintenanceMode=false] [name_description=] [shared=false] [SR_type=ext] [pool_uuid=00969214-df4d-83cb-78d5-bec9181903d4] [tags=]
...                         ${SPACE}Removable storage [uuid=8459c9c0-26cc-ac1d-7604-1d2516d5d2b3] [type=SR] [content_type=disk] [allocationStrategy=thick] [inMaintenanceMode=false] [name_description=] [shared=false] [SR_type=udev] [pool_uuid=00969214-df4d-83cb-78d5-bec9181903d4] [tags=]
...                         ${SPACE}XCP-ng Tools [uuid=13ef4c75-f235-d3e8-354b-602588775129] [type=SR] [content_type=iso] [allocationStrategy=] [inMaintenanceMode=false] [name_description=XCP-ng Tools ISOs] [shared=true] [SR_type=iso] [pool_uuid=00969214-df4d-83cb-78d5-bec9181903d4] [tags=]
...                         ${SPACE}DVD drives [uuid=da92118c-28a5-7342-5f0f-2da33889f402] [type=SR] [content_type=iso] [allocationStrategy=thick] [inMaintenanceMode=false] [name_description=Physical DVD drives] [shared=false] [SR_type=udev] [pool_uuid=00969214-df4d-83cb-78d5-bec9181903d4] [tags=]
...                         ${SPACE}Removable storage [uuid=289ada4a-690d-0200-9798-6ba61a2733f5] [type=SR] [content_type=disk] [allocationStrategy=thick] [inMaintenanceMode=false] [name_description=] [shared=false] [SR_type=udev] [pool_uuid=00969214-df4d-83cb-78d5-bec9181903d4] [tags=]
...                         ${SPACE}Removable storage [uuid=e205b9ea-fbdf-6461-cd6c-0d6b606d2237] [type=SR] [content_type=disk] [allocationStrategy=thick] [inMaintenanceMode=false] [name_description=] [shared=false] [SR_type=udev] [pool_uuid=00969214-df4d-83cb-78d5-bec9181903d4] [tags=]
...                         ${SPACE}nfs-HA-storage [uuid=89384d98-8d32-bc6b-1ada-dc8471126182] [type=SR] [content_type=user] [allocationStrategy=thin] [inMaintenanceMode=false] [name_description=HA storage for pool sync process] [shared=true] [SR_type=nfs] [pool_uuid=00969214-df4d-83cb-78d5-bec9181903d4] [tags=]
...                         ${SPACE}DVD drives [uuid=6f69a241-378e-e71e-2800-7a2157d78262] [type=SR] [content_type=iso] [allocationStrategy=thick] [inMaintenanceMode=false] [name_description=Physical DVD drives] [shared=false] [SR_type=udev] [pool_uuid=00969214-df4d-83cb-78d5-bec9181903d4] [tags=]
...                         ${SPACE}ISO [uuid=708e914c-ddb6-73c1-c0ee-be0c9f0d3735] [type=SR] [content_type=iso] [allocationStrategy=] [inMaintenanceMode=false] [name_description=ISO storage description] [shared=false] [SR_type=iso] [pool_uuid=00969214-df4d-83cb-78d5-bec9181903d4] [tags=]
...                         ${SPACE}HA [uuid=feb9d63f-6291-52f0-ec46-257c35048e73] [type=SR] [content_type=user] [allocationStrategy=thin] [inMaintenanceMode=false] [name_description=ha storage] [shared=true] [SR_type=linstor] [pool_uuid=00969214-df4d-83cb-78d5-bec9181903d4] [tags=]


*** Test Cases ***
List Storage Repository
    [Tags]    apps    virtualization    xenorchestra    discovery
    Ctn Run Command And Check Result As Strings    ${CMD}    ${EXPECTED_RUN_OUTPUT}

List Storage Repository Disco Format
    [Tags]    apps    virtualization    xenorchestra    discovery
    ${command}=    Catenate    ${CMD}    --disco-format

    ${root}=    Ctn Run Command And Return Parsed XML    ${command}
    ${nb_elements}=    Get Element Count    ${root}    element

    Should Be Equal As Integers
    ...    ${nb_elements}
    ...    11
    ...    Number of disco-format elements does not match for command:${\n}${command}${\n}

    @{elements}=    Get Elements Texts    ${root}    element
    @{expected_elements}=    Create List
    ...    name    uuid    type    content_type    allocationStrategy    inMaintenanceMode
    ...    name_description    shared    SR_type    pool_uuid    tags
    Lists Should Be Equal    ${elements}    ${expected_elements}

List Storage Repository Disco Show
    [Tags]    apps    virtualization    xenorchestra    discovery
    ${command}=    Catenate    ${CMD}    --disco-show

    ${root}=    Ctn Run Command And Return Parsed XML    ${command}
    ${nb_items}=    Get Element Count    ${root}    label

    Should Be Equal As Integers
    ...    ${nb_items}
    ...    11
    ...    Number of storage repositories does not match for command:${\n}${command}${\n}

    # check every attribute of one storage repository
    ${nfs_sr}=    Get Element    ${root}    label[@uuid="89384d98-8d32-bc6b-1ada-dc8471126182"]
    Should Be Equal    ${nfs_sr.attrib['name']}    nfs-HA-storage
    Should Be Equal    ${nfs_sr.attrib['uuid']}    89384d98-8d32-bc6b-1ada-dc8471126182
    Should Be Equal    ${nfs_sr.attrib['type']}    SR
    Should Be Equal    ${nfs_sr.attrib['content_type']}    user
    Should Be Equal    ${nfs_sr.attrib['allocationStrategy']}    thin
    Should Be Equal    ${nfs_sr.attrib['inMaintenanceMode']}    false
    Should Be Equal    ${nfs_sr.attrib['name_description']}    HA storage for pool sync process
    Should Be Equal    ${nfs_sr.attrib['shared']}    true
    Should Be Equal    ${nfs_sr.attrib['SR_type']}    nfs
    Should Be Equal    ${nfs_sr.attrib['pool_uuid']}    00969214-df4d-83cb-78d5-bec9181903d4
    Should Be Equal    ${nfs_sr.attrib['tags']}    ${EMPTY}
