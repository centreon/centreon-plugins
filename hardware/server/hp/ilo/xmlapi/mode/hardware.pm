#
# Copyright 2019 Centreon (http://www.centreon.com/)
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
    
    $self->{regexp_threshold_overload_check_section_option} = 
        '^(temperature|fan|vrm|psu|cpu|memory|nic|battery|ctrl|driveencl|pdrive|ldrive|bios)$';
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
            ['.*', 'CRITICAL'],
        ],
        nic => [
            ['Ok', 'OK'],
            ['Unknown', 'OK'],
            ['Disabled', 'OK'],
            ['.*', 'CRITICAL'],
        ],
    };
    
    $self->{components_path} = 'hardware::server::hp::ilo::xmlapi::mode::components';
    $self->{components_module} = ['fan', 'temperature', 'vrm', 'psu', 'cpu', 'memory', 'nic', 'battery', 'ctrl',
        'driveencl', 'pdrive', 'ldrive', 'bios'];
}

sub api_execute {
    my ($self, %options) = @_;
    
    $self->{xml_result} = $options{custom}->get_ilo_data();
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                });

    return $self;
}

1;

__END__

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'fan', 'temperature', 'vrm', 'psu', 'cpu', 'memory', 'nic', 'battery', 'ctrl',
'driveencl', 'pdrive', 'ldrive', 'bios'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=temperature --filter=fan)
Can also exclude specific instance: --filter="fan,Fan Block 1"

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping)
Can be specific or global: --absent-problem="fan,Fan Block 1"

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='fan,OK,degraded'

=item B<--warning>

Set warning threshold for 'temperature', 'fan' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold for 'temperature', 'fan' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,50'

=back

=cut
