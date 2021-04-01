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

package centreon::common::radlan::snmp::mode::environment;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use centreon::common::radlan::snmp::mode::components::resources qw(
    $oid_rlPhdUnitEnvParamEntry
    $oid_rlPhdUnitEnvParamMonitorAutoRecoveryEnable
);

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^temperature$';

    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        default => [
            ['normal', 'OK'],
            ['notPresent', 'OK'],
            ['warning', 'WARNING'],
            ['critical', 'CRITICAL'],
            ['shutdown', 'CRITICAL'],
            ['notFunctioning', 'CRITICAL'],
        ],
        temperature => [
            ['ok', 'OK'],
            ['unavailable', 'OK'],
            ['nonoperational', 'CRITICAL'],
        ]
    };

    $self->{components_path} = 'centreon::common::radlan::snmp::mode::components';
    $self->{components_module} = ['psu', 'fan', 'temperature'];
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    push @{$self->{request}}, {
        oid => $oid_rlPhdUnitEnvParamEntry,
        start => '.1.3.6.1.4.1.89.53.15.1.2', # rlPhdUnitEnvParamMainPSStatus
        end => $oid_rlPhdUnitEnvParamMonitorAutoRecoveryEnable
    };
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});

    $self->{radlan_new} = 0;
    foreach (keys %{$self->{results}->{$oid_rlPhdUnitEnvParamEntry}}) {
        if (/^$oid_rlPhdUnitEnvParamMonitorAutoRecoveryEnable\./) {
            $self->{radlan_new} = 1;
            last;
        }
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

1;

__END__

=head1 MODE

Check environment.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'fan', 'psu', 'temperature'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=psu)
Can also exclude specific instance: --filter=psu,0

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=fan#2#

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='fan,CRITICAL,^(?!(normal)$)'

=item B<--warning>

Set warning threshold (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,40'

=back

=cut
    
