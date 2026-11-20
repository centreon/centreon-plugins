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

package hardware::server::cisco::ucs::xmlapi::mode::equipment;

use strict;
use warnings;
use base qw(centreon::plugins::templates::hardware);

sub set_system {
    my ($self, %options) = @_;

    $self->{cb_hook2} = 'load_data';

    $self->{thresholds} = {
        presence => [
            ['unknown',       'UNKNOWN'],
            ['empty',         'OK'],
            ['equipped',      'OK'],
            ['missing',       'WARNING'],
            ['mismatch.*',    'WARNING'],
            ['degraded',      'WARNING'],
        ],
        operability => [
            ['operable',         'OK'],
            ['poweredOff',       'OK'],
            ['autoUpgrade',      'OK'],
            ['discovery',        'OK'],
            ['config',           'OK'],
            ['unknown',          'UNKNOWN'],
            ['inoperable',       'CRITICAL'],
            ['degraded',         'WARNING'],
            ['.*[Pp]roblem.*',   'CRITICAL'],
            ['.*[Ff]ailed.*',    'CRITICAL'],
            ['.*',               'CRITICAL'],
        ],
        overall_status => [
            ['ok',                'OK'],
            ['unassociated',      'OK'],
            ['discovery',         'OK'],
            ['config',            'OK'],
            ['maintenance',       'OK'],
            ['power-off',         'OK'],
            ['unconfig',          'OK'],
            ['indeterminate',     'UNKNOWN'],
            ['degraded',          'WARNING'],
            ['inaccessible',      'WARNING'],
            ['disabled',          'WARNING'],
            ['removed',           'WARNING'],
            ['decommissioning',   'WARNING'],
            ['inoperable',        'CRITICAL'],
            ['.*-failed',         'CRITICAL'],
            ['.*-problem',        'CRITICAL'],
            ['.*',                'CRITICAL'],
        ],
        drive_status => [
            ['online',         'OK'],
            ['in-use',         'OK'],
            ['present',        'OK'],
            ['rebuilding',     'WARNING'],
            ['predictive',     'WARNING'],
            ['pre-failure',    'WARNING'],
            ['broken',         'CRITICAL'],
            ['unknown',        'UNKNOWN'],
            ['.*',             'CRITICAL'],
        ],
    };

    $self->{components_path}   = 'hardware::server::cisco::ucs::xmlapi::mode::components';
    $self->{components_module} = ['fan', 'psu', 'chassis', 'iocard', 'blade', 'fex', 'cpu', 'memory', 'localdisk'];
}

# Called by hardware template after loading component modules
sub load_data {
    my ($self, %options) = @_;

    # Collect all class IDs requested by component load() methods
    $self->{request_classes} = [];
    for my $mod (@{$self->{components_module}}) {
        my $package = $self->{components_path} . '::' . $mod;
        $package->load($self);
    }

    # Fetch all classes in one pass
    $self->{data} = {};
    for my $class_id (@{$self->{request_classes}}) {
        $self->{data}->{$class_id} = $options{custom}->request(class_id => $class_id);
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    return $self;
}

1;

__END__

=head1 MODE

Check Cisco UCS hardware components via XML API.

=over 8

=item B<--component>

Filter component type (regexp). Example: --component='blade|fan'

=item B<--filter>

Filter component instance (regexp). Example: --filter='chassis-1'

=item B<--no-component>

Return WARNING when no component is found (default: CRITICAL).

=item B<--threshold-overload>

Override default severity. Format: section,[instance,]status,regexp
Example: --threshold-overload='fan,WARNING,poweredOff'

=back

=cut
