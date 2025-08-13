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

package apps::microsoft::hyperv::2012::local::mode::scvmmdiscovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::hyperv::2012::scvmmdiscovery;
use apps::microsoft::hyperv::2012::local::mode::resources::types qw($scvmm_vm_status);
use JSON::XS;

sub prefix_vm_output {
    my ($self, %options) = @_;

    return "VM '" . $options{instance_value}->{vm} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'prettify'          => { name => 'prettify' },
        'resource-type:s'   => { name => 'resource_type', type => 'vm' },
        'scvmm-hostname:s'  => { name => 'scvmm_hostname' },
        'scvmm-username:s'  => { name => 'scvmm_username' },
        'scvmm-password:s'  => { name => 'scvmm_password' },
        'scvmm-port:s'      => { name => 'scvmm_port', default => 8100 },
        'timeout:s'         => { name => 'timeout', default => 90 },
        'command:s'         => { name => 'command' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options' },
        'no-ps'             => { name => 'no_ps' },
        'ps-exec-only'      => { name => 'ps_exec_only' },
        'ps-display'        => { name => 'ps_display' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options); 

    if (!defined($self->{option_results}->{resource_type}) || $self->{option_results}->{resource_type} eq '') {
        $self->{option_results}->{resource_type} = 'vm';
    }
    if ($self->{option_results}->{resource_type} !~ /^vm|host$/) {
        $self->{output}->add_option_msg(short_msg => 'unknown resource type');
        $self->{output}->option_exit();
    }

    foreach my $label (('scvmm_username', 'scvmm_password', 'scvmm_port')) {
        if (!defined($self->{option_results}->{$label}) || $self->{option_results}->{$label} eq '') {
            my ($label_opt) = $label;
            $label_opt =~ tr/_/-/;
            $self->{output}->add_option_msg(short_msg => "Need to specify --" . $label_opt . " option.");
            $self->{output}->option_exit();
        }
    }

    centreon::plugins::misc::check_security_command(
        output => $self->{output},
        command => $self->{option_results}->{command},
        command_options => $self->{option_results}->{command_options},
        command_path => $self->{option_results}->{command_path}
    );

    $self->{option_results}->{command} = 'powershell.exe'
        if (!defined($self->{option_results}->{command}) || $self->{option_results}->{command} eq '');
    $self->{option_results}->{command_options} = '-InputFormat none -NoLogo -EncodedCommand'
        if (!defined($self->{option_results}->{command_options}) || $self->{option_results}->{command_options} eq '');
}

sub powershell_exec {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::hyperv::2012::scvmmdiscovery::get_powershell(
            scvmm_hostname => $self->{option_results}->{scvmm_hostname},
            scvmm_username => $self->{option_results}->{scvmm_username},
            scvmm_password => $self->{option_results}->{scvmm_password},
            scvmm_port => $self->{option_results}->{scvmm_port}
        );
        if (defined($self->{option_results}->{ps_display})) {
            $self->{output}->output_add(
                severity => 'OK',
                short_msg => $ps
            );
            $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
            $self->{output}->exit();
        }

        $self->{option_results}->{command_options} .= " " . centreon::plugins::misc::powershell_encoded($ps);
    }

    my ($stdout) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options}
    );
    if (defined($self->{option_results}->{ps_exec_only})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $stdout
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($self->{output}->decode($stdout));
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub run {
    my ($self, %options) = @_;

    my $disco_data;
    my $disco_stats;
    $disco_stats->{start_time} = time();
    
    my $decoded = $self->powershell_exec();

    my $hosts = {};
    foreach my $entry (@$decoded) {
        next if ($entry->{type} ne 'host');
        $hosts->{ $entry->{id} } = { cluster_name => $entry->{clusterName}, name => $entry->{name} };
    }

    foreach my $entry (@$decoded) {
        my $item = {};

        $item->{type} = $entry->{type};
        if ($self->{option_results}->{resource_type} eq 'vm' && $entry->{type} eq 'vm') {
            $item->{id} = $entry->{vmId};
            $item->{name} = $entry->{name};
            $item->{description} = $entry->{description};
            $item->{operating_system} = $entry->{operatingSystem};
            $item->{status} = $scvmm_vm_status->{ $entry->{status} };
            $item->{hostgroup_path} = $entry->{hostGroupPath};
            $item->{enabled} = ($entry->{enabled} =~ /True|1/i) ? 'yes' : 'no';
            $item->{computer_name} = $entry->{computerName};
            $item->{tag} = $entry->{tag};
            $entry->{ipv4Addresses} = [$entry->{ipv4Addresses}] if (ref($entry->{ipv4Addresses}) ne 'ARRAY');
            $item->{ipv4_addresses} = $entry->{ipv4Addresses};
            $item->{ipv4_address} = defined($entry->{ipv4Addresses}->[0]) ? $entry->{ipv4Addresses}->[0] : '';
            $item->{vmhost_name} = $hosts->{ $entry->{vmHostId} }->{name};
            $item->{cluster_name} = $hosts->{ $entry->{vmHostId} }->{cluster_name};
            push @$disco_data, $item;
        } elsif ($self->{option_results}->{resource_type} eq 'host' && $entry->{type} eq 'host') {
            $item->{id} = $entry->{id};
            $item->{name} = $entry->{name};
            $item->{description} = $entry->{description};
            $item->{fqdn} = $entry->{FQDN};
            $item->{cluster_name} = $entry->{clusterName};
            $item->{operating_system} = $entry->{operatingSystem};
            push @$disco_data, $item;
        }
    }

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = scalar(@$disco_data);
    $disco_stats->{results} = $disco_data;

    my $encoded_data;
    eval {
        if (defined($self->{option_results}->{prettify})) {
            $encoded_data = JSON::XS->new->utf8->pretty->encode($disco_stats);
        } else {
            $encoded_data = JSON::XS->new->utf8->encode($disco_stats);
        }
    };
    if ($@) {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}';
    }

    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

SCVMM resources discovery.

=over 8

=item B<--prettify>

Prettify the JSON output.

=item B<--resource-type>

Choose the type of resources to discover (can be: C<host>, C<vm>) (required).

=item B<--scvmm-hostname>

Set the SCVMM hostname.

=item B<--scvmm-username>

Set the SCVMM username (required).

=item B<--scvmm-password>

Set the SCVMM password (required).

=item B<--scvmm-port>

Set the SCVMM port (default: 8100).

=item B<--timeout>

Set timeout time for command execution (default: 90 sec).

=item B<--no-ps>

Don't encode powershell. To be used with C<--command> and 'type' command.

=item B<--command>

Set the command to get information (default: 'powershell.exe').
It can be used if you have the information in a file. 
This option should be used with C<--no-ps> option!!!

=item B<--command-path>

Set the command path (default: none).

=item B<--command-options>

Set the command options (default: C<-InputFormat none -NoLogo -EncodedCommand>).

=item B<--ps-display>

Display the powershell script.

=item B<--ps-exec-only>

Print the powershell output.

=back

=cut
