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

package centreon::common::broadcom::megaraid::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;
    
    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature)$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        default => [
            ['status-invalid', 'CRITICAL'],
            ['status-ok', 'OK'],
            ['status-critical', 'CRITICAL'],
            ['status-nonCritical', 'WARNING'],
            ['status-unrecoverable', 'CRITICAL'],
            ['status-not-installed', 'OK'],
            ['status-unknown', 'UNKNOWN'],
            ['status-not-available', 'WARNING'],
        ],
        vdrive => [
            ['offline', 'UNKNOWN'],
            ['partially-degraded', 'WARNING'],
            ['degraded', 'CRITICAL'],
            ['optimal', 'OK'],
        ],
        pdrive => [
            ['unconfigured-good', 'OK'],
            ['unconfigured-bad', 'CRITICAL'],
            ['hot-spare', 'OK'],
            ['offline', 'UNKNOWN'],
            ['failed', 'CRITICAL'],
            ['rebuild', 'OK'],
            ['online', 'OK'],
            ['copyback', 'OK'],
            ['system', 'OK'],
            ['UNCONFIGURED-SHIELDED', 'UNKNOWN'],
            ['HOTSPARE-SHIELDED', 'UNKNOWN'],
            ['CONFIGURED-SHIELDED', 'UNKNOWN'],
        ],
    };
    
    $self->{components_path} = 'centreon::common::broadcom::megaraid::snmp::mode::components';
    $self->{components_module} = ['alarm', 'fan', 'sim', 'slot', 'psu', 'temperature', 'pdrive', 'vdrive'];
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
    
    $options{options}->add_options(arguments => { 
    });
    
    return $self;
}

1;

__END__

=head1 MODE

Check hardware (LSI-MegaRAID-SAS-MIB).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'alarm', 'fan', 'sim', 'slot', 'psu',
'temperature', 'pdrive', 'vdrive'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=fan --filter=psu)
Can also exclude specific instance: --filter=fan,3

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=fan,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='psu,OK,^(?!(status-unrecoverable)$)'

=item B<--warning>

Set warning threshold for 'temperature' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,40'

=item B<--critical>

Set critical threshold for 'temperature' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,50'

=back

=cut
