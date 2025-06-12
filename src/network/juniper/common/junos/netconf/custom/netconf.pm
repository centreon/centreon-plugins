#
# Copyright 2025 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package network::juniper::common::junos::netconf::custom::netconf;

use strict;
use warnings;
use centreon::plugins::ssh;
use centreon::plugins::misc;
use XML::LibXML::Simple;
use centreon::plugins::statefile;

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'hostname:s'        => { name => 'hostname' },
            'timeout:s'         => { name => 'timeout', default => 45 },
            'command:s'         => { name => 'command' },
            'command-path:s'    => { name => 'command_path' },
            'command-options:s' => { name => 'command_options' },
            'cache-use'         => { name => 'cache_use' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'SSH OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{ssh} = centreon::plugins::ssh->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        $self->{ssh}->check_options(
            option_results   => $self->{option_results},
            default_ssh_port => 830
        );

        if ($self->{ssh}->get_ssh_backend() !~ /^sshcli$/) {
            $self->{output}->add_option_msg(short_msg => 'unsupported ssh backend (sshcli only)');
            $self->{output}->option_exit();
        }
    }

    centreon::plugins::misc::check_security_command(
        output          => $self->{output},
        command         => $self->{option_results}->{command},
        command_options => $self->{option_results}->{command_options},
        command_path    => $self->{option_results}->{command_path}
    );

    $self->{cache}->check_options(option_results => $self->{option_results}, default_format => 'json');

    return 0;
}

sub get_identifier {
    my ($self, %options) = @_;

    my $id = defined($self->{option_results}->{hostname}) ? $self->{option_results}->{hostname} : 'me';
    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        $id .= ':' . $self->{ssh}->get_port();
    }
    return $id;
}

sub load_xml {
    my ($self, %options) = @_;

    my $content;

    if (!defined($options{middle_tag})) {
        if ($options{data} =~ /($options{start_tag}.*?$options{end_tag})/ms) {
            $content = $1;
        }
    } else {
        while ($options{data} =~ /($options{start_tag}.*?$options{end_tag})/msg) {
            my $matched = $1;
            if ($1 =~ /$options{middle_tag}/ms) {
                $content = $matched;
                last;
            }
        }
    }

    if (!defined($content)) {
        if (defined($options{error_continue}) && $options{error_continue} == 1) {
            return {};
        }

        $self->{output}->add_option_msg(short_msg => "Cannot find information");
        $self->{output}->option_exit();
    }

    $content =~ s/junos://msg;

    my $xml_result;
    eval {
        $SIG{__WARN__} = sub {};
        $xml_result = XMLin($content, ForceArray => $options{force_array}, KeyAttr => []);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode xml response: $@");
        $self->{output}->option_exit();
    }

    return $xml_result;
}

sub execute_command {
    my ($self, %options) = @_;

    $self->{ssh_commands} = '';
    my $append = '';
    foreach (@{$options{commands}}) {
        $self->{ssh_commands} .= $append . " $_";
        $append = "\n]]>]]>\n\n";
    }

    my $content;
    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        ($content) = $self->{ssh}->execute(
            ssh_pipe                  => 1,
            hostname                  => $self->{option_results}->{hostname},
            command                   => $self->{ssh_commands},
            timeout                   => $self->{option_results}->{timeout},
            default_sshcli_option_eol => [ '-s=netconf' ]
        );
    } else {
        if (!defined($self->{option_results}->{command}) || $self->{option_results}->{command} eq '') {
            $self->{output}->add_option_msg(short_msg => 'please set --hostname option for ssh connection (or --command for local)');
            $self->{output}->option_exit();
        }
        ($content) = centreon::plugins::misc::execute(
            ssh_pipe        => 1,
            output          => $self->{output},
            options         => { timeout => $self->{option_results}->{timeout} },
            command         => $self->{option_results}->{command},
            command_path    => $self->{option_results}->{command_path},
            command_options => defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '' ? $self->{option_results}->{command_options} : undef
        );
    }

    return $content;
}

