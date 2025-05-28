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

package apps::monitoring::latencetech::restapi::mode::connectivity;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'kpis', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All KPIs are OK', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{kpis} = [
        { label => 'tcp-response-time', nlabel => 'tcp.response.time.milliseconds', set => {
                key_values => [ { name => 'tcpMs' }, { name => 'display' } ],
                output_template => 'TCP Response Time: %.2fms',
                perfdatas => [
                    { value => 'tcpMs', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'udp-response-time', nlabel => 'udp.response.time.milliseconds', set => {
                key_values => [ { name => 'udpMs' }, { name => 'display' } ],
                output_template => 'UDP Response Time: %.2fms',
                perfdatas => [
                    { value => 'udpMs', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'http-response-time', nlabel => 'http.response.time.milliseconds', set => {
                key_values => [ { name => 'httpMs' }, { name => 'display' } ],
                output_template => 'HTTP Response Time: %.2fms',
                perfdatas => [
                    { value => 'httpMs', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'https-response-time', nlabel => 'https.response.time.milliseconds', set => {
                key_values => [ { name => 'httpsMs' }, { name => 'display' } ],
                output_template => 'HTTPS Response Time: %.2fms',
                perfdatas => [
                    { value => 'httpsMs', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'icmp-response-time', nlabel => 'icmp.response.time.milliseconds', set => {
                key_values => [ { name => 'icmpMs' }, { name => 'display' } ],
                output_template => 'ICMP Response Time: %.2fms',
                perfdatas => [
                    { value => 'icmpMs', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'twamp-response-time', nlabel => 'twamp.response.time.milliseconds', set => {
                key_values => [ { name => 'twampMs' }, { name => 'display' } ],
                output_template => 'TWAMP Response Time: %.2fms',
                perfdatas => [
                    { value => 'twampMs', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'download-bandwidth', nlabel => 'download.bandwidth.mbps', set => {
                key_values => [ { name => 'downloadThroughputMbps' }, { name => 'display' } ],
                output_template => 'DL bandwidth: %.2fMbps',
                perfdatas => [
                    { value => 'downloadThroughputMbps', template => '%.2f',
                      min => 0, unit => 'Mbps', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'upload-bandwidth', nlabel => 'upload.bandwidth.mbps', set => {
                key_values => [ { name => 'uploadThroughputMbps' }, { name => 'display' } ],
                output_template => 'UL bandwidth: %.2fMbps',
                perfdatas => [
                    { value => 'uploadThroughputMbps', template => '%.2f',
                      min => 0, unit => 'Mbps', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'jitter-time', nlabel => 'jitter.time.milliseconds', set => {
                key_values => [ { name => 'jitterMs' }, { name => 'display' } ],
                output_template => 'Jitter Time: %.2fms',
                perfdatas => [
                    { value => 'jitterMs', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'application-latency', nlabel => 'application.latency.milliseconds', set => {
                key_values => [ { name => 'applicationLatencyMs' }, { name => 'display' } ],
                output_template => 'Application latency: %.2fms',
                perfdatas => [
                    { value => 'applicationLatencyMs', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'network-latency', nlabel => 'network.latency.milliseconds', set => {
                key_values => [ { name => 'networkLatencyMs' }, { name => 'display' } ],
                output_template => 'Network latency: %.2fms',
                perfdatas => [
                    { value => 'networkLatencyMs', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'expected-latency', nlabel => 'expected.latency.milliseconds', set => {
                key_values => [ { name => 'expectedLatencyMS' }, { name => 'display' } ],
                output_template => 'Expected latency: %.2fms',
                perfdatas => [
                    { value => 'expectedLatencyMS', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'network-stability-percentage', nlabel => 'network.stability.percentage', set => {
                key_values => [ { name => 'networkStabilityPercent' }, { name => 'display' } ],
                output_template => 'Network stability: %.2f%%',
                perfdatas => [
                    { value => 'networkStabilityPercent', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'expected-stability', nlabel => 'expected.stability.percentage', set => {
                key_values => [ { name => 'expectedStabilityPercent' }, { name => 'display' } ],
                output_template => 'Expected stability: %.2f%%',
                perfdatas => [
                    { value => 'expectedStabilityPercent', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'volatility-percentage', nlabel => 'volatility.percentage', set => {
                key_values => [ { name => 'volatilityPercent' }, { name => 'display' } ],
                output_template => 'Volatility: %.2f%%',
                perfdatas => [
                    { value => 'volatilityPercent', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'qoe-rate', nlabel => 'qoe.rate.value', set => {
                key_values => [ { name => 'qualityOfExperience' }, { name => 'display' } ],
                output_template => 'Quality of Experience: %.3f',
                perfdatas => [
                    { value => 'qualityOfExperience', template => '%.3f',
                      min => 0, max => 5, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'packet-loss', nlabel => 'packetloss.rate.percentage', set => {
                key_values => [ { name => 'packetLossRatePercent' }, { name => 'display' } ],
                output_template => 'Packet loss rate: %.2f%%',
                perfdatas => [
                    { value => 'packetLossRatePercent', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'expected-packet-loss', nlabel => 'expected.packetloss.rate.percentage', set => {
                key_values => [ { name => 'expectedPacketLossPercent' }, { name => 'display' } ],
                output_template => 'Expected packet loss rate: %.2f%%',
                perfdatas => [
                    { value => 'expectedPacketLossPercent', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'connectivity-health',
            type => 2,
            warning_default => '%{connectivityHealth} =~ "Warning"',
            critical_default => '%{connectivityHealth} =~ "Need Attention"',
            set => {
                key_values => [ { name => 'connectivityHealth' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Agent '" . $options{instance_value}->{display} . "' ";
}

sub custom_status_output {
    my ($self, %options) = @_;

    return 'Connectivity health: "' . $self->{result_values}->{connectivityHealth} . '"';
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

    my $results = $options{custom}->request_api(endpoint => '/ci');
    foreach my $kpi (keys %{$results->{KPIs}}) {
        $self->{kpis}->{$results->{AgentID}}->{display} = $results->{AgentID} . '-' . $results->{Attributes}->{agentName};
        $self->{kpis}->{$results->{AgentID}}->{$kpi} = $results->{KPIs}->{$kpi};        
    }
}

1;

__END__

=head1 MODE

Check agent connectivity statistics.

=over 8

=item B<--agent-id>

Set the ID of the agent (mandatory option).

=item B<--warning-tcp-response-time>

Thresholds.

=item B<--critical-tcp-response-time>

Thresholds.

=item B<--warning-udp-response-time>

Thresholds.

=item B<--critical-udp-response-time>

Thresholds.

=item B<--warning-http-response-time>

Thresholds.

=item B<--critical-http-response-time>

Thresholds.

=item B<--warning-https-response-time>

Thresholds.

=item B<--critical-https-response-time>

Thresholds.

=item B<--warning-icmp-response-time>

Thresholds.

=item B<--critical-icmp-response-time>

Thresholds.

=item B<--warning-twamp-response-time>

Thresholds.

=item B<--critical-twamp-response-time>

Thresholds.

=item B<--warning-download-bandwidth>

Thresholds.

=item B<--critical-download-bandwidth>

Thresholds.

=item B<--warning-upload-bandwidth>

Thresholds.

=item B<--critical-upload-bandwidth>

Thresholds.

=item B<--warning-jitter-time>

Thresholds.

=item B<--critical-jitter-time>

Thresholds.

=item B<--warning-application-latency>

Thresholds.

=item B<--critical-application-latency>

Thresholds.

=item B<--warning-network-latency>

Thresholds.

=item B<--critical-network-latency>

Thresholds.

=item B<--warning-expected-latency>

Thresholds.

=item B<--critical-expected-latency>

Thresholds.

=item B<--warning-network-stability-percentage>

Thresholds.

=item B<--critical-network-stability-percentage>

Thresholds.

=item B<--warning-expected-stability>

Thresholds.

=item B<--critical-expected-stability>

Thresholds.

=item B<--warning-volatility-percentage>

Thresholds.

=item B<--critical-volatility-percentage>

Thresholds.

=item B<--warning-qoe-rate>

Thresholds.

=item B<--critical-qoe-rate>

Thresholds.

=item B<--warning-packet-loss>

Thresholds.

=item B<--critical-packet-loss>

Thresholds.

=item B<--warning-expected-packet-loss>

Thresholds.

=item B<--critical-expected-packet-loss>

Thresholds.

=item B<--warning-connectivity-health>

Define the conditions to match for the connectivity status to be WARNING.
(default: '%{connectivityHealth} =~ "Warning"').

=item B<--critical-connectivity-health>

Define the conditions to match for the connectivity status to be CRITICAL.
(default: '%{connectivityHealth} =~ "Need Attention"').

=back

=cut
