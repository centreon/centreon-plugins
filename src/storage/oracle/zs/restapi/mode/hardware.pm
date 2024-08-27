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

package storage::oracle::zs::restapi::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{cb_hook2} = 'execute_custom';

    $self->{thresholds} = {
        default => [
            ['faulted', 'CRITICAL'],
            ['ok', 'OK'],
        ],
    };

    $self->{components_exec_load} = 0;

    $self->{components_path} = 'storage::oracle::zs::restapi::mode::components';
    $self->{components_module} = ['chassis', 'cpu', 'disk', 'fan', 'memory', 'psu', 'slot'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_performance => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub execute_custom {
    my ($self, %options) = @_;

    $self->{results} = {};
    my $result = $options{custom}->request_api(url_path => '/api/hardware/v1/chassis');
    foreach (@{$result->{chassis}}) {
        my $chassis = $options{custom}->request_api(url_path => $_->{href});
        $self->{results}->{$_->{name}} = $chassis->{chassis};
    }
}

1;

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'chassis', 'cpu', 'disk', 'fan', 'memory', 'psu', 'slot'.

=item B<--filter>

Exclude some parts (comma separated list)
You can also exclude items from specific instances: --filter='disk,hdd 0'

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='disk,WARNING,faulted'

=back

=cut