my $commands = {
    'show chassis routing-engine'        => '<rpc><get-route-engine-information></get-route-engine-information></rpc>',
    'show chassis fpc'                   => '<rpc><get-fpc-information></get-fpc-information></rpc>',
    'show system storage detail'         => '<rpc><get-system-storage><detail/></get-system-storage></rpc>',
    'show chassis environment'           => '<rpc><get-environment-information></get-environment-information></rpc>',
    'show chassis power'                 => '<rpc><get-power-usage-information></get-power-usage-information></rpc>',
    'show chassis fan'                   => '<rpc><get-fan-information></get-fan-information></rpc>',
    'show chassis fpc pic-status'        => '<rpc><get-pic-information></get-pic-information></rpc>',
    'show chassis afeb'                  => '<rpc><get-afeb-information></get-afeb-information></rpc>',
    'show chassis hardware'              => '<rpc><get-chassis-inventory></get-chassis-inventory></rpc>',
    'show interfaces extensive'          => '<rpc><get-interface-information><extensive/></get-interface-information></rpc>',
    'show bgp neighbor'                  => '<rpc><get-bgp-neighbor-information></get-bgp-neighbor-information></rpc>',
    'show ldp session extensive'         => '<rpc><get-ldp-session-information><extensive/></get-ldp-session-information></rpc>',
    'show mpls lsp'                      => '<rpc><get-mpls-lsp-information><statistics/></get-mpls-lsp-information></rpc>',
    'show rsvp session statistics'       => '<rpc><get-rsvp-session-information><statistics/></get-rsvp-session-information></rpc>',
    'show services rpm probe-results'    => '<rpc><get-probe-results></get-probe-results></rpc>',
    'show ospf neighbor detail'          => '<rpc><get-ospf-neighbor-information><detail/></get-ospf-neighbor-information></rpc>',
    'show interfaces diagnostics optics' => '<rpc><get-interface-optics-diagnostics-information /></rpc>'
};

sub get_rpc_commands {
    my ($self, %options) = @_;

    my $rpc_commands = {};
    foreach my $command (@{$options{commands}}) {
        next if ($command eq '' || $command !~ /([a-z_]+)/);
        my $label = $1;
        if ($label eq 'cpu') {
            $rpc_commands->{'show chassis routing-engine'} = $commands->{'show chassis routing-engine'};
            $rpc_commands->{'show chassis fpc'} = $commands->{'show chassis fpc'};
        } elsif ($label eq 'disk') {
            $rpc_commands->{'show system storage detail'} = $commands->{'show system storage detail'};
        } elsif ($label eq 'hardware') {
            $rpc_commands->{'show chassis environment'} = $commands->{'show chassis environment'};
            $rpc_commands->{'show chassis power'} = $commands->{'show chassis power'};
            $rpc_commands->{'show chassis fan'} = $commands->{'show chassis fan'};
            $rpc_commands->{'show chassis fpc'} = $commands->{'show chassis fpc'};
            $rpc_commands->{'show chassis fpc pic-status'} = $commands->{'show chassis fpc pic-status'};
            $rpc_commands->{'show chassis afeb'} = $commands->{'show chassis afeb'};
            $rpc_commands->{'show chassis hardware'} = $commands->{'show chassis hardware'};
        } elsif ($label eq 'interface') {
            $rpc_commands->{'show interfaces extensive'} = $commands->{'show interfaces extensive'};
        } elsif ($label eq 'interface_optical') {
            $rpc_commands->{'show interfaces diagnostics optics'} = $commands->{'show interfaces diagnostics optics'};
        } elsif ($label eq 'memory') {
            $rpc_commands->{'show chassis routing-engine'} = $commands->{'show chassis routing-engine'};
            $rpc_commands->{'show chassis fpc'} = $commands->{'show chassis fpc'};
        } elsif ($label eq 'bgp') {
            $rpc_commands->{'show bgp neighbor'} = $commands->{'show bgp neighbor'};
        } elsif ($label eq 'ldp') {
            $rpc_commands->{'show ldp session extensive'} = $commands->{'show ldp session extensive'};
        } elsif ($label eq 'lsp') {
            $rpc_commands->{'show mpls lsp'} = $commands->{'show mpls lsp'};
        } elsif ($label eq 'rsvp') {
            $rpc_commands->{'show rsvp session statistics'} = $commands->{'show rsvp session statistics'};
        } elsif ($label eq 'service_rpm') {
            $rpc_commands->{'show services rpm probe-results'} = $commands->{'show services rpm probe-results'};
        } elsif ($label eq 'ospf') {
            $rpc_commands->{'show ospf neighbor detail'} = $commands->{'show ospf neighbor detail'};
        } else {
            $self->{output}->add_option_msg(short_msg => "unsupported command: $command");
            $self->{output}->option_exit();
        }
    }

    return [ values(%$rpc_commands) ];
}

