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

package apps::centreon::local::mode::brokerstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::ssh;
use JSON;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg;
    
    if ($self->{result_values}->{type} eq 'input') {
        $msg = sprintf("state : %s", $self->{result_values}->{state});
    } else {
        $msg = sprintf(
            "state : %s [status : %s] [queue file enabled : %s]", 
            $self->{result_values}->{state},  $self->{result_values}->{status}, $self->{result_values}->{queue_file_enabled}
        );
    }
    return $msg;
}

sub prefix_endpoint_output {
    my ($self, %options) = @_;

    return "Endpoint $options{instance_value}->{type} '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'endpoint', type => 1, cb_prefix_output => 'prefix_endpoint_output', message_multiple => 'Broker statistics are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{endpoint} = [
        { label => 'status', type => 2, critical_default => '%{type} eq "output" and %{queue_file_enabled} =~ /yes/i', set => {
                key_values => [ { name => 'queue_file_enabled' }, { name => 'state' }, { name => 'status' }, { name => 'type' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'speed-events', set => {
                key_values => [ { name => 'speed_events' }, { name => 'display' } ],
                output_template => 'Speed Events: %s/s',
                perfdatas => [
                    { label => 'speed_events', value => 'speed_events', template => '%s', 
                      unit => 'events/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'queued-events', set => {
                key_values => [ { name => 'queued_events' }, { name => 'display' } ],
                output_template => 'Queued Events: %s',
                perfdatas => [
                    { label => 'queued_events', value => 'queued_events', template => '%s', 
                      unit => 'events', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'unacknowledged-events', set => {
                key_values => [ { name => 'unacknowledged_events' }, { name => 'display' } ],
                output_template => 'Unacknowledged Events: %s',
                perfdatas => [
                    { label => 'unacknowledged_events', value => 'unacknowledged_events', template => '%s', 
                      unit => 'events', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'broker-stats-file:s@' => { name => 'broker_stats_file' },
        'hostname:s'           => { name => 'hostname' },
        'timeout:s'            => { name => 'timeout', default => 30 },
        'sudo'                 => { name => 'sudo' },
        'filter-name:s'        => { name => 'filter_name' }
    });

    $self->{ssh} = centreon::plugins::ssh->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{broker_stats_file}) || scalar(@{$self->{option_results}->{broker_stats_file}}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Please set broker-stats-file option.");
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        $self->{ssh}->check_options(option_results => $self->{option_results});
    }
}

sub execute_command {
    my ($self, %options) = @_;

    my ($stdout, $exit_code);
    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        ($stdout, $exit_code) = $self->{ssh}->execute(
            hostname => $self->{option_results}->{hostname},
            sudo => $self->{option_results}->{sudo},
            command => $options{command},
            command_options => $options{command_options},
            timeout => $self->{option_results}->{timeout}
        );
    } else {
        ($stdout, $exit_code) = centreon::plugins::misc::execute(
            output => $self->{output},
            sudo => $self->{option_results}->{sudo},
            options => { timeout => $self->{option_results}->{timeout} },
            command => $options{command},
            command_options => $options{command_options}
        );
    }

    return ($stdout, $exit_code);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{endpoint} = {};
    foreach my $config (@{$self->{option_results}->{broker_stats_file}}) {
        my ($stdout) = $self->execute_command(
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

            my $queue_enabled = '-';
            if (defined($json->{$entry}->{queue_file_enabled})) {
                $queue_enabled = $json->{$entry}->{queue_file_enabled} ? 'yes' : 'no';
            }
            $self->{endpoint}->{$endpoint} = {
                display => $endpoint,
                state => $state,
                type => $type,
                status => defined($json->{$entry}->{status}) ? $json->{$entry}->{status} : '-',
                speed_events => $json->{$entry}->{event_processing_speed},
                queued_events => $json->{$entry}->{queued_events},
                unacknowledged_events => $json->{$entry}->{bbdo_unacknowledged_events},
                queue_file_enabled => $queue_enabled
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

=item B<--hostname>

Hostname to query in ssh.

=item B<--timeout>

Timeout in seconds for the command (default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--broker-stats-file>

Specify the centreon-broker json stats file (required). Can be multiple.

=item B<--filter-name>

Filter endpoint name.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'speed-events', 'queued-events', 'unacknowledged-events'.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{queue_file_enabled}, %{state}, %{status}, %{type}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{type} eq "output" and %{queue_file_enabled} =~ /yes/i').
You can use the following variables: %{queue_file_enabled}, %{state}, %{status}, %{type}, %{display}

=back

=cut
