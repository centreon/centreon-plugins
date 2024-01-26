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

package network::aruba::aoscx::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(?:fan\.speed|temperature|psu\.power)$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        default => [
            ['^ok$', 'OK'],
            ['normal', 'OK'],
            ['ready', 'OK'],
            ['.*', 'CRITICAL']
        ]
    };
    
    $self->{components_path} = 'network::aruba::aoscx::snmp::mode::components';
    $self->{components_module} = ['psu', 'temperature', 'fan', 'fantray'];
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'psu', 'temperature', 'fan', 'fantry'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=psu).
You can also exclude items from specific instances: --filter=fan,1.1

=item B<--no-component>

Define the expected status if no components are found (default: critical).


=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,status,regexp).
Example: --threshold-overload='fan,WARNING,string'

=item B<--warning>

Set warning threshold for 'temperature', 'fan.speed', 'psu.power' (syntax: section,[instance,]status,regexp)
Example: --warning='temperature,.*,30' --warning='fan.speed,.*,1000'

=item B<--critical>

Set critical threshold for 'temperature', 'fan.speed', 'psu.power' (syntax: section,[instance,]status,regexp)
Example: --critical='temperature,.*,40'

=back

=cut
