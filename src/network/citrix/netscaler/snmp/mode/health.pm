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

package network::citrix::netscaler::snmp::mode::health;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|fanspeed|voltage)$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
         psu => [
            ['normal', 'OK'],
            ['not present', 'OK'],
            ['failed', 'CRITICAL'],
            ['not supported', 'UNKNOWN']
        ]
    };
    
    $self->{components_path} = 'network::citrix::netscaler::snmp::mode::components';
    $self->{components_module} = ['psu', 'fanspeed', 'temperature', 'voltage'];
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    my $oid_nsSysHealthEntry = '.1.3.6.1.4.1.5951.4.1.1.41.7.1';
    push @{$self->{request}}, { oid => $oid_nsSysHealthEntry };
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

my $oid_sysHealthCounterName = '.1.3.6.1.4.1.5951.4.1.1.41.7.1.1';
my $oid_sysHealthCounterValue = '.1.3.6.1.4.1.5951.4.1.1.41.7.1.2';

my %map_psu_status = (
    0 => 'normal',
    1 => 'not present',
    2 => 'failed',
    3 => 'not supported',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { "alternative-status-mapping:s" => { name => 'alternative_status_mapping', default => '' }});

    return $self;
}

1;

__END__

=head1 MODE

Check System Health Status.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'temperature', 'voltage', 'fanspeed', 'psu'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=psu).
You can also exclude items from specific instances: --filter=fan,1

=item B<--no-component>

Define the expected status if no components are found (default: critical).


=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma separated list)
Can be specific or global: --absent-problem=psu,1

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='psu,CRITICAL,^(?!(normal)$)'

=item B<--warning>

Set warning threshold for 'temperature', 'fanspeed', 'voltage' (syntax: type,regexp,threshold)
Example: --warning='temperature,.,30'

=item B<--critical>

Set critical threshold for 'temperature', 'fanspeed', 'voltage'(syntax: type,regexp,threshold)
Example: --critical='temperature,.*,40'

=item B<--alternative-status-mapping>

Depending on the Netscaler product, the translation of OID .1.3.6.1.4.1.5951.4.1.1.41.7.1.2 may diverge. The default interpretation of this OID is:

0 => not supported, 1 => not present, 2 => failed, 3 => normal.

With this option set to '1', the OID will be interpreted otherwise:

0 => normal, 1 => not present, 2 => failed, 3 => not supported.

=back

=cut
