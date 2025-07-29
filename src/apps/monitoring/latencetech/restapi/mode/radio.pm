#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::monitoring::latencetech::restapi::mode::radio;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'snr-dbm', nlabel => 'signal.noise.ratio.db', set => {
                key_values => [ { name => 'SINR_dB' }, { name => 'display' } ],
                output_template => 'Signal noise ratio: %.2fdb',
                perfdatas => [
                    { value => 'SINR_dB', template => '%.2f',
                      unit => 'dbm', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'rssi-dbm', nlabel => 'received.signalstrength.indicator.dbm', set => {
                key_values => [ { name => 'RSSI_dBm' }, { name => 'display' } ],
                output_template => 'Received Signal Strength Indicator: %.2fdbm',
                perfdatas => [
                    { value => 'RSSI_dBm', template => '%.2f',
                      unit => 'dbm', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'rsrp-dbm', nlabel => 'reference.signalreceive.power.dbm', set => {
                key_values => [ { name => 'RSRP_dBm' }, { name => 'display' } ],
                output_template => 'Reference signal receive power: %.2fdbm',
                perfdatas => [
                    { value => 'RSRP_dBm', template => '%.2f',
                      unit => 'dbm', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
         { label => 'rsrq-db', nlabel => 'reference.signalreceive.quality.dbm', set => {
                key_values => [ { name => 'RSRQ_dB' }, { name => 'display' } ],
                output_template => 'Reference signal receive quality: %.2fdb',
                perfdatas => [
                    { value => 'RSRQ_dB', template => '%.2f',
                      unit => 'db', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        }
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Agent '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};
    my $results = $options{custom}->request_api(endpoint => '/radio');
    $self->{global}->{display} = $results->{agentID};
    foreach my $kpi (keys %{$results}) {
        if (defined($results->{$kpi}) && $results->{$kpi} !~ 'Unknown') {
            $self->{global}->{$kpi} = $results->{$kpi};
        }
    }
}

1;

__END__

=head1 MODE

Check agent radio statistics.

=over 8

=item B<--agent-id>

Set the ID of the agent (mandatory option).

=item B<--warning-snr-dbm>

Warning thresholds for signal noise ratio in dbm.

=item B<--critical-snr-dbm>

Critical thresholds for signal noise ratio in dbm.

=item B<--warning-rssi-dbm>

Warning thresholds for received signal strength indicator in dbm.

=item B<--critical-rssi-dbm>

Critical thresholds for received signal strength indicator in dbm.

=item B<--warning-rsrp-dbm>

Warning thresholds for reference signal receive power in dbm.

=item B<--critical-rsrp-dbm>

Critical thresholds for reference signal receive power in dbm.

=item B<--warning-rsrq-db>

Warning thresholds for reference signal receive quality in db.

=item B<--critical-rsrq-db>

Critical thresholds for reference signal receive quality in db.

=back

=cut
