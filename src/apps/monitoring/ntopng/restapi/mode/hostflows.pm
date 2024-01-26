#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package apps::monitoring::ntopng::restapi::mode::hostflows;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_packet_perfdata {
    my ($self) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => '/s',
        instances => [ $self->{result_values}->{ip} ],
        value => sprintf('%.2f', $self->{result_values}->{ $self->{key_values}->[0]->{name} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_traffic_perfdata {
    my ($self) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 'b/s',
        instances => [ $self->{result_values}->{ip} ],
        value => sprintf('%d', $self->{result_values}->{ $self->{key_values}->[0]->{name} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'packets-received', nlabel => 'host.packets.received.persecond', set => {
                key_values => [ { name => 'packetsReceived', per_second => 1 }, { name => 'ip' } ],
                output_template => 'packets received: %.2f/s',
                closure_custom_perfdata => $self->can('custom_packet_perfdata')
            }
        },
        { label => 'packets-sent', nlabel => 'host.packets.sent.persecond', set => {
                key_values => [ { name => 'packetsSent', per_second => 1 }, { name => 'ip' } ],
                output_template => 'packets sent: %.2f/s',
                closure_custom_perfdata => $self->can('custom_packet_perfdata')
            }
        },
        { label => 'traffic-in', nlabel => 'host.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'bytesReceived', per_second => 1 }, { name => 'ip' } ],
                output_template => 'traffic in: %s%s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => $self->can('custom_traffic_perfdata')
            }
        },
        { label => 'traffic-out', nlabel => 'host.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'bytesSent', per_second => 1 }, { name => 'ip' } ],
                output_template => 'traffic out: %s%s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => $self->can('custom_traffic_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'interface:s' => { name => 'interface', default => 0 },
        'ip:s'        => { name => 'ip' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{ip}) || $self->{option_results}->{ip} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify ip argument");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(
        endpoint => "/lua/rest/v2/get/host/data.lua",
        get_param => ['ifid=' . $self->{option_results}->{interface}, 'host=' . $self->{option_results}->{ip} ]
    );

    $self->{global} = {
        ip              => $self->{option_results}->{ip},
        packetsSent     => $results->{rsp}->{'packets.sent'},
        packetsReceived => $results->{rsp}->{'packets.rcvd'},
        bytesSent       => $results->{rsp}->{'bytes.sent'} * 8,
        bytesReceived   => $results->{rsp}->{'bytes.rcvd'} * 8
    };

    $self->{cache_name} = 'ntopng_' . $options{custom}->get_hostname() . '_' . $self->{mode} . '_' . 
        md5_hex(
            defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '' . '_' .
            defined($self->{option_results}->{interface}) ? $self->{option_results}->{interface} : '' . '_' .
            defined($self->{option_results}->{ip}) ? $self->{option_results}->{ip} : ''
        );
}
        
1;

__END__

=head1 MODE

Check host flows.

=over 8

=item B<--interface>

Interface name to check (0 by default).

=item B<--ip>

Set IP Address to monitor (required).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'packets-received', 'packets-sent', 'traffic-in', 'traffic-out'.

=back

=cut
