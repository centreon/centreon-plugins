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

package network::mikrotik::snmp::mode::environment;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;
    
    $self->{regexp_threshold_numeric_check_section_option} = '^(?:current|fan|power|temperature|voltage)$';
    
    $self->{cb_hook2} = 'snmp_execute';
     $self->{thresholds} = {
        'status' => [
            ['not ok', 'CRITICAL'],
            ['ok', 'OK']
        ]
    };

    $self->{components_path} = 'network::mikrotik::snmp::mode::components';
    $self->{components_module} = ['current', 'fan', 'power', 'status', 'temperature', 'voltage'];
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    my $oid_mtxrHealth = '.1.3.6.1.4.1.14988.1.1.3.100.1';
    if (defined($self->{option_results}->{legacy})) {
        $oid_mtxrHealth = '.1.3.6.1.4.1.14988.1.1.3';
    }
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_table(oid => $oid_mtxrHealth);
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'legacy' => { name => 'legacy' }
    });

    return $self;
}

1;

__END__

=head1 MODE

Check hardware.

=over 8

=item B<--legacy>

Look for legacy (prior to RouterOS 6.47) OIDs.

=item B<--component>

Which component to check (Default: '.*').
Can be: 'current', 'fan', 'power', 'status', 'temperature', 'voltage'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=fan --filter=voltage)
Can also exclude specific instance: --filter=fan,fan2

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--warning>

Set warning threshold for 'temperature', 'fan', 'voltage' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,40'

=item B<--critical>

Set critical threshold for 'temperature', 'fan', 'voltage' (syntax: type,regexp,threshold)
Example: --critical='temperature,cpu,50'

=back

=cut
