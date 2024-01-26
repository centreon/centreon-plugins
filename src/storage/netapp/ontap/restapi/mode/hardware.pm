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

package storage::netapp::ontap::restapi::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{cb_hook2} = 'save_custom';

    $self->{thresholds} = {
        state => [
            ['ok', 'OK'],
            ['error', 'CRITICAL'],
            ['.*', 'CRITICAL']
        ],
        disk => [
            ['present', 'OK'],
            ['broken', 'CRITICAL'],
            ['copy', 'OK'],
            ['maintenance', 'OK'],
            ['partner', 'OK'],
            ['reconstructing', 'OK'],
            ['removed', 'OK'],
            ['spare', 'OK'],
            ['unfail', 'OK'],
            ['zeroing', 'OK'],
            ['n/a', 'OK']
        ]
    };
    
    $self->{components_path} = 'storage::netapp::ontap::restapi::mode::components';
    $self->{components_module} = ['bay', 'disk', 'fru', 'shelf'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_performance => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub get_disks {
    my ($self, %options) = @_;

    return $self->{custom}->request_api(endpoint => '/api/storage/disks?fields=*');
}

sub get_shelves {
    my ($self, %options) = @_;

    return if (defined($self->{shelves}));

    $self->{shelves} = $self->{custom}->request_api(endpoint => '/api/storage/shelves?fields=*');
}

sub save_custom {
    my ($self, %options) = @_;

    $self->{custom} = $options{custom};
}

1;

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'bay', 'disk', 'fru', 'shelf'.

=item B<--filter>

Exclude some parts (comma separated list)
You can also exclude items from specific instances: --filter='fru,-'

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='fru,OK,error'

=back

=cut