sub get_cache_file_response_command {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_juniper_api_' . $self->get_identifier());
    my $response = $self->{cache}->get(name => 'response');
    if (!defined($response)) {
        $self->{output}->add_option_msg(short_msg => 'Cache file missing');
        $self->{output}->option_exit();
    }
    if (!defined($response->{ $options{command} })) {
        $self->{output}->add_option_msg(short_msg => "Command '$options{command} missing in cache file");
        $self->{output}->option_exit();
    }

    return $response->{ $options{command }};
}

sub cache_commands {
    my ($self, %options) = @_;

    my $content = $self->execute_command(commands => $self->get_rpc_commands(commands => $options{commands}));
    my $response = {};
    foreach my $command (@{$options{commands}}) {
        next if ($command eq '' || $command !~ /([a-z]+)/);
        my $label = $1;
        my $method = $self->can('get_' . $label . '_infos');
        if ($method) {
            my $result = $self->$method(content => $content);
            $response->{$label} = $result;
        }
    }

    $self->{cache}->read(statefile => 'cache_juniper_api_' . $self->get_identifier());
    $self->{cache}->write(data => {
        update_time => time(),
        response    => $response
    });
}

sub get_command_raw_result {
    my ($self, %options) = @_;

    my $content = $self->execute_command(commands => [ $options{command} ]);
    $content =~ /(<nc:rpc-reply.*<\/nc:rpc-reply>)/msg;
    $content = $1;
    $content =~ s/junos://msg;
    return $content;
}

sub get_cpu_infos {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{cache_use})) {
        return $self->get_cache_file_response_command(command => 'cpu');
    }

    my $content = $options{content};
    if (!defined($content)) {
        $content = $self->execute_command(commands => $self->get_rpc_commands(commands => [ 'cpu' ]));
    }

    my $results = [];
    my $result = $self->load_xml(data => $content, start_tag => '<route-engine-information.*?>', end_tag => '</route-engine-information>', force_array => [ 'route-engine' ]);

    foreach (@{$result->{'route-engine'}}) {
        push @$results, {
            name          => 'route engine slot ' . $_->{slot},
            cpu_1min_avg  => 100 - $_->{'cpu-idle1'},
            cpu_5min_avg  => 100 - $_->{'cpu-idle2'},
            cpu_15min_avg => 100 - $_->{'cpu-idle3'}
        };
    }

    $result = $self->load_xml(data => $content, start_tag => '<fpc-information.*?>', end_tag => '</fpc-information>', force_array => [ 'fpc' ]);

    foreach (@{$result->{fpc}}) {
        next if (!defined($_->{'cpu-1min-avg'}));

        push @$results, {
            name          => 'fpc slot ' . $_->{slot},
            cpu_1min_avg  => $_->{'cpu-1min-avg'},
            cpu_5min_avg  => $_->{'cpu-5min-avg'},
            cpu_15min_avg => $_->{'cpu-15min-avg'}
        };
    }

    return $results;
}

sub get_disk_infos {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{cache_use})) {
        return $self->get_cache_file_response_command(command => 'disk');
    }

    my $content = $options{content};
    if (!defined($content)) {
        $content = $self->execute_command(commands => $self->get_rpc_commands(commands => [ 'disk' ]));
    }

    my $results = [];
    my $result = $self->load_xml(data => $content, start_tag => '<system-storage-information.*?>', end_tag => '</system-storage-information>', force_array => [ 'filesystem' ]);

    foreach (@{$result->{filesystem}}) {
        push @$results, {
            mount           => centreon::plugins::misc::trim($_->{'mounted-on'}),
            space_used      => $_->{'used-blocks'}->{format} * 1024,
            space_total     => $_->{'total-blocks'}->{format} * 1024,
            space_free      => $_->{'available-blocks'}->{format} * 1024,
            space_used_prct => centreon::plugins::misc::trim($_->{'used-percent'}),
            space_free_prct => 100 - centreon::plugins::misc::trim($_->{'used-percent'})
        };
    }

    return $results;
}

