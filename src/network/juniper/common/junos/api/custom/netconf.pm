#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::juniper::common::junos::api::custom::netconf;

use strict;
use warnings;
use centreon::plugins::ssh;
use centreon::plugins::misc;
use XML::LibXML::Simple;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
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
        $options{options}->add_options(arguments =>  {                      
            'hostname:s'        => { name => 'hostname' },
            'timeout:s'         => { name => 'timeout', default => 45 },
            'command:s'         => { name => 'command' },
            'command-path:s'    => { name => 'command_path' },
            'command-options:s' => { name => 'command_options' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'SSH OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{ssh} = centreon::plugins::ssh->new(%options);

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
            option_results => $self->{option_results},
            default_ssh_port => 830
        );

        if ($self->{ssh}->get_ssh_backend() !~ /^sshcli$/) {
            $self->{output}->add_option_msg(short_msg => 'unsupported ssh backend (sshcli only)');
            $self->{output}->option_exit();
        }
    }

    centreon::plugins::misc::check_security_command(
        output => $self->{output},
        command => $self->{option_results}->{command},
        command_options => $self->{option_results}->{command_options},
        command_path => $self->{option_results}->{command_path}
    );

    return 0;
}

sub load_xml {
    my ($self, %options) = @_;

    if ($options{data} !~ /($options{start_tag}.*?$options{end_tag})/ms) {
        $self->{output}->add_option_msg(short_msg => "Cannot find information");
        $self->{output}->option_exit();
    }

    my $content = $1;
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
            ssh_pipe => 1,
            hostname => $self->{option_results}->{hostname},
            command => $self->{ssh_commands},
            timeout => $self->{option_results}->{timeout},
            default_sshcli_option_eol => ['-s=netconf']
        );
    } else {
        if (!defined($self->{option_results}->{command}) || $self->{option_results}->{command} eq '') {
            $self->{output}->add_option_msg(short_msg => 'please set --hostname option for ssh connection (or --command for local)');
            $self->{output}->option_exit();
        }
        ($content) = centreon::plugins::misc::execute(
            ssh_pipe => 1,
            output => $self->{output},
            options => { timeout => $self->{option_results}->{timeout} },
            command => $self->{option_results}->{command},
            command_path => $self->{option_results}->{command_path},
            command_options => defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '' ? $self->{option_results}->{command_options} : undef
        );
    }
    
    return $content;
}

