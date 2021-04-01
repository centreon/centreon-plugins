#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package apps::centreon::local::mode::brokerstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use JSON;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg;
    
    if ($self->{result_values}->{type} eq 'input') {
        $msg = sprintf("state : %s", $self->{result_values}->{state});
    } else {
        $msg = sprintf("state : %s [status : %s] [queue file enabled : %s]", 
            $self->{result_values}->{state},  $self->{result_values}->{status}, $self->{result_values}->{queue_file_enabled});
    }
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{queue_file_enabled} = $options{new_datas}->{$self->{instance} . '_queue_file_enabled'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_type'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'endpoint', type => 1, cb_prefix_output => 'prefix_endpoint_output', message_multiple => 'Broker statistics are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{endpoint} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'queue_file_enabled' }, { name => 'state' }, { name => 'status' }, { name => 'type' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'speed-events', set => {
                key_values => [ { name => 'speed_events' }, { name => 'display' } ],
                output_template => 'Speed Events: %s/s',
                perfdatas => [
                    { label => 'speed_events', value => 'speed_events', template => '%s', 
                      unit => 'events/s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'queued-events', set => {
                key_values => [ { name => 'queued_events' }, { name => 'display' } ],
                output_template => 'Queued Events: %s',
                perfdatas => [
                    { label => 'queued_events', value => 'queued_events', template => '%s', 
                      unit => 'events', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'unacknowledged-events', set => {
                key_values => [ { name => 'unacknowledged_events' }, { name => 'display' } ],
                output_template => 'Unacknowledged Events: %s',
                perfdatas => [
                    { label => 'unacknowledged_events', value => 'unacknowledged_events', template => '%s', 
                      unit => 'events', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'broker-stats-file:s@' => { name => 'broker_stats_file' },
        'hostname:s'           => { name => 'hostname' },
        'remote'               => { name => 'remote' },
        'ssh-option:s@'        => { name => 'ssh_option' },
        'ssh-path:s'           => { name => 'ssh_path' },
        'ssh-command:s'        => { name => 'ssh_command', default => 'ssh' },
        'timeout:s'            => { name => 'timeout', default => 30 },
        'sudo'                 => { name => 'sudo' },
        'filter-name:s'        => { name => 'filter_name' },
        'warning-status:s'     => { name => 'warning_status', default => '' },
        'critical-status:s'    => { name => 'critical_status', default => '%{type} eq "output" and %{queue_file_enabled} =~ /yes/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{broker_stats_file}) || scalar(@{$self->{option_results}->{broker_stats_file}}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Please set broker-stats-file option.");
        $self->{output}->option_exit();
    }
    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_endpoint_output {
    my ($self, %options) = @_;

    return "Endpoint $options{instance_value}->{type} '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{endpoint} = {};
    foreach my $config (@{$self->{option_results}->{broker_stats_file}}) {
        my ($stdout) = centreon::plugins::misc::execute(
            output => $self->{output},
            options => $self->{option_results},
            sudo => $self->{option_results}->{sudo},
            command => 'cat',
            command_options => $config
        );
        my $json;
        eval {
            $json = decode_json($stdout);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
            $self->{output}->option_exit();
        }

        foreach my $entry (keys %$json) {
            next if ($entry !~ /^endpoint/);

            my $endpoint = $entry;
            $endpoint =~ s/endpoint //;

            if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                $endpoint !~ /$self->{option_results}->{filter_name}/i) {
                $self->{output}->output_add(long_msg => "skipping endpoint '" . $endpoint . "': no matching filter name");
                next;
            }

            my $state = $json->{$entry}->{state};
            my $type = 'output';
            $type = 'input' if (!defined($json->{$entry}->{status}));

            $self->{endpoint}->{$endpoint} = {
                display => $endpoint,
                state => $state,
                type => $type,
                status => defined($json->{$entry}->{status}) ? $json->{$entry}->{status} : '-',
                speed_events => $json->{$entry}->{event_processing_speed},
                queued_events => $json->{$entry}->{queued_events},
                unacknowledged_events => $json->{$entry}->{bbdo_unacknowledged_events},
                queue_file_enabled => defined($json->{$entry}->{queue_file_enabled}) ? $json->{$entry}->{queue_file_enabled} : '-',
            };
        }
    }

    if (scalar(keys %{$self->{endpoint}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No endpoint found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Centreon Broker statistics files.

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

=item B<--broker-stats-file>

Specify the centreon-broker json stats file (Required). Can be multiple.

=item B<--filter-name>

Filter endpoint name.

=item B<--warning-*>

Threshold warning.
Can be: 'speed-events', 'queued-events', 'unacknowledged-events'.

=item B<--critical-*>

Threshold critical.
Can be: 'speed-events', 'queued-events', 'unacknowledged-events'.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{queue_file_enabled}, %{state}, %{status}, %{type}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{type} eq "output" and %{queue_file_enabled} =~ /yes/i').
Can used special variables like: %{queue_file_enabled}, %{state}, %{status}, %{type}, %{display}

=back

=cut