sub get_hardware_infos {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{cache_use})) {
        return $self->get_cache_file_response_command(command => 'hardware');
    }

    my $content = $options{content};
    if (!defined($content)) {
        $content = $self->execute_command(commands => $self->get_rpc_commands(commands => [ 'hardware' ]));
    }

    my $results = { 'fan' => [], 'psu' => [], 'env' => [], 'fpc' => [], 'pic' => {}, mic => {}, 'afeb' => [] };
    my $result = $self->load_xml(data => $content, start_tag => '<fan-information.*?>', end_tag => '</fan-information>', force_array => [ 'fan-information-rpm-item' ]);

    foreach (@{$result->{'fan-information-rpm-item'}}) {
        push @{$results->{fan}}, {
            name   => $_->{name},
            status => $_->{status},
            rpm    => $_->{rpm}
        };
    }

    $result = $self->load_xml(data => $content, start_tag => '<power-usage-information.*?>', end_tag => '</power-usage-information>', force_array => [ 'power-usage-item' ], error_continue => 1);

    if (defined($result->{'power-usage-item'})) {
        foreach (@{$result->{'power-usage-item'}}) {
            push @{$results->{psu}}, {
                name           => $_->{name},
                status         => $_->{state},
                dc_output_load => $_->{'dc-output-detail'}->{'dc-load'}
            };
        }
    }

    $result = $self->load_xml(data => $content, start_tag => '<environment-information.*?>', end_tag => '</environment-information>', force_array => [ 'environment-item' ]);

    foreach (@{$result->{'environment-item'}}) {
        my $temperature = '';
        if ($_->{class} eq 'Temp') {
            $temperature = $_->{temperature}->{celsius};
        }
        push @{$results->{env}}, {
            name        => $_->{name},
            status      => $_->{status},
            class       => $_->{class},
            temperature => $temperature
        };
    }

    $result = $self->load_xml(
        data        => $content,
        start_tag   => '<fpc-information',
        end_tag     => '</fpc-information>',
        middle_tag  => 'fpc.*?(cpu-15min-avg|memory-dram-size)',
        force_array => [ 'fpc' ]
    );

    foreach (@{$result->{fpc}}) {
        push @{$results->{fpc}}, {
            name   => 'fpc slot ' . $_->{slot},
            status => $_->{state}
        };
    }

    $result = $self->load_xml(data => $content, start_tag => '<scb-information.*?>', end_tag => '</scb-information>', force_array => [ 'scb' ], error_continue => 1);

    foreach (@{$result->{scb}}) {
        push @{$results->{afeb}}, {
            name   => 'afeb slot ' . $_->{slot},
            status => $_->{state}
        };
    }

    $result = $self->load_xml(
        data           => $content,
        start_tag      => '<fpc-information',
        end_tag        => '</fpc-information>',
        middle_tag     => 'pic-state',
        force_array    => [ 'fpc', 'pic' ],
        error_continue => 1
    );

    foreach my $fpc (@{$result->{fpc}}) {
        foreach (@{$fpc->{pic}}) {
            $results->{pic}->{'fpc' . $fpc->{slot} . '-pic' . $_->{'pic-slot'}} = {
                fpc_slot    => $fpc->{slot},
                pic_slot    => $_->{'pic-slot'},
                description => $_->{'pic-type'},
                instance    => $fpc->{slot} . '/' . $_->{'pic-slot'},
                status      => $_->{'pic-state'}
            };
        }
    }

    $result = $self->load_xml(
        data        => $content,
        start_tag   => '<chassis-inventory.*?>',
        end_tag     => '</chassis-inventory>',
        force_array => [ 'chassis-sub-module', 'chassis-sub-sub-module' ]
    );

    foreach my $module (@{$result->{chassis}->{'chassis-module'}}) {
        next if ($module->{name} !~ /FPC\s+(\d+)/ || !defined($module->{'chassis-sub-module'}));
        my $fpc_slot = $1;

        foreach my $submodule (@{$module->{'chassis-sub-module'}}) {
            next if ($submodule->{name} !~ /MIC\s+(\d+)/ || !defined($submodule->{'chassis-sub-sub-module'}));
            my $mic_slot = $1;

            $results->{mic}->{'fpc' . $fpc_slot . '-mic' . $mic_slot} = {
                pics        => [],
                fpc_slot    => $fpc_slot,
                mic_slot    => $mic_slot,
                instance    => $fpc_slot . '/' . $mic_slot,
                description => $submodule->{description}
            };
            foreach my $subsubmodule (@{$submodule->{'chassis-sub-sub-module'}}) {
                next if ($subsubmodule->{name} !~ /PIC\s+(\d+)/);
                my $pic_slot = $1;

                push @{$results->{mic}->{'fpc' . $fpc_slot . '-mic' . $mic_slot}->{pics}}, 'fpc' . $fpc_slot . '-pic' . $pic_slot;
                $results->{pic}->{'fpc' . $fpc_slot . '-pic' . $pic_slot}->{mic_slot} = $mic_slot;
                $results->{pic}->{'fpc' . $fpc_slot . '-pic' . $pic_slot}->{instance} = $fpc_slot . '/' . $mic_slot . '/' . $pic_slot;
            }
        }
    }

    return $results;
}

