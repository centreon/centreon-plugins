%centreon_vmware_config = (
    vsphere_server => {
        'default'    => {
            'url'      => 'https://vcenter/sdk',
            'username' => 'XXXXXX',
            'password' => 'XXXXXX'
        },
        'additional' => {
            'url'      => 'https://vcenter2/sdk',
            'username' => 'XXXXXX',
            'password' => 'XXXXXX'
        }
    },
    credstore_use => 0,
    credstore_file => '/root/.vmware/credstore/vicredentials.xml',
    timeout_vsphere => 60,
    timeout => 60,
    timeout_kill => 30,
    dynamic_timeout_kill => 86400,
    refresh_keeper_session => 15,
    bind => '*',
    port => 5700,
    ipc_file => '/tmp/centreon_vmware/routing.ipc',
    case_insensitive => 0,
    vsan_sdk_path => '/usr/local/share/perl5/VMware'
);

1;
