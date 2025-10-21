#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::juniper::common::junos::netconf::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(?:fan|psu|temperature)$';

    $self->{cb_hook2} = 'api_execute';

    $self->{thresholds} = {
        afeb        => [
            [ 'Online', 'OK' ],
            [ 'Offline', 'OK' ],
            [ 'Check', 'CRITICAL' ]
        ],
        fan         => [
            [ 'OK', 'OK' ],
            [ 'Check', 'WARNING' ]
        ],
        fpc         => [
            [ 'Online', 'OK' ],
            [ 'Dead', 'CRITICAL' ],
            [ 'Diag', 'WARNING' ],
            [ 'Empty', 'OK' ],
            [ 'Offline', 'CRITICAL' ],
            [ 'Present', 'CRITICAL' ],
            [ 'Probed', 'WARNING' ],
            [ 'Unknown', 'UNKNOWN' ],
            [ 'Offlining', 'OK' ],
            [ 'Spare', 'OK' ],
            [ 'Fault', 'CRITICAL' ] # Fault-off also
        ],
        pic         => [
            [ 'Online', 'OK' ],
            [ '.*', 'CRITICAL' ]
        ],
        mic         => [
            [ 'Online', 'OK' ],
            [ 'Error', 'CRITICAL' ]
        ],
        psu         => [
            [ 'Online', 'OK' ],
            [ 'Empty', 'OK' ],
            [ 'Present', 'WARNING' ] # present but not online
        ],
        temperature => [
            [ 'OK', 'OK' ],
            [ 'Absent', 'OK' ],
            [ '.*', 'CRITICAL' ]
        ]
    };

    $self->{components_path} = 'network::juniper::common::junos::netconf::mode::components';
    $self->{components_module} = [ 'afeb', 'fan', 'fpc', 'mic', 'pic', 'psu', 'temperature' ];
}

sub api_execute {
    my ($self, %options) = @_;

    $self->{results} = $options{custom}->get_hardware_infos();
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'display-instances' => { name => 'display_instances' }
    });

    return $self;
}

1;

__END__

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: C<afeb>, C<fan>, C<fpc>, C<mic>, C<pic>, C<psu>, C<temperature>.

=item B<--filter>

Exclude the items given as a comma-separated list (example: C<--filter=fan>).
You can also exclude items from specific instances: C<--filter=fan,Top>

=item B<--no-component>

Define the expected status if no components are found (default: C<critical>).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: C<--threshold-overload='fpc,CRITICAL,Unknown'>

=item B<--warning>

Set warning threshold (syntax: type,regexp,threshold)
Example: C<--warning='temperature,.*,30'>

=item B<--critical>

Set critical threshold (syntax: type,regexp,threshold)
Example: C<--critical='temperature,.*,40'>

=back

=cut
