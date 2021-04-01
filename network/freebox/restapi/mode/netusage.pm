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

package network::freebox::restapi::mode::netusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
         { label => 'bw-up', set => {
                key_values => [ { name => 'bw_up' } ],
                output_template => 'Upload available bandwidth : %.2f %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'bw_up', value => 'bw_up', template => '%s',
                      unit => 'b/s', min => 0 }
                ]
            }
        },
        { label => 'bw-down', set => {
                key_values => [ { name => 'bw_down' } ],
                output_template => 'Download available bandwidth : %.2f %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'bw_down', value => 'bw_down', template => '%s',
                      unit => 'b/s', min => 0 }
                ]
            }
        },
        { label => 'rate-up', set => {
                key_values => [ { name => 'rate_up' } ],
                output_template => 'Upload rate : %.2f %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'rate_up', value => 'rate_up', template => '%s',
                      unit => 'b/s', min => 0 }
                ]
            }
        },
        { label => 'rate-down', set => {
                key_values => [ { name => 'rate_down' } ],
                output_template => 'Download rate : %.2f %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'rate_down', value => 'rate_down', template => '%s',
                      unit => 'b/s', min => 0 }
                ]
            }
        },
        { label => 'vpn-rate-up', set => {
                key_values => [ { name => 'vpn_rate_up' } ],
                output_template => 'Vpn client upload rate : %.2f %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'vpn_rate_up', value => 'vpn_rate_up', template => '%s',
                      unit => 'b/s', min => 0 }
                ]
            }
        },
        { label => 'vpn-rate-down', set => {
                key_values => [ { name => 'vpn_rate_down' } ],
                output_template => 'Vpn client download rate : %.2f %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'vpn_rate_down', value => 'vpn_rate_down', template => '%s',
                      unit => 'b/s', min => 0 }
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

    $self->{global} = $options{custom}->get_performance(db => 'net', path => 'rrd/');
    $self->{global}->{$_} = int($self->{global}->{$_} * 8) foreach (keys %{$self->{global}});
}

1;

__END__

=head1 MODE

Check network usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^bw-up$'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'bw-up', 'bw-down', 'rate-up', 'rate-down', 'vpn-rate-up', 'vpn-rate-down'.

=back

=cut
