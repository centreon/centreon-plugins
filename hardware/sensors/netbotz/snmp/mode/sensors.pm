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

package hardware::sensors::netbotz::snmp::mode::sensors;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|humidity|dewpoint|airflow)$';

    $self->{cb_hook1} = 'get_version';
    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        default => [        
            ['normal', 'OK'],
            ['info', 'OK'],
            ['warning', 'WARNING'],
            ['error', 'CRITICAL'],
            ['critical', 'CRITICAL'],
            ['failure', 'CRITICAL']
        ]
    };

    $self->{components_path} = 'hardware::sensors::netbotz::snmp::mode::components';
    $self->{components_module} = [
        'temperature', 'humidity', 'dewpoint', 'airflow', 
        'doorswitch', 'camera', 'otherstate'
    ];
}

sub get_version {
    my ($self, %options) = @_;

    my $v1_netBotzErrorStatus = '.1.3.6.1.4.1.5528.100.100';
    my $v5_netBotzErrorStatus = '.1.3.6.1.4.1.52674.500.100.0';
    my $result = $options{snmp}->get_leef(
        oids => [$v1_netBotzErrorStatus, $v1_netBotzErrorStatus . '.0', $v5_netBotzErrorStatus]
    );

    $self->{is_v5} = 0;
    $self->{netbotz_branch} = '5528.100';
    if (defined($result->{$v5_netBotzErrorStatus})) {
        $self->{is_v5} = 1;
        $self->{netbotz_branch} = '52674.500';
    } elsif (!defined($result->{$v1_netBotzErrorStatus}) && !defined($result->{$v1_netBotzErrorStatus . '.0'})) {
        $self->{output}->add_option_msg(short_msg => 'cannot find netbotz version');
        $self->{output}->option_exit();
    }
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
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

Check sensors.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'temperature', 'humidity', 'dewpoint', 'airflow', 
'doorswitch', 'camera', 'otherstate'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=temperature --filter=humidity)
Can also exclude specific instance: --filter=temperature,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='temperature,CRITICAL,^(?!(normal)$)'

=item B<--warning>

Set warning threshold for 'temperature', 'humidity' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold for 'temperature', 'humidity' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,50'

=back

=cut