sub get_cpu_infos {
    my ($self, %options) = @_;

    my $content = $self->execute_command(commands => [
        '<rpc>
        <get-fpc-information>
        </get-fpc-information>
    </rpc>',
        '<rpc>
        <get-route-engine-information>
        </get-route-engine-information>
    </rpc>']);

    my $results = [];
    my $result = $self->load_xml(data => $content, start_tag => '<route-engine-information.*?>', end_tag => '</route-engine-information>', force_array => ['route-engine']);

    foreach (@{$result->{'route-engine'}}) {
        push @$results, {
            name => 'route engine slot ' . $_->{slot},
            cpu_1min_avg => 100 - $_->{'cpu-idle1'},
            cpu_5min_avg => 100 - $_->{'cpu-idle2'},
            cpu_15min_avg => 100 - $_->{'cpu-idle3'}
        };
    }

    $result = $self->load_xml(data => $content, start_tag => '<fpc-information.*?>', end_tag => '</fpc-information>', force_array => ['fpc']);

    foreach (@{$result->{fpc}}) {
        next if (!defined($_->{'cpu-1min-avg'}));

        push @$results, {
            name => 'fpc slot ' . $_->{slot},
            cpu_1min_avg => $_->{'cpu-1min-avg'},
            cpu_5min_avg => $_->{'cpu-5min-avg'},
            cpu_15min_avg => $_->{'cpu-15min-avg'}
        };
    }

    return $results;
}

sub get_disk_infos {
    my ($self, %options) = @_;

    my $content = $self->execute_command(commands => [
        '<rpc>
        <get-system-storage>
                <detail/>
        </get-system-storage>
    </rpc>']);

    my $results = [];
    my $result = $self->load_xml(data => $content, start_tag => '<system-storage-information.*?>', end_tag => '</system-storage-information>', force_array => ['filesystem']);

    foreach (@{$result->{filesystem}}) {
        push @$results, {
            mount => centreon::plugins::misc::trim($_->{'mounted-on'}),
            space_used => $_->{'used-blocks'}->{format} * 1024,
            space_total => $_->{'total-blocks'}->{format} * 1024,
            space_free => $_->{'available-blocks'}->{format} * 1024,
            space_used_prct => centreon::plugins::misc::trim($_->{'used-percent'}),
            space_free_prct => 100 - centreon::plugins::misc::trim($_->{'used-percent'})
        };
    }

    return $results;
}

sub get_hardware_infos {
    my ($self, %options) = @_;

    my $content = $self->execute_command(commands => [
        '<rpc>
        <get-environment-information>
        </get-environment-information>
    </rpc>',
        '<rpc>
        <get-power-usage-information>
        </get-power-usage-information>
    </rpc>',
        '<rpc>
        <get-fan-information>
        </get-fan-information>
    </rpc>',
        '<rpc>
        <get-fpc-information>
        </get-fpc-information>
    </rpc>']);

    my $results = { 'fan' => [], 'psu' => [], 'env' => [], 'fpc' => [] };
    my $result = $self->load_xml(data => $content, start_tag => '<fan-information.*?>', end_tag => '</fan-information>', force_array => ['fan-information-rpm-item']);

    foreach (@{$result->{'fan-information-rpm-item'}}) {
        push @{$results->{fan}}, {
            name => $_->{name},
            status => $_->{status},
            rpm => $_->{rpm}
        };
    }

    $result = $self->load_xml(data => $content, start_tag => '<power-usage-information.*?>', end_tag => '</power-usage-information>', force_array => ['power-usage-item']);

    foreach (@{$result->{'power-usage-item'}}) {
        push @{$results->{psu}}, {
            name => $_->{name},
            status => $_->{state},
            dc_output_load => $_->{'dc-output-detail'}->{'dc-load'}
        };
    }

    $result = $self->load_xml(data => $content, start_tag => '<environment-information.*?>', end_tag => '</environment-information>', force_array => ['environment-item']);

    foreach (@{$result->{'environment-item'}}) {
        my $temperature = '';
        if ($_->{class} eq 'Temp') {
            $temperature = $_->{temperature}->{celsius};
        }
        push @{$results->{env}}, {
            name => $_->{name},
            status => $_->{status},
            class => $_->{class},
            temperature => $temperature
        };
    }

    $result = $self->load_xml(data => $content, start_tag => '<fpc-information.*?>', end_tag => '</fpc-information>', force_array => ['fpc']);

    foreach (@{$result->{fpc}}) {
        push @{$results->{fpc}}, {
            name => 'fpc slot ' . $_->{slot},
            status => $_->{state}
        };
    }

    return $results;
}

sub get_interface_infos {
    my ($self, %options) = @_;

    my $content = $self->execute_command(commands => [
        '<rpc>
        <get-interface-information>
                <detail/>
        </get-interface-information>
    </rpc>']);

    my $results = [];
    my $result = $self->load_xml(data => $content, start_tag => '<interface-information.*?>', end_tag => '</interface-information>', force_array => ['physical-interface', 'logical-interface']);

    foreach (@{$result->{'physical-interface'}}) {
        my $speed = centreon::plugins::misc::trim($_->{'speed'});
        my ($speed_unit, $speed_value);
        if ($speed =~ /^\s*([0-9]+)\s*([A-Za-z])/) {
            ($speed_value, $speed_unit) = ($1, $2);
        }
        $speed = centreon::plugins::misc::scale_bytesbit(
            value => $speed_value,
            src_quantity => $speed_unit,
            dst_quantity => '',
            src_unit => 'b',
            dst_unit => 'b'
        );

        my $descr = centreon::plugins::misc::trim($_->{'description'});
        my $name = centreon::plugins::misc::trim($_->{'name'});

        push @$results, {
            descr => defined($descr) && $descr ne '' ? $descr : $name,
            name => $name,
            opstatus => centreon::plugins::misc::trim($_->{'oper-status'}),
            admstatus => centreon::plugins::misc::trim($_->{'admin-status'}->{content}),
            in => centreon::plugins::misc::trim($_->{'traffic-statistics'}->{'input-bytes'}) * 8,
            out => centreon::plugins::misc::trim($_->{'traffic-statistics'}->{'output-bytes'}) * 8,
            speed => $speed
        };

        foreach my $logint (@{$_->{'logical-interface'}}) {
            push @$results, {
                descr => centreon::plugins::misc::trim($logint->{'name'}),
                name => centreon::plugins::misc::trim($logint->{'name'}),
                opstatus => centreon::plugins::misc::trim($_->{'oper-status'}),
                admstatus => centreon::plugins::misc::trim($_->{'admin-status'}->{content}),
                in => centreon::plugins::misc::trim($logint->{'traffic-statistics'}->{'input-bytes'}) * 8,
                out => centreon::plugins::misc::trim($logint->{'traffic-statistics'}->{'output-bytes'}) * 8,
                speed => $speed
            };
        }
    }

    return $results;
}

sub get_memory_infos {
    my ($self, %options) = @_;

    my $content = $self->execute_command(commands => [
        '<rpc>
        <get-fpc-information>
        </get-fpc-information>
    </rpc>',
        '<rpc>
        <get-route-engine-information>
        </get-route-engine-information>
    </rpc>']);

    my $results = [];
    my $result = $self->load_xml(data => $content, start_tag => '<route-engine-information.*?>', end_tag => '</route-engine-information>', force_array => ['route-engine']);

    foreach (@{$result->{'route-engine'}}) {
        push @$results, {
            name => 'route engine slot ' . $_->{slot},
            mem_used => $_->{'memory-buffer-utilization'}
        };
    }

    $result = $self->load_xml(data => $content, start_tag => '<fpc-information.*?>', end_tag => '</fpc-information>', force_array => ['fpc']);

    foreach (@{$result->{fpc}}) {
        next if (!defined($_->{'memory-heap-utilization'}));

        push @$results, {
            name => 'fpc slot ' . $_->{slot} . ' heap',
            mem_used => $_->{'memory-heap-utilization'}
        }, {
           name => 'fpc slot ' . $_->{slot} . ' buffer',
           mem_used => $_->{'memory-buffer-utilization'}
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

=back

=head1 DESCRIPTION

B<custom>.

=cut
