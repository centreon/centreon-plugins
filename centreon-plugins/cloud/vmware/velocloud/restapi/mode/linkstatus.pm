#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package cloud::vmware::velocloud::restapi::mode::linkstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("Status is '%s', VPN State is '%s'",
        $self->{result_values}->{state}, $self->{result_values}->{vpn_state});
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{interface} = $options{new_datas}->{$self->{instance} . '_interface'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{vpn_state} = $options{new_datas}->{$self->{instance} . '_vpn_state'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'edges', type => 3, cb_prefix_output => 'prefix_edge_output', cb_long_output => 'long_output',
          message_multiple => 'All edges links are ok', indent_long_output => '    ',
            group => [
                { name => 'links', display_long => 1, cb_prefix_output => 'prefix_link_output',
                  message_multiple => 'All links status are ok', type => 1 },
            ]
        }
    ];

    $self->{maps_counters}->{links} = [
        { label => 'status', set => {
                key_values => [ { name => 'interface' }, { name => 'state' }, { name => 'vpn_state' },
                    { name => 'display' }, { name => 'id' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'traffic-in', nlabel => 'link.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in' }, { name => 'id' } ],
                output_template => 'Traffic In: %s %s/s',
                perfdatas => [
                    { value => 'traffic_in_absolute', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'id_absolute' },
                ],
            }
        },
        { label => 'traffic-out', nlabel => 'link.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out' }, { name => 'id' } ],
                output_template => 'Traffic Out: %s %s/s',
                perfdatas => [
                    { value => 'traffic_out_absolute', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'id_absolute' },
                ],
            }
        },
        { label => 'latency-in', nlabel => 'link.latency.in.milliseconds', set => {
                key_values => [ { name => 'latency_in' }, { name => 'id' } ],
                output_template => 'Latency In: %.2f ms',
                perfdatas => [
                    { value => 'latency_in_absolute', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'id_absolute' },
                ],
            }
        },
        { label => 'latency-out', nlabel => 'link.latency.out.milliseconds', set => {
                key_values => [ { name => 'latency_out' }, { name => 'id' } ],
                output_template => 'Latency Out: %.2f ms',
                perfdatas => [
                    { value => 'latency_out_absolute', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'id_absolute' },
                ],
            }
        },
        { label => 'jitter-in', nlabel => 'link.jitter.in.milliseconds', set => {
                key_values => [ { name => 'jitter_in' }, { name => 'id' } ],
                output_template => 'Jitter In: %.2f ms',
                perfdatas => [
                    { value => 'jitter_in_absolute', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'id_absolute' },
                ],
            }
        },
        { label => 'jitter-out', nlabel => 'link.jitter.out.milliseconds', set => {
                key_values => [ { name => 'jitter_out' }, { name => 'id' } ],
                output_template => 'Jitter Out: %.2f ms',
                perfdatas => [
                    { value => 'jitter_out_absolute', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'id_absolute' },
                ],
            }
        },
        { label => 'packet-loss-in', nlabel => 'link.packet.loss.in.percentage', set => {
                key_values => [ { name => 'packet_loss_in' }, { name => 'id' } ],
                output_template => 'Packet Loss In: %.2f%%',
                perfdatas => [
                    { value => 'packet_loss_in_absolute', template => '%.2f',
                      min => 0, unit => '%', label_extra_instance => 1, instance_use => 'id_absolute' },
                ],
            }
        },
        { label => 'packet-loss-out', nlabel => 'link.packet.loss.out.percentage', set => {
                key_values => [ { name => 'packet_loss_out' }, { name => 'id' } ],
                output_template => 'Packet Loss Out: %.2f%%',
                perfdatas => [
                    { value => 'packet_loss_out_absolute', template => '%.2f',
                      min => 0, unit => '%', label_extra_instance => 1, instance_use => 'id_absolute' },
                ],
            }
        },
    ];
}

sub prefix_edge_output {
    my ($self, %options) = @_;

    return "Edge '" . $options{instance_value}->{display} . "' ";
}

sub prefix_link_output {
    my ($self, %options) = @_;
    
    return "Link '" . $options{instance_value}->{display} . "' [Id: " . $options{instance_value}->{id} . "] ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking edge '" . $options{instance_value}->{display} . "' [Id: " . $options{instance_value}->{id} . "] ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-edge-name:s"    => { name => 'filter_edge_name' },
        "filter-edge-id:s"      => { name => 'filter_edge_id' },
        "filter-link-id:s"      => { name => 'filter_link_id' },
        "warning-status:s"      => { name => 'warning_status', default => '' },
        "critical-status:s"     => { name => 'critical_status', default => '' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{edges} = {};

    $self->{cache_name} = "velocloud_" . $self->{mode} . '_' . $options{custom}->get_connection_infos()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_id}) ? md5_hex($self->{option_results}->{filter_id}) : md5_hex('all'));

    my $results = $options{custom}->list_edges;

    foreach my $edge (@{$results}) {
        if (defined($self->{option_results}->{filter_edge_name}) && $self->{option_results}->{filter_edge_name} ne '' &&
            $edge->{name} !~ /$self->{option_results}->{filter_edge_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $edge->{name} . "'.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_edge_id}) && $self->{option_results}->{filter_edge_id} ne '' &&
            $edge->{id} !~ /$self->{option_results}->{filter_edge_id}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $edge->{id} . "'.", debug => 1);
            next;
        }

        $self->{edges}->{$edge->{id}}->{id} = $edge->{id};
        $self->{edges}->{$edge->{id}}->{display} = $edge->{name};

        my $links = $options{custom}->list_links(edge_id => $edge->{id});

        foreach my $link (@{$links}) {
            if (defined($self->{option_results}->{filter_link_id}) && $self->{option_results}->{filter_link_id} ne '' &&
                $link->{linkId} !~ /$self->{option_results}->{filter_link_id}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $edge->{id} . "'.", debug => 1);
                next;
            }

            $self->{edges}->{$edge->{id}}->{links}->{$link->{linkId}} = {
                display => $link->{link}->{displayName},
                id => $link->{linkId},
                interface => $link->{link}->{interface},
                state => $link->{link}->{state},
                vpn_state => $link->{link}->{vpnState},
                traffic_out => $link->{bytesTx} * 8,
                traffic_in => $link->{bytesRx} * 8,
                latency_out => $link->{bestLatencyMsTx},
                latency_in => $link->{bestLatencyMsRx},
                jitter_out => $link->{bestJitterMsTx},
                jitter_in => $link->{bestJitterMsRx},
                packet_loss_out => $link->{bestLossPctTx},
                packet_loss_in => $link->{bestLossPctRx},
            };
        }
    }

    if (scalar(keys %{$self->{edges}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No edge found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check edge links.

=over 8

=item B<--filter-edge-name>

Filter edge by name (Can be a regexp).

=item B<--filter-edge-id>

Filter edge by id (Can be a regexp).

=item B<--filter-link-id>

Filter link by id (Can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}, %{vpn_state}.

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{state}, %{vpn_state}.

=item B<--warning-*>

Threshold warning.
Can be: 'traffic-in', 'traffic-out'.

=item B<--critical-*>

Threshold critical.
Can be: 'traffic-in', 'traffic-out'.

=back

=cut
