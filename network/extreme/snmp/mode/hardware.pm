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

package network::extreme::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|fan|poe|psu\.power|psu\.fan)$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        psu => [
            ['notPresent', 'OK'],
            ['presentOK', 'OK'],
            ['presentPowerOff', 'WARNING'],
            ['presentNotOK', 'CRITICAL'],
        ],
        fan => [
            ['not operational', 'CRITICAL'],
            ['operational', 'OK'],
        ],
        slot => [
            ['notPresent', 'OK'],
            ['testing', 'OK'],
            ['mismatch', 'WARNING'],
            ['failed', 'CRITICAL'],
            ['operational', 'OK'],
            ['powerdown', 'WARNING'],
            ['unknown', 'UNKNOWN'],
            ['present', 'OK'],
            ['poweron', 'OK'],
            ['post', 'UNKNOWN'],
            ['downloading', 'WARNING'],
            ['booting', 'WARNING'],
            ['offline', 'WARNING'],
            ['initializing', 'OK'],
            ['invalid', 'CRITICAL'],
        ],
        poe => [
            ['initializing', 'OK'],
            ['operational', 'OK'],
            ['downloadFail', 'CRITICAL'],
            ['calibrationRequired', 'CRITICAL'],
            ['invalidFirmware', 'CRITICAL'],
            ['mismatchVersion', 'CRITICAL'],
            ['updating', 'OK'],
            ['invalidDevice', 'CRITICAL'],
            ['notOperational', 'CRITICAL'],
            ['other', 'CRITICAL'],
        ],
    };
    
    $self->{components_path} = 'network::extreme::snmp::mode::components';
    $self->{components_module} = ['fan', 'psu', 'slot', 'temperature', 'poe'];
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

Check Hardware (Fans, Power Supplies, Slot, Temperature, POEs).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'fan', 'psu', 'slot', 'temperature', 'poe'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=fan --filter=psu)
Can also exclude specific instance: --filter=fan,101

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=psu,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='psu,CRITICAL,^(?!(presentOK)$)'

=item B<--warning>

Set warning threshold for 'temperature', 'fan', 'psu.fan', 'psu' (syntax: type,regexp,threshold)
Example: --warning='psu.fan,1.1,5000'

=item B<--critical>

Set critical threshold for 'temperature', 'fan', 'psu.fan', 'psu' (syntax: type,regexp,threshold)
Example: --critical='psu,.*,200'

=back

=cut