sub get_interface_infos {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{cache_use})) {
        return $self->get_cache_file_response_command(command => 'interface');
    }

    my $content = $options{content};
    if (!defined($content)) {
        $content = $self->execute_command(commands => $self->get_rpc_commands(commands => [ 'interface' ]));
    }

    my $results = [];
    my $result = $self->load_xml(
        data        => $content,
        start_tag   => '<interface-information',
        end_tag     => '</interface-information>',
        middle_tag  => 'admin-status',
        force_array => [ 'physical-interface', 'logical-interface' ]
    );

    foreach (@{$result->{'physical-interface'}}) {
        my $speed = centreon::plugins::misc::trim($_->{'speed'});
        my ($speed_unit, $speed_value);
        if ($speed =~ /^\s*([0-9]+)\s*([A-Za-z])/) {
            ($speed_value, $speed_unit) = ($1, $2);
        }
        $speed = centreon::plugins::misc::scale_bytesbit(
            value        => $speed_value,
            src_quantity => $speed_unit,
            dst_quantity => '',
            src_unit     => 'b',
            dst_unit     => 'b'
        );

        my $descr = centreon::plugins::misc::trim($_->{'description'});
        my $name = centreon::plugins::misc::trim($_->{'name'});

        my $item = {
            descr     => defined($descr) && $descr ne '' ? $descr : $name,
            name      => $name,
            opstatus  => centreon::plugins::misc::trim($_->{'oper-status'}),
            admstatus => centreon::plugins::misc::trim($_->{'admin-status'}->{content}),
            in        => centreon::plugins::misc::trim($_->{'traffic-statistics'}->{'input-bytes'}) * 8,
            out       => centreon::plugins::misc::trim($_->{'traffic-statistics'}->{'output-bytes'}) * 8,
            inPkts    => centreon::plugins::misc::trim($_->{'traffic-statistics'}->{'input-packets'}),
            outPkts   => centreon::plugins::misc::trim($_->{'traffic-statistics'}->{'output-packets'}),
            speed     => $speed
        };
        if (defined($_->{'input-error-list'})) {
            foreach my $label (keys %{$_->{'input-error-list'}}) {
                $item->{'counter-in-' . $label} = centreon::plugins::misc::trim($_->{'input-error-list'}->{$label});
            }
        }
        if (defined($_->{'output-error-list'})) {
            foreach my $label (keys %{$_->{'output-error-list'}}) {
                $item->{'counter-out-' . $label} = centreon::plugins::misc::trim($_->{'output-error-list'}->{$label});
            }
        }

        push @$results, $item;

        foreach my $logint (@{$_->{'logical-interface'}}) {
            push @$results, {
                descr     => centreon::plugins::misc::trim($logint->{'name'}),
                name      => centreon::plugins::misc::trim($logint->{'name'}),
                opstatus  => centreon::plugins::misc::trim($_->{'oper-status'}),
                admstatus => centreon::plugins::misc::trim($_->{'admin-status'}->{content}),
                in        => centreon::plugins::misc::trim($logint->{'traffic-statistics'}->{'input-bytes'}) * 8,
                out       => centreon::plugins::misc::trim($logint->{'traffic-statistics'}->{'output-bytes'}) * 8,
                speed     => $speed
            };
        }
    }

    return $results;
}

