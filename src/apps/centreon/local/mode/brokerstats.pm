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
    my $msg = sprintf(
        "state : %s [status : %s] [queue file enabled : %s]", 
        $self->{result_values}->{state},
        $self->{result_values}->{status},
        $self->{result_values}->{queue_file_enabled}
    );
    return $msg;
}

sub prefix_input_output {
    my ($self, %options) = @_;

    return "Input '" . $options{instance_value}->{display} . "' ";
}

sub prefix_output_output {
    my ($self, %options) = @_;

    return "Output '" . $options{instance_value}->{display} . "' ";
}

sub prefix_consumer_output {
    my ($self, %options) = @_;

    return "Consumer '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        {
            name => 'inputs', type => 3, cb_prefix_output => 'prefix_input_output', cb_long_output => 'prefix_input_output', indent_long_output => '    ', message_multiple => 'Input endpoints statistics are ok',
            group => [
                { name => 'inputs_status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'consumers', type => 1, display_long => 1, cb_prefix_output => 'prefix_consumer_output', message_multiple => 'Consumers statistics are ok', skipped_code => { -10 => 1 } }
            ]
        },
        { name => 'outputs', type => 1, cb_prefix_output => 'prefix_output_output', message_multiple => 'Output endpoints statistics are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{outputs} = [
        { label => 'output-status', type => 2, critical_default => '%{queue_file_enabled} =~ /yes/i', set => {
                key_values => [ { name => 'queue_file_enabled' }, { name => 'state' }, { name => 'status' }, { name => 'type' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'speed-events', nlabel => 'output.events.processing_speed.persecond', set => {
                key_values => [ { name => 'speed_events' }, { name => 'display' } ],
                output_template => 'Events processing speed: %.2f/s',
                perfdatas => [
                    { label => 'speed_events', value => 'speed_events', template => '%.2f', 
                      unit => 'events/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'queued-events', nlabel => 'output.events.queued.count', set => {
                key_values => [ { name => 'queued_events' }, { name => 'display' } ],
                output_template => 'Queued events: %s',
                perfdatas => [
                    { label => 'queued_events', value => 'queued_events', template => '%s', 
                      unit => 'events', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'unacknowledged-events', nlabel => 'output.events.unacknowledged.count', set => {
                key_values => [ { name => 'unacknowledged_events' }, { name => 'display' } ],
                output_template => 'Unacknowledged events: %s',
                perfdatas => [
                    { label => 'unacknowledged_events', value => 'unacknowledged_events', template => '%s', 
                      unit => 'events', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{inputs_status} = [
        { label => 'input-status', type => 2, critical_default => '%{state} !~ /listening/i', set => {
                key_values => [ { name => 'state' }, { name => 'type' }, { name => 'display' } ],
                output_template => 'state: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'consumers', nlabel => 'input.consumers.count', set => {
                key_values => [ { name => 'consumers_count' }, { name => 'display' } ],
                output_template => 'Consumers: %s',
                perfdatas => [
                    { label => 'consumers', value => 'consumers_count', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];    

    $self->{maps_counters}->{consumers} = [
        { label => 'consumer-status', type => 2, critical_default => '%{state} !~ /connected/i', set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                output_template => 'state: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'speed-events', nlabel => 'consumer.events.processing_speed.persecond', set => {
                key_values => [ { name => 'speed_events' }, { name => 'display' } ],
                output_template => 'Events processing speed: %.2f/s',
                perfdatas => [
                    { label => 'speed_events', value => 'speed_events', template => '%.2f', 
                      unit => 'events/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'queued-events', nlabel => 'consumer.events.queued.count', set => {
                key_values => [ { name => 'queued_events' }, { name => 'display' } ],
                output_template => 'Queued events: %s',
                perfdatas => [
                    { label => 'queued_events', value => 'queued_events', template => '%s', 
                      unit => 'events', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'unacknowledged-events', nlabel => 'consumer.events.unacknowledged.count', set => {
                key_values => [ { name => 'unacknowledged_events' }, { name => 'display' } ],
                output_template => 'Unacknowledged events: %s',
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'broker-stats-file:s@' => { name => 'broker_stats_file' },
        'hostname:s'           => { name => 'hostname' },
        'timeout:s'            => { name => 'timeout', default => 30 },
        'sudo'                 => { name => 'sudo' },
        'filter-name:s'        => { name => 'filter_name' },
        'warning-status:s'     => { name => 'warning_status' }, # Legacy compat
        'critical-status:s'    => { name => 'critical_status' } # Legacy compat
    });

    $self->{ssh} = centreon::plugins::ssh->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    # Legacy compat
    if (defined($options{option_results}->{warning_status}) && $options{option_results}->{warning_status} ne '') {
        $options{option_results}->{'warning-input-status'} = $options{option_results}->{warning_status};
        $options{option_results}->{'warning-output-status'} = $options{option_results}->{warning_status};
    }
    if (defined($options{option_results}->{critical_status}) && $options{option_results}->{critical_status} ne '') {
        $options{option_results}->{'critical-input-status'} = $options{option_results}->{critical_status};
        $options{option_results}->{'critical-output-status'} = $options{option_results}->{critical_status};
    }
    
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

    $self->{outputs} = {};
    $self->{inputs} = {};

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
                $self->{output}->output_add(long_msg => "skipping endpoint '" . $endpoint . "': no matching filter name", debug => 1);
                next;
            }

            if (!defined($json->{$entry}->{status})) {
                $self->{inputs}->{$endpoint}->{display} = $endpoint;
                $self->{inputs}->{$endpoint}->{consumers_count} = 0;
                $self->{inputs}->{$endpoint}->{inputs_status} = {
                    display => $endpoint,
                    type => "input",
                    state => $json->{$entry}->{state},
                    consumers_count => 0,
                    consumers => {}
                };

                foreach my $key (keys %{$json->{$entry}}) {
                    next if ($key !~ /^$endpoint/);
                    $self->{inputs}->{$endpoint}->{consumers_count}++;
                    $self->{inputs}->{$endpoint}->{inputs_status}->{consumers_count}++;
                    
                    $self->{inputs}->{$endpoint}->{consumers}->{$key} = {
                        display => $key,
                        state => $json->{$entry}->{$key}->{state},
                        speed_events => $json->{$entry}->{$key}->{event_processing_speed},
                        queued_events => $json->{$entry}->{$key}->{queued_events},
                        unacknowledged_events => ($json->{$entry}->{$key}->{bbdo_unacknowledged_events}) ? $json->{$entry}->{$key}->{bbdo_unacknowledged_events} : 0
                    };
                }
            } else {
                $self->{outputs}->{$endpoint} = {
                    display => $endpoint,
                    state => $json->{$entry}->{state},
                    type => "output",
                    status => $json->{$entry}->{status},
                    speed_events => $json->{$entry}->{event_processing_speed},
                    queued_events => $json->{$entry}->{queued_events},
                    unacknowledged_events => ($json->{$entry}->{bbdo_unacknowledged_events}) ? $json->{$entry}->{bbdo_unacknowledged_events} : 0,
                    queue_file_enabled => ($json->{$entry}->{queue_file_enabled}) ? 'yes' : 'no'
                };
            }
        }
    }

    if (scalar(keys %{$self->{inputs}}) <= 0 && scalar(keys %{$self->{outputs}}) <= 0) {
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
Can be: 'speed-events', 'queued-events', 'unacknowledged-events', 'consumers'.

=item B<--warning-*-status>

Define the conditions to match for the status to be WARNING.
Can be: 'input', 'output' or 'consumer'
You can use the following variables: %{queue_file_enabled}, %{state}, %{status}, %{display}

=item B<--critical-*-status>

Define the conditions to match for the status to be CRITICAL.

Can be: 'input', 'output' or 'consumer'
You can use the following variables: %{queue_file_enabled}, %{state}, %{status}, %{type}, %{display}

Defaults are :

- input: '%{state} !~ /listening/i'
- ouput: '%{queue_file_enabled} =~ /yes/i'
- consumer: '%{state} !~ /connected/i'

=back

=cut
