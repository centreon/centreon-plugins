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

package hardware::server::huawei::ibmc::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(harddisk|fan|psu|temperature)$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        'default' => [
            ['ok', 'OK'],
            ['minor', 'WARNING'],
            ['major', 'CRITICAL'],
            ['critical', 'CRITICAL'],
            ['absence', 'UNKNOWN'],
            ['unknown', 'UNKNOWN']
        ],
        'logicaldrive' => [
            ['offline', 'OK'],
            ['partial degraded', 'WARNING'],
            ['degraded', 'CRITICAL'],
            ['optimal', 'OK'],
            ['unknown', 'UNKNOWN']
        ],
        'raidcontroller' => [
            ['memory correctable error', 'WARNING'],
            ['memory uncorrectable error', 'CRITICAL'],
            ['memory ECC error reached limit', 'CRITICAL'],
            ['NVRAM uncorrectable error', 'CRITICAL'],
            ['ok', 'OK'],
            ['unknown', 'UNKNOWN']
        ]
    };

    $self->{components_path} = 'hardware::server::huawei::ibmc::snmp::mode::components';
    $self->{components_module} = [
        'component', 'cpu', 'harddisk', 'fan', 'logicaldrive',
        'memory', 'pcie', 'psu', 'raidcontroller', 'temperature'
    ];
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

Check hardware components.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'component', 'cpu', 'harddisk', 'fan', 'logicaldrive',
'memory', 'pcie', 'psu', 'raidcontroller', 'temperature'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=psu)
Can also exclude specific instance: --filter=psu,1

=item B<--no-component>

Return an error if no components are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='psu,CRITICAL,^(?!(ok)$)'

=item B<--warning>

Set warning threshold (syntax: type,regexp,threshold)
Example: --warning='psu,.*,300'

=item B<--critical>

Set critical threshold (syntax: type,regexp,threshold)
Example: --critical='psu,.*,400'

=back

=cut
    
