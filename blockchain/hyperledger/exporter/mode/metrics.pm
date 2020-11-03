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

package blockchain::hyperledger::exporter::mode::metrics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::monitoring::openmetrics::scrape;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'peers', cb_prefix_output => 'prefix_output_block', type => 0 },
        { name => 'orderers', cb_prefix_output => 'prefix_output_transaction', type => 0 }
    ];

    $self->{maps_counters}->{peers} = [
        { label => 'peers-known', nlabel => 'peers.known.count', set => {
                key_values => [ { name => 'gossip_membership_total_peers_known', diff => 1 } ],
                output_template => 'Number of known peers: %s',
                perfdatas => [
                    { value => 'gossip_membership_total_peers_known', template => '%s', min => 0,
                      label_extra_instance => 1 },
                ],
            }
        },
        { label => 'endorsing-duration-avg', nlabel => 'endorser.propsal.duration.avg', set => {
                key_values => [ { name => 'endorser_propsal_duration_avg' } ],
                output_template => 'Average endorsing duration (ms) : %s',
                perfdatas => [
                    { value => 'endorser_propsal_duration_avg', template => '%s', min => 0,
                      label_extra_instance => 1 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{orderers} = [
        { label => 'orderers-connected', nlabel => 'consensus.etcdraft.active.nodes', set => {
                key_values => [ { name => 'consensus_etcdraft_active_nodes' } ],
                output_template => 'Connected orderers: %s',
                perfdatas => [
                    { value => 'consensus_etcdraft_active_nodes', template => '%s', min => 0,
                      label_extra_instance => 1 },
                ],
            }
        },
        { label => 'max-orderers', nlabel => 'consensus.etcdraft.cluster.size', set => {
                key_values => [ { name => 'consensus_etcdraft_cluster_size' } ],
                output_template => 'Max orderers: %s',
                perfdatas => [
                    { value => 'consensus_etcdraft_cluster_size', template => '%s', min => 0,
                      label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub channel_long_output {
    my ($self, %options) = @_;

    return "checking channel '" . $options{instance_value}->{display} . "'";
}

sub prefix_channel_output {
    my ($self, %options) = @_;

    return "channel '" . $options{instance_value}->{display} . "' ";
}

sub prefix_gscd_output {
    my ($self, %options) = @_;

    return 'time it takes to commit a block: ';
}

sub prefix_gpvd_output {
    my ($self, %options) = @_;

    return 'time it takes to validate a block: ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
         'filter-channel:s' => { name => 'filter_channel' },
    });

    return $self;
}

sub change_macros {
    my ($self, %options) = @_;

    $options{template} =~ s/%\{(.*?)\}/$options{dimensions}->{$1}/g;
    if (defined($options{escape})) {
        $options{template} =~ s/([\Q$options{escape}\E])/\\$1/g;
    }
    return $options{template};
}

sub search_metric {
    my ($self, %options) = @_;

    return if (!defined($options{metrics}->{$options{label}}));
    use Data::Dumper;

    print Dumper($foo, $bar);
    foreach (@{$options{metrics}->{$options{label}}->{data}}) {
        next if (!defined($_->{dimensions}->{$options{dimension}}));
        my $dimension = $_->{dimensions}->{$options{dimension}};
        next if (defined($self->{option_results}->{filter_channel}) && $self->{option_results}->{filter_channel} ne '' &&
            $dimension !~ /$self->{option_results}->{filter_channel}/);
        
        if (!defined($self->{channel}->{$dimension})) {
            $self->{channel}->{$dimension} = { display => $dimension };
        }
        $self->{channel}->{$dimension}->{$options{store}} = {} if (!defined($self->{channel}->{$dimension}->{$options{store}}));
        my $key = $self->change_macros(template => $options{key}, dimensions => $_->{dimensions});
        $self->{channel}->{$dimension}->{$options{store}}->{$key} = $_->{value};
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $metrics = centreon::common::monitoring::openmetrics::scrape::parse(%options, strip_chars => "[\"']");
    $self->{channel} = {};
    $self->search_metric(
        metrics => $metrics,
        label => 'gossip_membership_total_peers_known',
        dimension => 'channel',
        key => 'gossip_membership_total_peers_known',
        store => 'peers'
    );
    $self->search_metric(
        metrics => $metrics,
        label => 'consensus_etcdraft_active_nodes',
        dimension => 'channel',
        key => 'consensus_etcdraft_active_nodes',
        store => 'peers'
    );

    $self->search_metric(
        metrics => $metrics,
        label => 'consensus_etcdraft_cluster_size',
        dimension => 'channel',
        key => 'consensus_etcdraft_cluster_size',
        store => 'peers'
    );
    $self->search_metric(
        metrics => $metrics,
        label => 'gossip_privdata_validation_duration_count',
        dimension => 'channel',
        key => 'gossip_privdata_validation_duration_count',
        store => 'channel_gpvd'
    );

    $self->search_metric(
        metrics => $metrics,
        label => 'ledger_transaction_count',
        dimension => 'channel',
        key => 'ledger_transaction_count',
        store => 'channel_global'
    );
    $self->search_metric(
        metrics => $metrics,
        label => 'gossip_membership_total_peers_known',
        dimension => 'channel',
        key => 'gossip_membership_total_peers_known',
        store => 'channel_global'
    );
    $self->search_metric(
        metrics => $metrics,
        label => 'gossip_state_height',
        dimension => 'channel',
        key => 'gossip_state_height',
        store => 'channel_global'
    );
    $self->search_metric(
        metrics => $metrics,
        label => 'ledger_blockchain_height',
        dimension => 'channel',
        key => 'ledger_blockchain_height',
        store => 'channel_global'
    );

    $self->{cache_name} = 'hyperledger_' . $options{custom}->get_uuid()  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{hostname}) ? $self->{option_results}->{hostname} : 'me') . '_' .
        (defined($self->{option_results}->{port}) ? $self->{option_results}->{port} : 'default') . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_channel}) ? md5_hex($self->{option_results}->{filter_channel}) : md5_hex('all'));

}

1;

__END__

=head1 MODE

Check blockchain system.

=over 8

=item B<--filter-name>

Filter channel channel (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds. Use --list-counters to get available thresholds options.

=back

=cut
