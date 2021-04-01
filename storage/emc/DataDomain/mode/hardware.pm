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

package storage::emc::DataDomain::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use storage::emc::DataDomain::lib::functions;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(battery|temperature)$';

    $self->{cb_hook1} = 'get_version'; # before the loads
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        fan => [
            ['notfound', 'OK'],
            ['ok', 'OK'],
            ['failed', 'CRITICAL'],
        ],
        temperature => [
            ['failed', 'CRITICAL'],
            ['ok', 'OK'],
            ['notfound', 'OK'],
            ['absent', 'OK'],
            ['overheatWarning', 'WARNING'],
            ['overheatCritical', 'CRITICAL'],
        ],
        psu => [
            ['absent', 'OK'],
            ['ok', 'OK'],
            ['failed', 'CRITICAL'],
            ['faulty', 'WARNING'],
            ['acnone', 'WARNING'],
            ['unknown', 'UNKNOWN'],
        ],
        disk => [
            ['ok', 'OK'],
            ['spare', 'OK'],
            ['available', 'OK'],
            ['unknown', 'UNKNOWN'],
            ['absent', 'OK'],
            ['failed', 'CRITICAL'],
        ],
        battery => [
            ['ok', 'OK'],
            ['disabled', 'OK'],
            ['discharged', 'WARNING'],
            ['softdisabled', 'OK'],
            ['UNKNOWN', 'UNKNOWN'],
        ],
    };
    
    $self->{components_path} = 'storage::emc::DataDomain::mode::components';
    $self->{components_module} = ['fan', 'temperature', 'psu', 'disk', 'battery'];
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

sub get_version {
    my ($self, %options) = @_;
    
    my $oid_sysDescr = '.1.3.6.1.2.1.1.1.0'; # 'Data Domain OS 5.4.1.1-411752'
    my $result = $options{snmp}->get_leef(oids => [ $oid_sysDescr ]);
    if (!($self->{os_version} = storage::emc::DataDomain::lib::functions::get_version(value => $result->{$oid_sysDescr}))) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'Cannot get DataDomain OS version.'
        );
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    $self->{output}->output_add(long_msg => 'DataDomain OS version: ' . $self->{os_version} . '.');
}

1;

__END__

=head1 MODE

Check components (Fans, Power Supplies, Temperatures, Disks, Nvram Batteries).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'psu', 'fan', 'disk', 'temperature', 'battery'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=fan --filter=psu)
Can also exclude specific instance: --filter=psu,3.3

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping)
Can be specific or global: --absent-problem=psu,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='fan,CRITICAL,^(?!(ok)$)'

=item B<--warning>

Set warning threshold for temperatures (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,20'

=item B<--critical>

Set critical threshold for temperatures and battery charge (syntax: type,regexp,threshold)
Example: --critical='temperature,1.1,25' --critical='battery,.*,20:'

=back

=cut
    
