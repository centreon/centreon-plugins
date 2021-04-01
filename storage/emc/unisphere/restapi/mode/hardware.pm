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

package storage::emc::unisphere::restapi::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|power)$';

    $self->{cb_hook1} = 'init_custom';

    $self->{thresholds} = {
        health => [
            ['ok_but', 'WARNING'],
            ['ok', 'OK'],
            ['degraded', 'WARNING'],
            ['minor', 'WARNING'],
            ['major', 'CRITICAL'],
            ['critical', 'CRITICAL'],
            ['non_recoverable', 'CRITICAL'],
            ['unknown', 'UNKNOWN'],
        ],
    };
    
    $self->{components_path} = 'storage::emc::unisphere::restapi::mode::components';
    $self->{components_module} = ['disk', 'fan', 'iomodule', 'psu', 'dpe', 'battery', 'ssd', 'sp'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub init_custom {
    my ($self, %options) = @_;

    $self->{custom} = $options{custom};
}

1;

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'disk', 'fan', 'iomodule', 'psu', 'dpe', 'battery', 'ssd', 'sp'.

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter='disk,dpe_disk_6'

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='disk,OK,ok_but'

=item B<--warning>

Set warning threshold for 'temperature', 'power' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,40'

=item B<--critical>

Set critical threshold for 'temperature', 'power' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,50'

=back

=cut
