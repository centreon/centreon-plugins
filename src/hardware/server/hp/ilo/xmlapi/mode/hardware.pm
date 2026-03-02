#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package hardware::server::hp::ilo::xmlapi::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|fan)$';
    
    $self->{cb_hook2} = 'api_execute';
    
    $self->{thresholds} = {
        default => [
            ['Ok', 'OK'],
            ['Good', 'OK'],
            ['Not installed', 'OK'],
            ['Not Present', 'OK'],
            ['NOT APPLICABLE', 'OK'],
            ['n/a', 'OK'],
            ['Unknown', 'UNKNOWN'],
            ['Warning', 'WARNING'],
            ['.*', 'CRITICAL']
        ],
        nic => [
            ['Ok', 'OK'],
            ['Unknown', 'OK'],
            ['Disabled', 'OK'],
            ['.*', 'CRITICAL']
        ]
    };
    
    $self->{components_path} = 'hardware::server::hp::ilo::xmlapi::mode::components';
    $self->{components_module} = [
        'fan', 'temperature', 'vrm', 'psu', 'cpu', 'memory', 'nic', 'battery', 'ctrl',
        'driveencl', 'pdrive', 'ldrive', 'bios'
    ];
}

sub api_execute {
    my ($self, %options) = @_;
    
    $self->{xml_result} = $options{custom}->get_ilo_data();
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
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

Define a regular expression to select which components to check (default: '.*').
Can be: C<fan>, C<temperature>, C<vrm>, C<psu>, C<cpu>, C<memory>, C<nic>, C<battery>, C<ctrl>,
C<driveencl>, C<pdrive>, C<ldrive>, C<bios>.

=item B<--filter>

Exclude the given items (example: --filter=temperature --filter=fan).
You can also exclude items from specific instances: --filter="fan,Fan Block 1"

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping).
Can be specific or global (example: --absent-problem="fan,Fan Block 1").

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='fan,OK,degraded'

=item B<--warning>

Define the warning threshold for 'temperature', 'fan'. Syntax: type,regexp,threshold.
Example: --warning='temperature,.*,30'
When not specified on the command line the warning threshold for the 'temperature' entity is automatically defined based on the CAUTION field returned by ILO.

=item B<--critical>

Define the critical threshold for 'temperature', 'fan'. Syntax: type,regexp,threshold.
Example: --critical='temperature,.*,50'
When not specified on the command line the critical threshold for the 'temperature' entity is automatically defined based on the CRITICAL field returned by ILO.

=back

=cut
