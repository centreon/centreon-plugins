#
# Copyright 2018 Centreon (http://www.centreon.com/)
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
# Author : ArnoMLT
#

package storage::netgear::readynas::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(fan|temperature)$';
    
    $self->{cb_hook1} = 'init_mib_ver';
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        default => [
            ['Normal', 'OK'],
            ['Ok', 'OK'],
            ['Unknown', 'CRITICAL'],
            ['Failed', 'CRITICAL'],
            ['n/a', 'OK' ]
        ],
        disk => [
            ['Online', 'OK'],
            ['Ok', 'OK'],
            ['Unknown', 'OK'],
            ['Offline', 'CRITICAL']
        ],
        psu => [
            ['On', 'OK'],
            ['Ok', 'OK'],
            ['Off', 'CRITICAL'],
            ['Unknown', 'CRITICAL']
        ],
        volume => [
            ['Redundant', 'OK'],
            ['Ok', 'OK'],
            ['Unprotected', 'WARNING'],
            ['Degraded', 'CRITICAL'],
            ['Dead', 'CRITICAL'],
            ['Unknown', 'CRITICAL']
        ]
    };
    
    $self->{components_path} = 'storage::netgear::readynas::snmp::mode::components';
    $self->{components_module} = ['psu', 'fan', 'disk', 'volume', 'temperature'];
}

sub init_mib_ver {
    my ($self, %options) = @_;

    # make the difference between READYNASOS-MIB (v6) and READYNAS-MIB (v4)
    my $oid_MgrSoftwareVersion_v4 = '.1.3.6.1.4.1.4526.18.1.0';
    my $oid_MgrSoftwareVersion_v6 = '.1.3.6.1.4.1.4526.22.1.0';
    
    my $result = $options{snmp}->get_leef(oids => [$oid_MgrSoftwareVersion_v4, $oid_MgrSoftwareVersion_v6]);
    
    $self->{mib_ver} = defined($result->{$oid_MgrSoftwareVersion_v4}) ? 'v4' : 'v6';
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

Check hardware (READYNASOS-MIB, READYNAS-MIB) (Fans, Power Supplies, Disk status, Volume status, Temperatures).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'psu', 'fan', 'disk', 'volume', 'temperature'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=psu)
Can also exclude specific instance: --filter=psu,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='psu,CRITICAL,^(?!(on)$)'

=item B<--warning>

Set warning threshold for temperatures, fan (syntax: type,instance,threshold)
Example: --warning='xxxxx,.*,30'

=item B<--critical>

Set critical threshold for temperatures, fan (syntax: type,instance,threshold)
Example: --critical='xxxxx,.*,40'

=back

=cut
