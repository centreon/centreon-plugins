#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package storage::nimble::restapi::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(?:fan|temperature)$';

    $self->{cb_hook2} = 'execute_custom';

    $self->{thresholds} = {
        sensor => [
            ['ok', 'OK'],
            ['alerted', 'CRITICAL'],
            ['failed', 'CRITICAL'],
            ['missing', 'OK']
        ],
        disk => [
            ['valid', 'OK'],
            ['in use', 'OK'],
            ['failed', 'CRITICAL'],
            ['absent', 'OK'],
            ['removed', 'OK'],
            ['void', 'OK'],
            ['t_fail', 'CRITICAL'],
            ['foreign', 'OK']
        ],
        raid => [
            ['N/A', 'OK'],
            ['okay', 'OK'],
            ['resynchronizing', 'OK'],
            ['spare', 'OK'],
            ['faulty', 'CRITICAL']
        ]
    };

    $self->{components_path} = 'storage::nimble::restapi::mode::components';
    $self->{components_module} = ['disk', 'fan', 'temperature', 'psu'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    $self->{requests} = {};
    return $self;
}

sub use_serial {
    my ($self, %options) = @_;

    return $self->{use_serial} if (defined($self->{use_serial}));

    $self->{use_serial} = 0;
    my $array_names = {};
    foreach (@{$self->{results}->{shelve}->{data}}) {
        if (defined($array_names->{ $_->{array_name} })) {
            $self->{use_serial} = 1;
            last;
        }
        $array_names->{ $_->{array_name} } = 1;
    }

    return $self->{use_serial};
}

sub execute_custom {
    my ($self, %options) = @_;

    $self->{results} = {};
    foreach (keys %{$self->{requests}}) {
        my $result = $options{custom}->request_api(endpoint => $self->{requests}->{$_});
        $self->{results}->{$_} = $result;
    }
}

1;

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'disk', 'fan', 'psu', 'temperature'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=psu)
Can also exclude specific instance: --filter=fan,A:fan1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='sensor,WARNING,missing'

=item B<--warning>

Set warning threshold for 'fan', 'temperature' (syntax: section,[instance,]status,regexp)
Example: --warning='temperature,.*,30' --warning='fan,.*,1000'

=item B<--critical>

Set critical threshold for 'fan', 'temperature' (syntax: section,[instance,]status,regexp)
Example: --critical='temperature,.*,40'

=back

=cut
