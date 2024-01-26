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

package network::keysight::nvos::restapi::mode::hardware;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_psu_output {
    my ($self, %options) = @_;

    return "power supply '" . $options{instance} . "' ";
}

sub prefix_temperature_output {
    my ($self, %options) = @_;

    return "temperature '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'temperatures', type => 1, cb_prefix_output => 'prefix_temperature_output', skipped_code => { -10 => 1 } },
        { name => 'fan', type => 0, skipped_code => { -10 => 1 } },
        { name => 'psus', type => 1, cb_prefix_output => 'prefix_psu_output', message_multiple => 'all power supplies are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{temperatures} = [
        {
            label => 'temperature-status',
            type => 2,
            unknown_default => '%{status} eq "unknown"',
            warning_default => '%{status} eq "warn"',
            critical_default => '%{status} eq "hot"',
            set => {
                key_values => [ { name => 'status' }, { name => 'class' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'temperature', nlabel => 'hardware.temperature.celsius', set => {
                key_values => [ { name => 'reading' }, { name => 'class' } ],
                output_template => 'reading: %s C',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'C',
                        instances => $self->{result_values}->{class},
                        value => $self->{result_values}->{reading},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
                    );
                }
            }
        }
    ];

    $self->{maps_counters}->{fan} = [
        { label => 'fans-failed', nlabel => 'fans.failed.count', set => {
                key_values => [ { name => 'failed' } ],
                output_template => 'number of failed fans: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{psus} = [
        { label => 'psu-status', type => 2, critical_default => '%{status} eq "bad"', set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        endpoint => '/api/system',
        get_param => ['properties=power_module_a,power_module_b,temperature_readings,fan_failure_count']
    );
    if (!defined($result->{power_module_a})) {
        $self->{output}->add_option_msg(short_msg => "Cannot find hardware informations");
        $self->{output}->option_exit();
    }

    $self->{temperatures} = {};
    foreach (@{$result->{temperature_readings}}) {
        $self->{temperatures}->{ $_->{temperature_sensor}->{id}->{module_class} } = {
            class => $_->{temperature_sensor}->{id}->{module_class},
            status => lc($_->{temperature_status}),
            reading => $_->{temperature}
        };
    }

    # -1 means: unsupported
    if ($result->{fan_failure_count} > -1) {
        $self->{fan} = { failed => $result->{fan_failure_count} };
    }

    $self->{psus} = {
        power_module_a => {
            name => 'power_module_a',
            status => lc($result->{power_module_a}->{power_supply_status})
        },
        power_module_b => {
            name => 'power_module_b',
            status => lc($result->{power_module_b}->{power_supply_status})
        }
    };
}

1;

__END__

=head1 MODE

Check hardware.

=over 8

=item B<--unknown-temperature-status>

Define the conditions to match for the status to be UNKNOWN (default : '%{status} eq "unknown"').
You can use the following variables: %{status}, %{class}

=item B<--warning-temperature-status>

Define the conditions to match for the status to be WARNING (default : '%{status} eq "warn"').
You can use the following variables: %{status}, %{class}

=item B<--critical-temperature-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} eq "hot"');
You can use the following variables: %{status}, %{class}

=item B<--unknown-psu-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{name}

=item B<--warning-psu-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} eq "bad"');
You can use the following variables: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds. Can be:
'temperature', 'fans-failed'.

=back

=cut
