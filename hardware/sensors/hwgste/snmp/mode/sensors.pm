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


package hardware::sensors::hwgste::snmp::mode::sensors;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use hardware::sensors::hwgste::snmp::mode::components::resources qw($mapping);

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|humidity)$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        default => [
            ['invalid', 'UNKNOWN'],
            ['normal', 'OK'],
            ['outOfRangeLo', 'WARNING'],
            ['outOfRangeHi', 'WARNING'],
            ['alarmLo', 'CRITICAL'],
            ['alarmHi', 'CRITICAL']
        ]
    };

    $self->{components_path} = 'hardware::sensors::hwgste::snmp::mode::components';
    $self->{components_module} = ['temperature', 'humidity'];
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(
        oids => [{ oid => $mapping->{branch_sensors}->{hwgste} }, { oid => $mapping->{branch_sensors}->{hwgste2} }]
    );
    $self->{branch} = 'hwgste';
    if (defined($self->{results}->{ $mapping->{branch_sensors}->{hwgste2} }) && 
        scalar(keys %{$self->{results}->{ $mapping->{branch_sensors}->{hwgste2} }}) > 0) {
        $self->{branch} = 'hwgste2';
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check HWg-STE sensors.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'temperature', 'humidity'.

=item B<--filter>

Exclude some parts.
Can also exclude specific instance: --filter=sensor,10

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='sensor,CRITICAL,^(?!(normal)$)'

=item B<--warning>

Set warning threshold for temperature, humidity (syntax: type,instance,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold for temperature, humidity (syntax: type,instance,threshold)
Example: --critical='humidty,.*,40'

=back

=cut
