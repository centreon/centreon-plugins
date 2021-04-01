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

package network::freebox::restapi::mode::dslusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'rate-up', set => {
                key_values => [ { name => 'rate_up' } ],
                output_template => 'Dsl available upload bandwidth : %.2f %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'rate_up', value => 'rate_up', template => '%s',
                      unit => 'b/s', min => 0 }
                ]
            }
        },
        { label => 'rate-down', set => {
                key_values => [ { name => 'rate_down' } ],
                output_template => 'Dsl available download bandwidth : %.2f %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'rate_down', value => 'rate_down', template => '%s',
                      unit => 'b/s', min => 0 }
                ]
            }
        },
        { label => 'snr-up', set => {
                key_values => [ { name => 'snr_up' } ],
                output_template => 'Dsl upload signal/noise ratio : %.2f dB',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'snr_up', value => 'snr_up', template => '%.2f',
                      unit => 'dB' }
                ]
            }
        },
        { label => 'snr-down', set => {
                key_values => [ { name => 'snr_down' } ],
                output_template => 'Dsl download signal/noise ratio : %.2f dB',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'snr_down', value => 'snr_down', template => '%.2f',
                      unit => 'dB' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = $options{custom}->get_performance(db => 'dsl', path => 'rrd/');
    $self->{global}->{snr_up} *= 10 if (defined($self->{global}->{snr_up}));
    $self->{global}->{snr_down} *= 10 if (defined($self->{global}->{snr_down}));
    $self->{global}->{rate_up} *= int($self->{global}->{rate_up} * 8)
        if (defined($self->{global}->{rate_up}));
    $self->{global}->{rate_down} *= int($self->{global}->{rate_down} * 8)
        if (defined($self->{global}->{rate_down}));
}

1;

__END__

=head1 MODE

Check dsl usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^rate-up$'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'rate-up', 'rate-down', 'snr-up', 'snr-down'.

=back

=cut
