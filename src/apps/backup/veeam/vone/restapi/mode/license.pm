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

package apps::backup::veeam::vone::restapi::mode::license;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_license_unit_output {
    my ($self, %options) = @_;

    return sprintf(
        'total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $self->{result_values}->{total},
        $self->{result_values}->{used},
        $self->{result_values}->{prct_used},
        $self->{result_values}->{free},
        $self->{result_values}->{prct_free}
    );
}

sub prefix_license_output {
    my ($self, %options) = @_;

    return sprintf(
        "license unit '%s' ",
        $options{instance_value}->{unit}
    );
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'license', type => 1, cb_prefix_output => 'prefix_license_output', message_multiple => 'All license units are ok' }
    ];

    $self->{maps_counters}->{license} = [
        { label => 'license-unit-usage', nlabel => 'license.unit.usage.count', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_license_unit_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'license-unit-free', display_ok => 0, nlabel => 'license.unit.free.count', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_license_unit_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'license-unit-usage-prct', display_ok => 0, nlabel => 'license.unit.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_license_unit_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $license = $options{custom}->get_license();

    $self->{proxies} = {};
    foreach my $lic (@{$license->{units}}) {
        $self->{license}->{ lc($lic->{licenseUnit}) } = {
            unit => lc($lic->{licenseUnit}),
            total => $lic->{licensed},
            free => $lic->{available},
            used => $lic->{used},
            prct_used => $lic->{used} * 100 / $lic->{licensed},
            prct_free => $lic->{available} * 100 / $lic->{licensed}
        };
    }
}

1;

__END__

=head1 MODE

Check license units.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='license-unit-usage-prct'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'license-unit-usage', 'license-unit-free', 'license-unit-usage-prct'.
=back

=cut