sub get_interface_optical_infos {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{cache_use})) {
        return $self->get_cache_file_response_command(command => 'interface_optical');
    }

    my $content = $options{content};
    if (!defined($content)) {
        $content = $self->execute_command(commands => $self->get_rpc_commands(commands => [ 'interface_optical' ]));
    }

    my $results = [];
    my $result = $self->load_xml(
        data        => $content,
        start_tag   => '<interface-information',
        end_tag     => '</interface-information>',
        middle_tag  => 'optics-diagnostics',
        force_array => [ 'physical-interface' ]
    );

    foreach (@{$result->{'physical-interface'}}) {
        my $entry = { name => centreon::plugins::misc::trim($_->{'name'}) };

        if (defined($_->{'optics-diagnostics'}->{'laser-output-power-dbm'})) {
            $entry->{outputPowerDbm} = centreon::plugins::misc::trim($_->{'optics-diagnostics'}->{'laser-output-power-dbm'});
            $entry->{outputPowerDbmLowAlarmCrit} = centreon::plugins::misc::trim($_->{'optics-diagnostics'}->{'laser-tx-power-low-alarm-threshold-dbm'});
            $entry->{outputPowerDbmHighAlarmCrit} = centreon::plugins::misc::trim($_->{'optics-diagnostics'}->{'laser-tx-power-high-alarm-threshold-dbm'});
            $entry->{outputPowerDbmLowAlarmWarn} = centreon::plugins::misc::trim($_->{'optics-diagnostics'}->{'laser-tx-power-low-warn-threshold-dbm'});
            $entry->{outputPowerDbmHighAlarmWarn} = centreon::plugins::misc::trim($_->{'optics-diagnostics'}->{'laser-tx-power-high-warn-threshold-dbm'});
        }
        if (defined($_->{'optics-diagnostics'}->{'laser-input-power-dbm'})) {
            $entry->{inputPowerDbm} = centreon::plugins::misc::trim($_->{'optics-diagnostics'}->{'laser-input-power-dbm'});
            $entry->{inputPowerDbmLowAlarmCrit} = centreon::plugins::misc::trim($_->{'optics-diagnostics'}->{'laser-rx-power-low-alarm-threshold-dbm'});
            $entry->{inputPowerDbmHighAlarmCrit} = centreon::plugins::misc::trim($_->{'optics-diagnostics'}->{'laser-rx-power-high-alarm-threshold-dbm'});
            $entry->{inputPowerDbmLowAlarmWarn} = centreon::plugins::misc::trim($_->{'optics-diagnostics'}->{'laser-rx-power-low-warn-threshold-dbm'});
            $entry->{inputPowerDbmHighAlarmWarn} = centreon::plugins::misc::trim($_->{'optics-diagnostics'}->{'laser-rx-power-high-warn-threshold-dbm'});
        }

        $entry->{biasCurrent} = centreon::plugins::misc::trim($_->{'optics-diagnostics'}->{'laser-bias-current'});
        $entry->{moduleTemperature} = centreon::plugins::misc::trim($_->{'optics-diagnostics'}->{'module-temperature'}->{celsius});

        push @$results, $entry;
    }

    return $results;
}

sub get_memory_infos {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{cache_use})) {
        return $self->get_cache_file_response_command(command => 'memory');
    }

    my $content = $options{content};
    if (!defined($content)) {
        $content = $self->execute_command(commands => $self->get_rpc_commands(commands => [ 'memory' ]));
    }

    my $results = [];
    my $result = $self->load_xml(data => $content, start_tag => '<route-engine-information.*?>', end_tag => '</route-engine-information>', force_array => [ 'route-engine' ]);

    foreach (@{$result->{'route-engine'}}) {
        push @$results, {
            name     => 'route engine slot ' . $_->{slot},
            mem_used => $_->{'memory-buffer-utilization'}
        };
    }

    $result = $self->load_xml(data => $content, start_tag => '<fpc-information.*?>', end_tag => '</fpc-information>', force_array => [ 'fpc' ]);

    foreach (@{$result->{fpc}}) {
        next if (!defined($_->{'memory-heap-utilization'}));

        push @$results, {
            name     => 'fpc slot ' . $_->{slot} . ' heap',
            mem_used => $_->{'memory-heap-utilization'}
        },   {
                 name     => 'fpc slot ' . $_->{slot} . ' buffer',
                 mem_used => $_->{'memory-buffer-utilization'}
             };
    }

    return $results;
}

sub get_ospf_infos {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{cache_use})) {
        return $self->get_cache_file_response_command(command => 'ospf');
    }

    my $content = $options{content};
    if (!defined($content)) {
        $content = $self->execute_command(commands => $self->get_rpc_commands(commands => [ 'ospf' ]));
    }

    my $results = [];
    my $result = $self->load_xml(data => $content, start_tag => '<ospf-neighbor-informatio.*?>', end_tag => '</ospf-neighbor-information>', force_array => [ 'ospf-neighbor' ]);

    foreach (@{$result->{'ospf-neighbor'}}) {
        push @$results, {
            neighborId      => $_->{'neighbor-id'},
            neighborAddress => $_->{'neighbor-address'},
            interfaceName   => $_->{'interface-name'},
            state           => $_->{'ospf-neighbor-state'}
        };
    }

    return $results;
}

