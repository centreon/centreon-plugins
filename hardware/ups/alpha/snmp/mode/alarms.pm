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

package hardware::ups::alpha::snmp::mode::alarms;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        alarm => [
            ['on', 'CRITICAL'],
            ['off', 'OK']
        ]
    };

    $self->{components_path} = 'hardware::ups::alpha::snmp::mode::components';
    $self->{components_module} = ['alarm'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_performance => 1, no_load_components => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

1;

=head1 MODE

Check alarms.

=over 8

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter="alarm,FAN Alarm"

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='alarm,FAN Alarm,OK,on'

=back

=cut

package hardware::ups::alpha::snmp::mode::components::alarm;

use strict;
use warnings;

my %map_status = (0 => 'off', 1 => 'on');

my $mapping = {
    upsAlarmDescr       => { oid => '.1.3.6.1.4.1.7309.6.1.5.2.1.2' },
    upsAlarmStatus      => { oid => '.1.3.6.1.4.1.7309.6.1.5.2.1.3', map => \%map_status },    
};
my $oid_upsAlarmEntry = '.1.3.6.1.4.1.7309.6.1.5.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_upsAlarmEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking alarms");
    $self->{components}->{alarm} = {name => 'alarms', total => 0, skip => 0};
    return if ($self->check_filter(section => 'alarm'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_upsAlarmEntry}})) {
        next if ($oid !~ /^$mapping->{upsAlarmStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_upsAlarmEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'alarm', instance => $instance));

        $self->{components}->{alarm}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("alarm '%s' status is '%s' [instance = %s]",
                                                        $result->{upsAlarmDescr}, $result->{upsAlarmStatus}, $result->{upsAlarmDescr}));
        $exit = $self->get_severity(section => 'alarm', value => $result->{upsAlarmStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Alarm '%s' status is '%s'", $result->{upsAlarmDescr}, $result->{upsAlarmStatus}));
        }
    }
}

1;
