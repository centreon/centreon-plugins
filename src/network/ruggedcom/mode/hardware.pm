#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::ruggedcom::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use centreon::plugins::misc;

sub set_system {
    my ($self, %options) = @_;
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {        
        psu => [
            ['notPresent', 'OK'],
            ['functional', 'OK'],
            ['notFunctional', 'CRITICAL'],
            ['notConnected', 'WARNING'],
        ],
        fan => [
            ['notPresent', 'OK'],
            ['failed', 'CRITICAL'],
            ['standby', 'OK'],
            ['on', 'OK'],
            ['off', 'WARNING'],
        ],
    };
    
    $self->{components_path} = 'network::ruggedcom::mode::components';
    $self->{components_module} = ['psu', 'fan'];
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_performance => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check hardware (RUGGEDCOM-SYS-INFO-MIB).

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'psu', 'fan'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=psu).
You can also exclude items from specific instances: --filter=psu,1

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma separated list)
Can be specific or global: --absent-problem=fan,1

=item B<--no-component>

Define the expected status if no components are found (default: critical).


=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,status,regexp).
Example: --threshold-overload='psu,CRITICAL,^(?!(on)$)'

=item B<--warning>

Define the warning threshold for temperatures (syntax: type,instance,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Define the critical threshold for temperatures (syntax: type,instance,threshold)
Example: --critical='temperature,.*,40'

=item B<--warning-count-*>

Define the warning threshold for the number of components of one type (replace '*' with the component type).

=item B<--critical-count-*>

Define the critical threshold for the number of components of one type (replace '*' with the component type).

=back

=cut
    
