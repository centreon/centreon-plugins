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

package storage::dell::equallogic::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|fan)$';

    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        fan => [
            ['unknown', 'UNKNOWN'],
            ['normal', 'OK'],
            ['warning', 'WARNING'],
            ['critical', 'CRITICAL'],
        ],
        temperature => [
            ['unknown', 'UNKNOWN'],
            ['normal', 'OK'],
            ['warning', 'WARNING'],
            ['critical', 'CRITICAL'],
        ],
        health => [
            ['unknown', 'UNKNOWN'],
            ['normal', 'OK'],
            ['warning', 'WARNING'],
            ['critical', 'CRITICAL'],
        ],
        psu => [
            ['on-and-operating', 'OK'],
            ['no-ac-power', 'CRITICAL'],
            ['failed-or-no-data', 'CRITICAL'],
        ],
        'psu.fan' => [
            ['not-applicable', 'OK'],
            ['fan-is-operational', 'OK'],
            ['fan-not-operational', 'CRITICAL'],
        ],
        raid => [
            ['ok', 'OK'],
            ['degraded', 'WARNING'],
            ['verifying', 'OK'],
            ['reconstructing', 'WARNING'],
            ['failed', 'CRITICAL'],
            ['catastrophicLoss', 'CRITICAL'],
            ['expanding', 'OK'],
            ['mirroring', 'OK'],
        ],
        disk => [
            ['on-line', 'OK'],
            ['spare', 'OK'],
            ['failed', 'CRITICAL'],
            ['off-line', 'WARNING'],
            ['alt-sig', 'WARNING'],
            ['too-small', 'WARNING'],
            ['history-of-failures', 'WARNING'],
            ['unsupported-version', 'CRITICAL'],
            ['unhealthy', 'CRITICAL'],
            ['replacement', 'CRITICAL'],
        ],
    };
    
    $self->{components_path} = 'storage::dell::equallogic::snmp::mode::components';
    $self->{components_module} = ['fan', 'psu', 'temperature', 'raid', 'disk', 'health'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

my $oid_eqlMemberName = '.1.3.6.1.4.1.12740.2.1.1.1.9';

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    push @{$self->{request}}, { oid => $oid_eqlMemberName };
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

sub get_member_name {
    my ($self, %options) = @_;
    
    my $name = defined($self->{results}->{$oid_eqlMemberName}->{$oid_eqlMemberName . '.' . $options{instance}}) ? 
                $self->{results}->{$oid_eqlMemberName}->{$oid_eqlMemberName . '.' . $options{instance}} : 'unknown';
    return $name;
}

1;

__END__

=head1 MODE

Check Hardware (Power Supplies, Fans, Temperatures, Raids, Disks, Health).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'fan', 'psu', 'temperature', 'raid', 'disk', 'health'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=fan --filter=psu)
Can also exclude specific instance: --filter=fan,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='fan,CRITICAL,^(?!(normal)$)'

=item B<--warning>

Set warning threshold for 'temperature', 'fan' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold for 'temperature', 'fan' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,40'

=back

=cut
