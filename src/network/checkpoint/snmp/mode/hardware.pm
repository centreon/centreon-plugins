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

package network::checkpoint::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(?:fan|temperature|voltage)$';

    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        temperature => [
            ['true', 'CRITICAL'],
            ['reading error', 'CRITICAL'],
            ['false', 'OK']
        ],
        voltage => [
            ['true', 'CRITICAL'],
            ['reading error', 'CRITICAL'],
            ['false', 'OK']
        ],
        fan => [
            ['true', 'CRITICAL'],
            ['reading error', 'CRITICAL'],
            ['false', 'OK']
        ],
        psu => [
            ['ok', 'OK'],
            ['up', 'OK'],
            ['down', 'CRITICAL'],
            ['dummy', 'OK'],
            ['^present', 'OK']
        ],
        raiddisk => [
            ['online', 'OK'],
            ['missing', 'OK'],
            ['not_compatible', 'CRITICAL'],
            ['disc_failed', 'CRITICAL'],
            ['initializing', 'OK'],
            ['offline_requested', 'OK'],
            ['failed_requested', 'OK'],
            ['unconfigured_good_spun_up', 'WARNING'],
            ['unconfigured_good_spun_down', 'WARNING'],
            ['unconfigured_bad', 'CRITICAL'],
            ['hotspare', 'OK'],
            ['drive_offline', 'WARNING'],
            ['rebuild', 'WARNING'],
            ['failed', 'CRITICAL'],
            ['copyback', 'WARNING'],
            ['other_offline', 'WARNING']
        ]
    };
    
    $self->{components_path} = 'network::checkpoint::snmp::mode::components';
    $self->{components_module} = ['voltage', 'fan', 'temperature', 'psu', 'raiddisk'];
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check hardware (fans, power supplies, temperatures, voltages).

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'psu', 'fan', 'temperature', 'voltage', 'raiddisk'.

=item B<--add-name-instance>

Add literal description for instance value (used in filter and threshold options).

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=fan --filter=psu).
You can also exclude items from specific instances: --filter=psu,1

=item B<--no-component>

Define the expected status if no components are found (default: critical).


=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='fan,CRITICAL,^(?!(false)$)'

=item B<--warning> B<--critical>

Set thresholds for 'fan', 'temperature', 'voltage' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,40' --warning='critical,.*,45'

=back

=cut
