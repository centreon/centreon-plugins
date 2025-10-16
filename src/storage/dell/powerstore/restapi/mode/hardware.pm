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

package storage::dell::powerstore::restapi::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{cb_hook1} = 'init_custom';

    $self->{thresholds} = {
        default => [
            ['Uninitialized', 'OK'],
            ['Healthy', 'OK'],
            ['Initializing', 'OK'],
            ['Failed', 'CRITICAL'],
            ['Disconnected', 'OK'],
            ['Prepare_Failed', 'CRITICAL'],
            ['Trigger_Update', 'OK'],
            ['Empty', 'OK']
        ]
    };

    $self->{components_exec_load} = 0;

    $self->{components_path} = 'storage::dell::powerstore::restapi::mode::components';
    $self->{components_module} = ['appliance', 'battery', 'dimm', 'disk', 'enclosure', 'fan', 'node', 'iomodule', 'psu', 'sfp'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, no_performance => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub init_custom {
    my ($self, %options) = @_;

    $self->{results} = $options{custom}->request_api(
        endpoint => '/api/rest/hardware',
        get_param => ['select=*', 'offset=0', 'limit=2000']
    );
}

1;

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'appliance', 'battery', 'dimm', 'disk', 'enclosure', 'fan', 'node', 'iomodule', 'psu', 'sfp'.

=item B<--filter>

Exclude some parts (comma separated list)
You can also exclude items from specific instances: --filter='disk,26018c5b69264a868e49119eec95b0a9'

=item B<--absent-problem>

Return an error if an entity is 'Empty' (default is skipping)
Can be specific or global: --absent-problem="fan,c41c5a99937e4953a180c65756f303f6"

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='disk,CRITICAL,Uninitialized'

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
