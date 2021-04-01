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

package hardware::devices::polycom::trio::restapi::mode::network;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'packets-in', nlabel => 'network.packets.in.persecond', set => {
                key_values => [ { name => 'packets_in', per_second => 1 } ],
                output_template => 'packets in: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => '/s' }
                ],
            }
        },
        { label => 'packets-out', nlabel => 'network.packets.out.persecond', set => {
                key_values => [ { name => 'packets_out', per_second => 1 } ],
                output_template => 'packets out: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => '/s' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(url_path => '/api/v1/mgmt/network/stats');
    if (!defined($result->{data}->{TxPackets})) {
        $self->{output}->add_option_msg(short_msg => "cannot find network information.");
        $self->{output}->option_exit();
    }

    $self->{global} = {
        packets_in => $result->{data}->{RxPackets},
        packets_out => $result->{data}->{TxPackets}
    };

    $self->{cache_name} = 'polycom_trio_' . $options{custom}->{hostname}  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check network traffic.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'packets-in', 'packets-out'.

=back

=cut