sub get_bgp_infos {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{cache_use})) {
        return $self->get_cache_file_response_command(command => 'bgp');
    }

    my $content = $options{content};
    if (!defined($content)) {
        $content = $self->execute_command(commands => $self->get_rpc_commands(commands => [ 'bgp' ]));
    }

    my $results = [];
    my $result = $self->load_xml(data => $content, start_tag => '<bgp-information.*?>', end_tag => '</bgp-information>', force_array => [ 'bgp-peer', 'bgp-rib' ]);

    foreach my $item (@{$result->{'bgp-peer'}}) {
        my $ribs = [];
        foreach (@{$item->{'bgp-rib'}}) {
            push @$ribs, {
                ribName      => $_->{name},
                sendState    => $_->{'send-state'},
                activePrefix => $_->{'active-prefix-count'}
            };
        }

        $item->{'local-address'} =~ s/\+/:/g;
        $item->{'peer-address'} =~ s/\+/:/g;

        push @$results, {
            snmpIndex => $item->{'snmp-index'},
            localAddr => $item->{'local-address'},
            localAs   => $item->{'local-as'},
            peerAddr  => $item->{'peer-address'},
            peerAs    => $item->{'peer-as'},
            peerState => $item->{'peer-state'},
            inBytes   => $item->{'input-octets'},
            outBytes  => $item->{'output-octets'},
            ribs      => $ribs
        };
    }

    return $results;
}

sub get_ldp_infos {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{cache_use})) {
        return $self->get_cache_file_response_command(command => 'ldp');
    }

    my $content = $options{content};
    if (!defined($content)) {
        $content = $self->execute_command(commands => $self->get_rpc_commands(commands => [ 'ldp' ]));
    }

    my $results = [];
    my $result = $self->load_xml(data => $content, start_tag => '<ldp-session-information.*?>', end_tag => '</ldp-session-information>', force_array => [ 'ldp-session', 'ldp-session-statistics' ]);

    foreach my $item (@{$result->{'ldp-session'}}) {
        my $stats = [];
        foreach (@{$item->{'ldp-session-statistics'}}) {
            push @$stats, {
                messageType => lc($_->{'ldp-message-type'}),
                sent        => $_->{'ldp-messages-sent'},
                received    => $_->{'ldp-messages-received'}
            };
        }

        push @$results, {
            id              => $item->{'ldp-session-id'},
            remoteAddress   => $item->{'ldp-remote-address'},
            sessionState    => $item->{'ldp-session-state'},
            connectionState => $item->{'ldp-connection-state'},
            stats           => $stats
        };
    }

    return $results;
}

sub get_lsp_infos {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{cache_use})) {
        return $self->get_cache_file_response_command(command => 'lsp');
    }

    my $content = $options{content};
    if (!defined($content)) {
        $content = $self->execute_command(commands => $self->get_rpc_commands(commands => [ 'lsp' ]));
    }

    my $results = [];
    my $result = $self->load_xml(data => $content, start_tag => '<mpls-lsp-information.*?>', end_tag => '</mpls-lsp-information>', force_array => [ 'rsvp-session-data', 'rsvp-session' ]);

    foreach my $item (@{$result->{'rsvp-session-data'}}) {
        foreach (@{$item->{'rsvp-session'}}) {
            my $lsp = $_;
            if (defined($_->{'mpls-lsp'})) {
                $lsp = $_->{'mpls-lsp'};
            }

            push @$results, {
                type       => $item->{'session-type'},
                name       => $lsp->{name},
                srcAddress => $lsp->{'source-address'},
                dstAddress => $lsp->{'destination-address'},
                lspState   => $lsp->{'lsp-state'},
                lspBytes   => $lsp->{'lsp-bytes'}
            };
        }
    }

    return $results;
}

sub get_rsvp_infos {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{cache_use})) {
        return $self->get_cache_file_response_command(command => 'rsvp');
    }

    my $content = $options{content};
    if (!defined($content)) {
        $content = $self->execute_command(commands => $self->get_rpc_commands(commands => [ 'rsvp' ]));
    }

    my $result = $self->load_xml(data => $content, start_tag => '<rsvp-session-information.*?>', end_tag => '</rsvp-session-information>', force_array => [ 'rsvp-session-data', 'rsvp-session' ]);

    my $results = [];
    foreach my $item (@{$result->{'rsvp-session-data'}}) {
        foreach (@{$item->{'rsvp-session'}}) {
            my $bytes = 0;
            if ($_->{'lsp-bytes'} =~ /([0-9]+)/) {
                $bytes = $1;
            }

            push @$results, {
                type       => $item->{'session-type'},
                name       => $_->{name},
                srcAddress => $_->{'source-address'},
                dstAddress => $_->{'destination-address'},
                lspState   => $_->{'lsp-state'},
                lspBytes   => $bytes
            };
        }
    }

    return $results;
}

