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

package hardware::devices::polycom::hdx::snmp::mode::viewstationstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'h323-packet-loss', nlabel => 'viewstation.h323.packet.loss.percentage', set => {
                key_values => [ { name => 'polycomVSPercentPacketLoss' } ],
                output_template => 'H323 Packet Loss %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'h323-jitter', nlabel => 'viewstation.h323.jitter.milliseconds', set => {
                key_values => [ { name => 'polycomVSJitter' } ],
                output_template => 'H323 (audio/video) Jitter %.2f ms',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'ms' }
                ]
            }
        },
        { label => 'h323-latency', nlabel => 'viewstation.h323.latency.count', set => {
                key_values => [ { name => 'polycomVSLatency' }],
                output_template => 'H323 (audio/video) Latency %.2f',
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        }
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "View Station Phone Number: '" . $options{instance_value}->{display} . "' Stats: ";
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    return $self;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options();

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_polycomVSPhoneNumber = '.1.3.6.1.4.1.2684.1.1.2.0';
    my $oid_polycomVSPercentPacketLoss = '.1.3.6.1.4.1.2684.1.1.21.0';
    my $oid_polycomVSJitter = '.1.3.6.1.4.1.2684.1.1.22.0';
    my $oid_polycomVSLatency = '.1.3.6.1.4.1.2684.1.1.23.0';

    my $result = $options{snmp}->get_leef(
        oids => [
            $oid_polycomVSPhoneNumber,
            $oid_polycomVSPercentPacketLoss,
            $oid_polycomVSJitter,
            $oid_polycomVSLatency
        ],
        nothing_quit => 1
    );

    $self->{global} = {
        display => $result->{$oid_polycomVSPhoneNumber},
        polycomVSPercentPacketLoss => $result->{$oid_polycomVSPercentPacketLoss},
        polycomVSJitter => $result->{$oid_polycomVSJitter},
        polycomVSLatency => $result->{$oid_polycomVSLatency}
    };
}
1;

__END__

=head1 MODE

Check HDX ViewStation statistics during H323 communications

=over 8

=item B<--warning-* --critical-*>

Warning and Critical thresholds.
Possible values are: h323-packet-loss, h323-jitter, h323-latency

=back

=cut
