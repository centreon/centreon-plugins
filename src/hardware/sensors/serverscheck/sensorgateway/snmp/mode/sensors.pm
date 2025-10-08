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

package hardware::sensors::serverscheck::sensorgateway::snmp::mode::sensors;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^sensors$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {        
        output => [
            ['open', 'CRITICAL'],
            ['close', 'OK']
        ]
    };

    $self->{components_path} = 'hardware::sensors::serverscheck::sensorgateway::snmp::mode::components';
    $self->{components_module} = ['sensors'];
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check sensors components (Sensor Probes).

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'sensors'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=sensors).
You can also exclude items from specific instances: --filter=sensors,Inter

=item B<--absent-problem>

Return an error if a component is not 'present' (default is skipping).
It can be set globally or for a specific instance: --absent-problem='component_name' or --absent-problem='component_name,instance_value'.

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,status,regexp).
Example: --threshold-overload='output,CRITICAL,^(?!(off)$)'

=item B<--warning>

Set warning threshold for temperatures and humidity (syntax: type,regexp,threshold)
Example: --warning='sensors,Int. Temp,30' --warning='sensors,Fuel Level,50:'

=item B<--critical>

Set critical threshold for temperature and humidity (syntax: type,regexp,threshold)
Example: --warning='sensors,Int. Temp,35' --warning='sensors,Fuel Level,40:'

=item B<--warning-count-*>

Define the warning threshold for the number of components of one type (replace '*' with the component type).

=item B<--critical-count-*>

Define the critical threshold for the number of components of one type (replace '*' with the component type).

=back

=cut
    
