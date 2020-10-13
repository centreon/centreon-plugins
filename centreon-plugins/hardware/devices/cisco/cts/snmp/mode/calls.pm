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

package hardware::devices::cisco::cts::snmp::mode::calls;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_traffic_calc {
    my ($self, %options) = @_;

    if (!defined($options{delta_time})) {
        $self->{error_msg} = 'Buffer creation';
        return -1;
    }

    my $total_bytes = 0;
    foreach (keys %{$options{new_datas}}) {
        if (/\Q$self->{instance}\E_.*_bytes/) {
            my $new_bytes = $options{new_datas}->{$_};
            next if (!defined($options{old_datas}->{$_}));
            my $old_bytes = $options{old_datas}->{$_};
            my $bytes = $new_bytes - $old_bytes;
            $bytes = $new_bytes if ($bytes < 0);

            $total_bytes += $bytes;
        }
    }

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{traffic_per_seconds} = ($total_bytes * 8) / $options{delta_time};
    return 0;
}

sub custom_jitter_calc {
    my ($self, %options) = @_;

    my $max_jitter = 0;
    foreach (keys %{$options{new_datas}}) {
        if (/\Q$self->{instance}\E_.*_maxjitter/) {
            $max_jitter = $options{new_datas}->{$_} if ($options{new_datas}->{$_} > $max_jitter);
        }
    }

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{max_jitter} = $max_jitter;
    return 0;
}

sub custom_loss_calc {
    my ($self, %options) = @_;

    my ($total_loss, $total_pkts) = (0, 0);
    foreach (keys %{$options{new_datas}}) {
        if (/\Q$self->{instance}\E_.*_loss_$options{extra_options}->{label_ref}/) {
            my $new_loss = $options{new_datas}->{$_};
            next if (!defined($options{old_datas}->{$_}));
            my $old_loss = $options{old_datas}->{$_};
            my $loss = $new_loss - $old_loss;
            $loss = $new_loss if ($loss < 0);

            $total_loss += $loss;
        } elsif (/\Q$self->{instance}\E_.*_packets_$options{extra_options}->{label_ref}/) {
            my $new_pkts = $options{new_datas}->{$_};
            next if (!defined($options{old_datas}->{$_}));
            my $old_pkts = $options{old_datas}->{$_};
            my $pkts = $new_pkts - $old_pkts;
            $pkts = $new_pkts if ($pkts < 0);

            $total_pkts += $pkts;
        }
    }

    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{packets_loss} = $total_loss;
    $self->{result_values}->{packets_loss_prct} = 0;
    $self->{result_values}->{packets} = $total_pkts;
    if ($total_pkts > 0) {
        $self->{result_values}->{packets_loss_prct} = ($total_loss * 100) / $total_pkts;
    }

    return 0;
}