sub get_service_rpm_infos {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{cache_use})) {
        return $self->get_cache_file_response_command(command => 'service_rpm');
    }

    my $content = $options{content};
    if (!defined($content)) {
        $content = $self->execute_command(commands => $self->get_rpc_commands(commands => [ 'service_rpm' ]));
    }

    my $results = [];
    my $result = $self->load_xml(data => $content, start_tag => '<probe-results.*?>', end_tag => '</probe-results>', force_array => [ 'probe-test-results' ]);

    foreach (@{$result->{'probe-test-results'}}) {
        push @$results, {
            testName            =>
            $_->{'test-name'},
            targetAddress       =>
            $_->{'target-address'},
            sourceAddress       =>
            $_->{'source-address'},
            probeType           =>
            $_->{'probe-type'},
            probeStatus         =>
            $_->{'probe-single-results'}->{'probe-status'},
            lastLossPercentage  =>
            $_->{'probe-last-test-results'}->{'probe-test-generic-results'}->{'loss-percentage'},
            lastRTTAvgDelay     =>
            centreon::plugins::misc::trim($_->{'probe-last-test-results'}->{'probe-test-generic-results'}->{'probe-test-rtt'}->{'probe-summary-results'}->{'avg-delay'}->{content}),
            lastRTTJitterDelay  =>
            centreon::plugins::misc::trim($_->{'probe-last-test-results'}->{'probe-test-generic-results'}->{'probe-test-rtt'}->{'probe-summary-results'}->{'jitter-delay'}->{content}),
            lastRTTStdevDelay   =>
            centreon::plugins::misc::trim($_->{'probe-last-test-results'}->{'probe-test-generic-results'}->{'probe-test-rtt'}->{'probe-summary-results'}->{'stddev-delay'}->{content}),
            lastPRTJAvgDelay    =>
            centreon::plugins::misc::trim($_
                ->{'probe-last-test-results'}
                ->{'probe-test-generic-results'}
                ->{'probe-test-positive-round-trip-jitter'}
                ->{'probe-summary-results'}
                ->{'avg-delay'}
                ->{content}),
            lastPRTJJitterDelay =>
            centreon::plugins::misc::trim($_
                ->{'probe-last-test-results'}
                ->{'probe-test-generic-results'}
                ->{'probe-test-positive-round-trip-jitter'}
                ->{'probe-summary-results'}
                ->{'jitter-delay'}
                ->{content}),
            lastPRTJStdevDelay  =>
            centreon::plugins::misc::trim($_
                ->{'probe-last-test-results'}
                ->{'probe-test-generic-results'}
                ->{'probe-test-positive-round-trip-jitter'}
                ->{'probe-summary-results'}
                ->{'stddev-delay'}
                ->{content}),
            lastNRTJAvgDelay    =>
            centreon::plugins::misc::trim($_
                ->{'probe-last-test-results'}
                ->{'probe-test-generic-results'}
                ->{'probe-test-negative-round-trip-jitter'}
                ->{'probe-summary-results'}
                ->{'avg-delay'}
                ->{content}),
            lastNRTJJitterDelay =>
            centreon::plugins::misc::trim($_
                ->{'probe-last-test-results'}
                ->{'probe-test-generic-results'}
                ->{'probe-test-negative-round-trip-jitter'}
                ->{'probe-summary-results'}
                ->{'jitter-delay'}
                ->{content}),
            lastNRTJStdevDelay  =>
            centreon::plugins::misc::trim($_
                ->{'probe-last-test-results'}
                ->{'probe-test-generic-results'}
                ->{'probe-test-negative-round-trip-jitter'}
                ->{'probe-summary-results'}
                ->{'stddev-delay'}
                ->{content}),
        };
    }

    return $results;
}

1;

__END__

=head1 NAME

ssh

=head1 SYNOPSIS

my ssh

=head1 SSH OPTIONS

=over 8

=item B<--hostname>

Hostname to query.

=item B<--timeout>

Timeout in seconds for the command (default: 45).

=item B<--command>

Command to get information. Used it you have output in a file.

=item B<--command-path>

Command path.

=item B<--command-options>

Command options.

=item B<--cache-use>

Use the cache file (created with cache mode).

=back

=head1 DESCRIPTION

B<custom>.

=cut
