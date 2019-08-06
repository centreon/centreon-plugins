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

package cloud::vmware::velocloud::restapi::mode::linkusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'edges', type => 3, cb_prefix_output => 'prefix_edge_output', cb_long_output => 'long_output',
          message_multiple => 'All edges links usage are ok', indent_long_output => '    ',
            group => [
                { name => 'links', display_long => 1, cb_prefix_output => 'prefix_link_output',
                  message_multiple => 'All links status are ok', type => 1 },
            ]
        }
    ];

    $self->{maps_counters}->{links} = [
        { label => 'traffic-in', nlabel => 'link.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in' }, { name => 'display' }, { name => 'id' } ],
                output_change_bytes => 2,
                output_template => 'Traffic In: %s %s/s',
                perfdatas => [
                    { value => 'traffic_in_absolute', template => '%s',
                      min => 0, unit => 'b/s', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'traffic-out', nlabel => 'link.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out' }, { name => 'display' }, { name => 'id' } ],
                output_change_bytes => 2,
                output_template => 'Traffic Out: %s %s/s',
                perfdatas => [
                    { value => 'traffic_out_absolute', template => '%s',
                      min => 0, unit => 'b/s', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'latency-in', nlabel => 'link.latency.in.milliseconds', set => {
                key_values => [ { name => 'latency_in' }, { name => 'display' }, { name => 'id' } ],
                output_template => 'Latency In: %.2f ms',
                perfdatas => [
                    { value => 'latency_in_absolute', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'latency-out', nlabel => 'link.latency.out.milliseconds', set => {
                key_values => [ { name => 'latency_out' }, { name => 'display' }, { name => 'id' } ],
                output_template => 'Latency Out: %.2f ms',
                perfdatas => [
                    { value => 'latency_out_absolute', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'jitter-in', nlabel => 'link.jitter.in.milliseconds', set => {
                key_values => [ { name => 'jitter_in' }, { name => 'display' }, { name => 'id' } ],
                output_template => 'Jitter In: %.2f ms',
                perfdatas => [
                    { value => 'jitter_in_absolute', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'jitter-out', nlabel => 'link.jitter.out.milliseconds', set => {
                key_values => [ { name => 'jitter_out' }, { name => 'display' }, { name => 'id' } ],
                output_template => 'Jitter Out: %.2f ms',
                perfdatas => [
                    { value => 'jitter_out_absolute', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'packet-loss-in', nlabel => 'link.packet.loss.in.percentage', set => {
                key_values => [ { name => 'packet_loss_in' }, { name => 'display' }, { name => 'id' } ],
                output_template => 'Packet Loss In: %.2f%%',
                perfdatas => [
                    { value => 'packet_loss_in_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'packet-loss-out', nlabel => 'link.packet.loss.out.percentage', set => {
                key_values => [ { name => 'packet_loss_out' }, { name => 'display' }, { name => 'id' } ],
                output_template => 'Packet Loss Out: %.2f%%',
                perfdatas => [
                    { value => 'packet_loss_out_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1 },
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-edge-name:s"    => { name => 'filter_edge_name' },
        "filter-link-name:s"    => { name => 'filter_link_name' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{edges} = {};

    my $results = $options{custom}->list_edges;

    foreach my $edge (@{$results}) {
        if (defined($self->{option_results}->{filter_edge_name}) && $self->{option_results}->{filter_edge_name} ne '' &&
            $edge->{name} !~ /$self->{option_results}->{filter_edge_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $edge->{name} . "'.", debug => 1);
            next;
        }

        $self->{edges}->{$edge->{name}}->{id} = $edge->{id};
        $self->{edges}->{$edge->{name}}->{display} = $edge->{name};

        my $links = $options{custom}->get_links_metrics(
            edge_id => $edge->{id},
            timeframe => $self->{timeframe}
        );

        foreach my $link (@{$links}) {
            if (defined($self->{option_results}->{filter_link_name}) && $self->{option_results}->{filter_link_name} ne '' &&
                $link->{link}->{displayName} !~ /$self->{option_results}->{filter_link_name}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $edge->{id} . "'.", debug => 1);
                next;
            }

            $self->{edges}->{$edge->{name}}->{links}->{$link->{link}->{displayName}} = {
                id => $link->{linkId},
                display => $link->{link}->{displayName},
                traffic_out => int($link->{bytesTx} * 8 / $self->{timeframe}),
                traffic_in => int($link->{bytesRx} * 8 / $self->{timeframe}),
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
    foreach (keys %{$self->{edges}}) {
        last if (defined($self->{edges}->{$_}->{links}));
        $self->{output}->add_option_msg(short_msg => "No link found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check links usage per edges.

=over 8

=item B<--filter-edge-name>

Filter edge by name (Can be a regexp).

=item B<--filter-link-name>

Filter link by name (Can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'traffic-in', 'traffic-out', 'latency-in',
'latency-out', 'jitter-in', 'jitter-out',
'packet-loss-in', 'packet-loss-out'.

=item B<--critical-*>

Threshold critical.
Can be: 'traffic-in', 'traffic-out', 'latency-in',
'latency-out', 'jitter-in', 'jitter-out',
'packet-loss-in', 'packet-loss-out'.

=back

=cut