sub custom_loss_output {
    my ($self, %options) = @_;

    return sprintf(
        "packets %s loss: %.2f%% (%s on %s)",
        $self->{result_values}->{label},
        $self->{result_values}->{packets_loss_prct},
        $self->{result_values}->{packets_loss},
        $self->{result_values}->{packets}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Calls ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'streams_active', type => 1, cb_prefix_output => 'prefix_stream_active_output', message_multiple => 'All active call streams are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'dummy', threshold => 0, display_ok => 0, set => {
                key_values => [ { name => 'calls_instance_finished' } ],
                output_template => 'none',
                perfdatas => []
            }
        },
        { label => 'active', nlabel => 'calls.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => 'active: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'total', nlabel => 'calls.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    my @map = (
        ['total-unknown', 'unknown: %s', 'unknown'],
        ['total-other', 'other: %s', 'other'],
        ['total-internal-error', 'internal error: %s', 'internal.error'],
        ['total-local-disconnected', 'local disconnected: %s', 'local.disconnected'],
        ['total-remote-disconnected', 'remote disconnected: %s', 'remote.disconnected'],
        ['total-network-congestion', 'network congestion: %s', 'network.congestion'],
        ['total-media-negotiation-failure', 'media negotiation failure: %s', 'media.negotiation.failure'],
        ['total-security-config-mismatched', 'security config mismatched: %s', 'security.config.mismatched'],
        ['total-incompatible-remote-endpoint', 'incompatible remote endpoint: %s', 'incompatible.remote.endpoint'],
        ['total-service-unavailable', 'service unaivalable: %s', 'service.unavailable'],
        ['total-remote-terminated-error', 'remote terminated with error: %s', 'remote.terminated.error']
    );
    foreach (@map) {
        push @{$self->{maps_counters}->{global}}, { label => $_->[0], nlabel => 'calls.total.' . $_->[2] . '.count', display_ok => 0, set => {
                key_values => [ { name => $_->[2] } ],
                output_template => $_->[1],
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        };
    }

    $self->{maps_counters}->{streams_active} = [
        { label => 'streams-active-maxjitter', nlabel => 'calls.streams.active.maxjitter.milliseconds', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_jitter_calc'),
                output_template => 'max jitter: %s ms',
                output_use => 'max_jitter',  threshold_use => 'max_jitter',
                perfdatas => [
                    { value => 'max_jitter', template => '%d',
                      unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];

    foreach (('in', 'out')) {
        push @{$self->{maps_counters}->{streams_active}}, 
            { label => 'streams-active-traffic-' . $_, nlabel => 'calls.streams.active.traffic.' . $_ . '.bytes', set => {
                    key_values => [],
                    manual_keys => 1,
                    closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => $_ },
                    output_template => 'traffic ' . $_ . ': %s %s/s',
                    output_change_bytes => 1,
                    output_use => 'traffic_per_seconds',  threshold_use => 'traffic_per_seconds',
                    perfdatas => [
                        { value => 'traffic_per_seconds', template => '%d',
                          unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                    ]
                }
            },
            { label => 'streams-active-packetloss-' . $_, nlabel => 'calls.streams.active.packetloss.' . $_ . '.count', set => {
                    key_values => [],
                    manual_keys => 1,
                    closure_custom_calc => $self->can('custom_loss_calc'), closure_custom_calc_extra_options => { label_ref => $_ },
                    closure_custom_output => $self->can('custom_loss_output'),
                    threshold_use => 'packets_loss',
                    perfdatas => [
                        { value => 'packets_loss', template => '%d',
                          min => 0, label_extra_instance => 1, instance_use => 'display' }
                    ]
                }
            },
            { label => 'streams-active-packetloss-' . $_ . '-prct', nlabel => 'calls.streams.active.packetloss.' . $_ . '.percentage', display_ok => 0, set => {
                    key_values => [],
                    manual_keys => 1,
                    closure_custom_calc => $self->can('custom_loss_calc'), closure_custom_calc_extra_options => { label_ref => $_ },
                    closure_custom_output => $self->can('custom_loss_output'),
                    threshold_use => 'packets_loss_prct',
                    perfdatas => [
                        { value => 'packets_loss_prct', template => '%.2f',
                          unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                    ]
                }
            };
    }
}

sub prefix_stream_active_output {
    my ($self, %options) = @_;

    return "Stream '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $map_term_reason = {
    1 => 'unknown', 2 => 'other', 3 => 'internal.error',
    4 => 'local.disconnected', 5 => 'remote.disconnected',
    6 => 'network.congestion', 7 => 'media.negotiation.failure',
    8 => 'security.config.mismatched', 9 => 'incompatible.remote.endpoint',
    10 => 'service.unavailable', 11 => 'remote.terminated.error',
    12 => 'incall'
};
my $map_stream_type = {
    1 => 'video', 2 => 'audio', 3 => 'content'
};
my $oid_ctpcCallTermReason = '.1.3.6.1.4.1.9.9.644.1.4.8.1.17';

my $mapping = {
    traffic_out      => { oid => '.1.3.6.1.4.1.9.9.644.1.4.10.1.3' }, # ctpcTxTotalBytes
    packets_out      => { oid => '.1.3.6.1.4.1.9.9.644.1.4.10.1.4' }, # ctpcTxTotalPackets
    packets_lost_out => { oid => '.1.3.6.1.4.1.9.9.644.1.4.10.1.5' }, # ctpcTxLostPackets
    traffic_in       => { oid => '.1.3.6.1.4.1.9.9.644.1.4.10.1.11' }, # ctpcRxTotalBytes
    packets_in       => { oid => '.1.3.6.1.4.1.9.9.644.1.4.10.1.12' }, # ctpcRxTotalPackets
    packets_lost_in  => { oid => '.1.3.6.1.4.1.9.9.644.1.4.10.1.13' }, # ctpcRxLostPackets
    maxjitter        => { oid => '.1.3.6.1.4.1.9.9.644.1.4.10.1.25' }, # ctpcMaxCallJitter
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'cisco_cts_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    my $calls_instance_finished = $self->read_statefile_key(key => 'global_calls_instance_finished');
    $calls_instance_finished = {} if (!defined($calls_instance_finished));
    my $calls_instance_finished_new = {};

    my $active_calls = {};
    $self->{global} = { active => 0, total => 0 };
    foreach (values %$map_term_reason) {
        $self->{global}->{$_} = 0;
    }

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_ctpcCallTermReason
    );
    foreach (keys %$snmp_result) {
        /^$oid_ctpcCallTermReason\.(\d+)/;
        my $instance = $1;
        if ($map_term_reason->{ $snmp_result->{$_} } eq 'incall') {
            $active_calls->{$instance} = 1;
            $self->{global}->{active}++;
        } else {
            $calls_instance_finished_new->{$instance} = 1;
            next if (defined($calls_instance_finished->{$instance}));
            $self->{global}->{total}++;
            $self->{global}->{ $map_term_reason->{ $snmp_result->{$_} } }++;
        }
    }

    $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            map({ oid => $_->{oid} }, values(%$mapping))
        ],
        return_type => 1
    );

    $self->{streams_active} = {};
    foreach (('audio', 'video', 'content')) {
        $self->{streams_active}->{$_} = { display => $_ };
    }

    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{traffic_out}->{oid}\.(\d+)\.(\d+)\.(\d+)/);
        my ($index, $type, $source) = ($1, $2, $3);
        my $instance = $index . '.' . $type . '.' . $source;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        my $stream_type = $map_stream_type->{$type};
        if (defined($active_calls->{$index})) {
            $self->{streams_active}->{$stream_type}->{$instance . '_traffic_in'} = defined($result->{traffic_in}) ? $result->{traffic_in} : 0;
            $self->{streams_active}->{$stream_type}->{$instance . '_traffic_out'} = defined($result->{traffic_out}) ? $result->{traffic_out} : 0;
            $self->{streams_active}->{$stream_type}->{$instance . '_loss_in'} = defined($result->{packets_lost_in}) ? $result->{packets_lost_in} : 0;
            $self->{streams_active}->{$stream_type}->{$instance . '_packets_in'} = defined($result->{packets_in}) ? $result->{packets_in} : 0;
            $self->{streams_active}->{$stream_type}->{$instance . '_loss_out'} = defined($result->{packets_lost_out}) ? $result->{packets_lost_out} : 0;
            $self->{streams_active}->{$stream_type}->{$instance . '_packets_out'} = defined($result->{packets_out}) ? $result->{packets_out} : 0;
            $self->{streams_active}->{$stream_type}->{$instance . '_maxjitter'} = defined($result->{maxjitter}) ? $result->{maxjitter} : 0;
        }
    }

    $self->{global}->{calls_instance_finished} = $calls_instance_finished_new;
}

1;

__END__

=head1 MODE

Check call stream (real-time and history)

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'active', 'total', 'total-unknown',
'total-other', 'total-internal-error', 'total-local-disconnected', 'total-remote-disconnected',
'total-network-congestion', 'total-media-negotiation-failure', 'total-security-config-mismatched', 
'total-incompatible-remote-endpoint', 'total-service-unavailable', 'total-remote-terminated-error',
'streams-active-maxjitter',
'streams-active-traffic-in', 'streams-active-packetloss-in', 'streams-active-packetloss-in-prct',
'streams-active-traffic-out', 'streams-active-packetloss-out', 'streams-active-packetloss-out-prct'.

=back

=cut
