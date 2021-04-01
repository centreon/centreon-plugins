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

package network::checkpoint::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_performance => 1, no_absent => 1);
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

Which component to check (Default: '.*').
Can be: 'psu', 'fan', 'temperature', 'voltage', 'raiddisk'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=fan --filter=psu)
Can also exclude specific instance: --filter=psu,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='fan,CRITICAL,^(?!(false)$)'

=back

=cut
