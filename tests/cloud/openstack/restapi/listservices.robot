*** Settings ***
Documentation       OpenStack List-Services

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}openstack.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS} 
...                 --plugin=cloud::openstack::restapi::plugin
...                 --identity-url=http://${HOSTNAME}:${APIPORT}/v3
...                 --mode=list-services
...                 --username=xxx
...                 --password=P@s$WoRdZ


*** Test Cases ***
ListServices ${tc}
    [Tags]    cloud     openstack     api
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_string}

    Examples:        tc       extraoptions                                         expected_string    --
           ...       1        ${EMPTY}                                             List service: [Type = compute][Name = nova][Region = -][Label = nova compute (global)] [Type = compute][Name = nova][Region = microstack][Label = nova compute microstack] [Type = identity][Name = keystone][Region = -][Label = keystone identity (global)] [Type = identity][Name = keystone][Region = microstack][Label = keystone identity microstack] [Type = image][Name = glance][Region = -][Label = glance image (global)] [Type = image][Name = glance][Region = microstack][Label = glance image microstack] [Type = network][Name = neutron][Region = -][Label = neutron network (global)] [Type = network][Name = neutron][Region = microstack][Label = neutron network microstack] [Type = placement][Name = placement][Region = -][Label = placement placement (global)] [Type = placement][Name = placement][Region = microstack][Label = placement placement microstack] [Type = volumev2][Name = cinderv2][Region = -][Label = cinderv2 volumev2 (global)] [Type = volumev2][Name = cinderv2][Region = microstack][Label = cinderv2 volumev2 microstack] [Type = volumev3][Name = cinderv3][Region = -][Label = cinderv3 volumev3 (global)] [Type = volumev3][Name = cinderv3][Region = microstack][Label = cinderv3 volumev3 microstack]
           ...       2        --disco-show --include-type=placement                <?xml version="1.0" encoding="utf-8"?> <data> <label label="placement placement (global)" name="placement" region="" type="placement"/> <label label="placement placement microstack" name="placement" region="microstack" type="placement"/> </data>
           ...       3        --disco-show --include-name=nova                     <?xml version="1.0" encoding="utf-8"?> <data> <label label="nova compute (global)" name="nova" region="" type="compute"/> <label label="nova compute microstack" name="nova" region="microstack" type="compute"/> </data>
           ...       4        --disco-show --exclude-region=microstack             <?xml version="1.0" encoding="utf-8"?> <data> <label label="nova compute (global)" name="nova" region="" type="compute"/> <label label="keystone identity (global)" name="keystone" region="" type="identity"/> <label label="glance image (global)" name="glance" region="" type="image"/> <label label="neutron network (global)" name="neutron" region="" type="network"/> <label label="placement placement (global)" name="placement" region="" type="placement"/> <label label="cinderv2 volumev2 (global)" name="cinderv2" region="" type="volumev2"/> <label label="cinderv3 volumev3 (global)" name="cinderv3" region="" type="volumev3"/> </data>
           ...       5        --disco-format                                       <?xml version="1.0" encoding="utf-8"?> <data> <element>type</element> <element>name</element> <element>region</element> <element>label</element> </data>

