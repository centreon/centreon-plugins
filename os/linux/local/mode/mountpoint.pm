#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package os::linux::local::mode::mountpoint;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return "options are '" . $self->{result_values}->{options} . "' [type: " . $self->{result_values}->{type} . "]";
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_type'};
    $self->{result_values}->{options} = $options{new_datas}->{$self->{instance} . '_options'};

    return 0;
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Mount point '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'mountpoints', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All mount points options are ok' }
    ];
    
    $self->{maps_counters}->{mountpoints} = [
        { label => 'status', set => {
                key_values => [ { name => 'display' }, { name => 'options' }, { name => 'type' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                {
                                    "hostname:s"            => { name => 'hostname' },
                                    "remote"                => { name => 'remote' },
                                    "ssh-option:s@"         => { name => 'ssh_option' },
                                    "ssh-path:s"            => { name => 'ssh_path' },
                                    "ssh-command:s"         => { name => 'ssh_command', default => 'ssh' },
                                    "timeout:s"             => { name => 'timeout', default => 30 },
                                    "sudo"                  => { name => 'sudo' },
                                    "command:s"             => { name => 'command', default => 'mount' },
                                    "command-path:s"        => { name => 'command_path' },
                                    "command-options:s"     => { name => 'command_options', default => ' 2>&1' },
                                    "filter-device:s"       => { name => 'filter_device' },
                                    "filter-mountpoint:s"   => { name => 'filter_mountpoint' },
                                    "filter-type:s"         => { name => 'filter_type' },
                                    "warning-status:s"      => { name => 'warning_status', default => '' },
                                    "critical-status:s"     => { name => 'critical_status', default => '%{options} !~ /^rw/i && %{type} !~ /tmpfs/i' },
                                });
    $self->{result} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout, $exit_code) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options},
        no_quit => 1
    );

    $self->{mountpoints} = {};
    
    my @lines = split /\n/, $stdout;
    foreach my $line (@lines) {
        next if ($line !~ /^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+\((.*)\)/);
        my ($device, $mountpoint, $type, $options) = ($1, $3, $5, $6);
        
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $type !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $mountpoint . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_device}) && $self->{option_results}->{filter_device} ne '' &&
            $device !~ /$self->{option_results}->{filter_device}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $mountpoint . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_mountpoint}) && $self->{option_results}->{filter_mountpoint} ne '' &&
            $mountpoint !~ /$self->{option_results}->{filter_mountpoint}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $mountpoint . "': no matching filter.", debug => 1);
            next;
        }

        $self->{mountpoints}->{$mountpoint} = {
            display => $mountpoint,
            type => $type,
            options => $options,
        };
    }
    
    if (scalar(keys %{$self->{mountpoints}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No mount points found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check mount points options.

=over 8

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'mount').

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: ' 2>&1').

=item B<--filter-mountpoint>

Filter mount point name (Can use regexp).

=item B<--filter-device>

Filter device name (Can use regexp).

=item B<--filter-type>

Filter mount point type (Can use regexp).

=item B<--warning-status>

Threshold warning.

=item B<--critical-status>

Threshold critical
(Default: '%{options} !~ /^rw/i && %{type} !~ /tmpfs/i').

=back

=cut
