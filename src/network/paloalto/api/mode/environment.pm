#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::paloalto::api::mode::environment;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(?:temperature|fan|voltage)$';

    $self->{cb_hook2} = 'api_execute';

    $self->{thresholds} = {
        default => [
            ['false', 'OK'],
            ['.*', 'CRITICAL']
        ]
    };

    $self->{components_exec_load} = 0;

    $self->{components_path} = 'network::paloalto::api::mode::components';
    $self->{components_module} = ['temperature', 'fan', 'voltage', 'psu'];
}

sub api_execute {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        type => 'op',
        cmd  => '<show><system><environmentals></environmentals></system></show>',
        ForceArray => ['entry']
    );

    # Structure the API response for the component checks
    # Data will be organized as: $self->{data}->{component_type}->{instance} = { ... }
    $self->{data} = {};

    # Process temperature data
    if ($result->{thermal}->{Slot1}->{entry}) {
        my $temp_idx = 0;
        foreach my $entry (@{$result->{thermal}->{Slot1}->{entry}}) {
            $temp_idx++;
            my $instance = "thermal_slot" . ($entry->{slot} // 1) . "_index" . $temp_idx;
            $self->{data}->{temperatures}->{$instance} = {
                description => $entry->{description} // "Temperature $temp_idx",
                value       => $entry->{DegreesC} // '',
                min         => $entry->{min} // '',
                max         => $entry->{max} // '',
                alarm       => $entry->{alarm} // 'False'
            };
        }
    }

    # Process fan data
    if ($result->{fan}->{Slot1}->{entry}) {
        my $fan_idx = 0;
        foreach my $entry (@{$result->{fan}->{Slot1}->{entry}}) {
            $fan_idx++;
            my $instance = "fan_slot" . ($entry->{slot} // 1) . "_index" . $fan_idx;
            $self->{data}->{fans}->{$instance} = {
                description => $entry->{description} // "Fan $fan_idx",
                rpm         => $entry->{RPMs} // '',
                min         => $entry->{min} // '',
                alarm       => $entry->{alarm} // 'False'
            };
        }
    }

    # Process voltage (power) data
    if ($result->{power}->{Slot1}->{entry}) {
        my $voltage_idx = 0;
        foreach my $entry (@{$result->{power}->{Slot1}->{entry}}) {
            $voltage_idx++;
            my $instance = "voltage_slot" . ($entry->{slot} // 1) . "_index" . $voltage_idx;
            $self->{data}->{voltages}->{$instance} = {
                description => $entry->{description} // "Voltage $voltage_idx",
                value       => $entry->{Volts} // '',
                min         => $entry->{min} // '',
                max         => $entry->{max} // '',
                alarm       => $entry->{alarm} // 'False'
            };
        }
    }

    # Process PSU (power supply) data
    if ($result->{'power-supply'}->{Slot1}->{entry}) {
        my $psu_idx = 0;
        foreach my $entry (@{$result->{'power-supply'}->{Slot1}->{entry}}) {
            $psu_idx++;
            my $instance = "psu_slot" . ($entry->{slot} // 1) . "_index" . $psu_idx;
            $self->{data}->{psus}->{$instance} = {
                description => $entry->{description} // "PSU $psu_idx",
                inserted    => $entry->{Inserted} // 'False',
                alarm       => $entry->{alarm} // 'False'
            };
        }
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check Palo Alto environment sensors (temperatures, fans, voltages, power supplies).

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'psu', 'temperature', 'fan', 'voltage'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=temperature).
You can also exclude items from specific instances: --filter=C<temperature,Temperature CPLD>

=item B<--absent-problem>

Return an error if a component is not 'present' (default is skipping).
It can be set globally or for a specific instance: --absent-problem='component_name' or --absent-problem='component_name,instance_value'.

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='psu,ok,true'

=item B<--warning>

Set warning threshold for 'temperature', 'fan', 'voltage' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,50' --warning='fan,.*,2500'

=item B<--critical>

Set critical threshold for 'temperature', 'fan', 'voltage' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,70' --critical='fan,.*,1000'

=item B<--warning-count-*>

Define the warning threshold for the number of components of one type (replace '*' with the component type).

=item B<--critical-count-*>

Define the critical threshold for the number of components of one type (replace '*' with the component type).

=back

=cut
