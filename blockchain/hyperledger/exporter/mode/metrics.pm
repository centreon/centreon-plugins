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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);


sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'peers', cb_prefix_output => 'prefix_output_peer', type => 0 },
        { name => 'orderers', cb_prefix_output => 'prefix_output_orderer', type => 0 },
        { name => 'ledger', cb_prefix_output => 'prefix_output_ledger', type => 0 }
    ];

    $self->{maps_counters}->{ledger} = [
        { label => 'ledger-block-processing-time-avg', nlabel => 'ledger.block.processing.time.avg', set => {
                key_values => [ { name => 'ledger_block_processing_time_avg' }, 
                                { name => 'ledger_blockchain_height' },  { name => 'ledger_transaction_count' } ],
                closure_custom_output => $self->can('custom_ledger_output'),
                perfdatas => [
                    { value => 'ledger_block_processing_time_avg', template => '%s', min => 0,
                      label_extra_instance => 1 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{peers} = [
        { label => 'peer-known', nlabel => 'peers.known.count', set => {
                key_values => [ { name => 'gossip_membership_total_peers_known' } ],
                output_template => 'Number of known peers: %s',
                perfdatas => [
                    { value => 'gossip_membership_total_peers_known', template => '%s', min => 0,
                      label_extra_instance => 1 },
                ],
            }
        },
        { label => 'peer-endorsing-duration-avg', nlabel => 'endorser.propsal.duration.avg', set => {
                key_values => [ { name => 'endorser_propsal_duration_avg' }, { name => 'endorser_successful_proposals' }, { name => 'endorser_endorsement_failures' } ],
                closure_custom_output => $self->can('custom_endorser_output'),
                perfdatas => [
                    { value => 'endorser_propsal_duration_avg', template => '%s', min => 0,
                      label_extra_instance => 1 },
                ],
            }
        },
        { label => 'peer-gossip-state-commit-duration-avg', nlabel => 'gossip.state.commit.duration.avg', set => {
                key_values => [ { name => 'gossip_state_commit_duration_avg' } ],
                output_template => 'Average state commit duration (sec) : %s',
                perfdatas => [
                    { value => 'gossip_state_commit_duration_avg', template => '%s', min => 0,
                      label_extra_instance => 1 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{orderers} = [
        { label => 'orderer-validation-duration-avg', nlabel => 'broadcast.validate.duration.avg', set => {
                key_values => [ { name => 'broadcast_validate_duration_avg' },  { name => 'consensus_etcdraft_is_leader' }, { name => 'consensus_etcdraft_leader_changes' },
                 { name => 'broadcast_processed_count' } ],
                closure_custom_output => $self->can('custom_validation_output'),
                perfdatas => [
                    { value => 'broadcast_validate_duration_avg', template => '%s', min => 0,
                      label_extra_instance => 1 },
                ],
            }
        },
        { label => 'orderer-broadcast-enqueue-duration-avg', nlabel => 'broadcast.enqueue.duration.avg', set => {
                key_values => [ { name => 'broadcast_enqueue_duration_avg' } ],
                output_template => 'Average enqueue duration (sec) : %s',
                perfdatas => [
                    { value => 'broadcast_enqueue_duration_avg', template => '%s', min => 0,
                      label_extra_instance => 1 },
                ],
            }
        },
        { label => 'raft-orderers-active', nlabel => 'consensus.etcdraft.active.nodes', set => {
                key_values => [ { name => 'consensus_etcdraft_active_nodes' } ],
                output_template => 'Active orderers: %s',
                perfdatas => [
                    { value => 'consensus_etcdraft_active_nodes', template => '%s', min => 0,
                      label_extra_instance => 1 },
                ],
            }
        },
        { label => 'raft-orderers-max', nlabel => 'consensus.etcdraft.cluster.size', set => {
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

sub custom_validation_output {
    my ($self, %options) = @_;
    my $isLeader = ($self->{result_values}->{consensus_etcdraft_is_leader} == 0) ? "false" : "true";
    return sprintf(
            "Is leader: %s, Leader changes: %s, Blocks processed: %s, Average validate duration (sec) : %s",
            $isLeader,
            $self->{result_values}->{consensus_etcdraft_leader_changes},
            $self->{result_values}->{broadcast_processed_count},
            $self->{result_values}->{broadcast_validate_duration_avg}
    );
}

sub custom_endorser_output {
    my ($self, %options) = @_;

    return sprintf(
            "Average endorsing duration (sec) : %s, Endorsement success: %s, Endorsement failure : %s",
            $self->{result_values}->{endorser_propsal_duration_avg},
            $self->{result_values}->{endorser_successful_proposals},
            $self->{result_values}->{endorser_endorsement_failures}
    );
}

sub custom_ledger_output {
    my ($self, %options) = @_;

    return sprintf(
            "Average block processing duration (sec) : %s, Block count: %s, Transaction count: %s",
            $self->{result_values}->{ledger_block_processing_time_avg},
            $self->{result_values}->{ledger_blockchain_height},
            $self->{result_values}->{ledger_transaction_count}
    );
}

sub prefix_output_peer {
    my ($self, %options) = @_;

    return "Peer metrics '";
}

sub prefix_output_orderer {
    my ($self, %options) = @_;

    return "Orderer metrics '";
}
sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
         'filter-channel:s' => { name => 'filter_channel' },
         'filter-status:s' => { name => 'filter_status' },
         'filter-chaincode:s' => { name => 'filter_chaincode' },
         'filter-type:s' => { name => 'filter_type' },
         'filter-transaction-type:s' => { name => 'filter_transaction_type' },
         'filter-success:s' => { name => 'filter_success' },
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

    if (!defined($options{metrics}->{$options{label}})) {
        $self->{$options{store}}->{$options{key}} = 'no value';
        return;
    }

    my $value = undef;
    foreach my $data (@{$options{metrics}->{$options{label}}->{data}}) {
        my $all_filters_ok = 1;
        foreach my $dimension (@{$options{dimensions}}) {
            my $filter = "filter_" . $dimension;
            next if (!defined($self->{option_results}->{$filter}));
            $all_filters_ok = 0;
            last if (!defined($data->{dimensions}->{$dimension}));
            my $dimension_value = $data->{dimensions}->{$dimension};
            last if (defined($self->{option_results}->{$filter}) && $self->{option_results}->{$filter} ne '' &&
                 $dimension_value !~ /$self->{option_results}->{$filter}/);
            $all_filters_ok = 1
        }
        next if (!$all_filters_ok);
  
        $value = !defined($value) ? $data->{value} : $value + $data->{value};
    }
    $self->{$options{store}} = {} if (!defined($self->{$options{store}}));

    $self->{$options{store}}->{$options{key}} = $value;
}

sub search_calc_avg_metric {
    my ($self, %options) = @_;

    if (!defined($options{metrics}->{$options{numerator}}) || !defined($options{metrics}->{$options{denominator}})) {
        $self->{$options{store}}->{$options{key}} = 'no value';
        return;
    }

    my $numerator_value = undef;
    my $denominator_value = undef;
    foreach my $data (@{$options{metrics}->{$options{numerator}}->{data}}) {
        my $all_filters_ok = 1;
        foreach my $dimension (@{$options{dimensions}}) {
            my $filter = "filter_" . $dimension;
            next if (!defined($self->{option_results}->{$filter}));
            $all_filters_ok = 0;
            last if (!defined($data->{dimensions}->{$dimension}));
            my $dimension_value = $data->{dimensions}->{$dimension};
            last if (defined($self->{option_results}->{$filter}) && $self->{option_results}->{$filter} ne '' &&
                 $dimension_value !~ /$self->{option_results}->{$filter}/);
            $all_filters_ok = 1
        }
        next if (!$all_filters_ok);
  
        $numerator_value = !defined($numerator_value) ? $data->{value} : $numerator_value + $data->{value};
    }
    return if (!defined($numerator_value));

    foreach my $data (@{$options{metrics}->{$options{denominator}}->{data}}) {
        my $all_filters_ok = 1;
        foreach my $dimension (@{$options{dimensions}}) {
            my $filter = "filter_" . $dimension;
            next if (!defined($self->{option_results}->{$filter}));
            $all_filters_ok = 0;
            last if (!defined($data->{dimensions}->{$dimension}));
            my $dimension_value = $data->{dimensions}->{$dimension};
            last if (defined($self->{option_results}->{$filter}) && $self->{option_results}->{$filter} ne '' &&
                 $dimension_value !~ /$self->{option_results}->{$filter}/);
            $all_filters_ok = 1
        }
        next if (!$all_filters_ok);

        $denominator_value = !defined($denominator_value) ? $data->{value} : $denominator_value + $data->{value};
    }
    return if (!defined($denominator_value));

    $self->{$options{store}} = {} if (!defined($self->{$options{store}}));

    $self->{$options{store}}->{$options{key}} = $numerator_value / $denominator_value;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $metrics = centreon::common::monitoring::openmetrics::scrape::parse(%options, strip_chars => "[\"']");
    $self->{channel} = {};
    my @channel = ("channel");
    my @chaincode_channel_succes = ('chaincode', 'channel', 'success');
    my @chaincode_channel_transaction_type_validation_code = ('chaincode','channel','transaction_type','validation_code');
    my @channel_status_type = ('channel', 'status', 'type');
    my @no_dimension = ();

    $self->search_metric(
        metrics => $metrics,
        label => 'gossip_membership_total_peers_known',
        dimensions =>  \@channel,
        key => 'gossip_membership_total_peers_known',
        store => 'peers'
    );

    $self->search_metric(
        metrics => $metrics,
        label => 'endorser_successful_proposals',
        dimensions =>  \@no_dimension,
        key => 'endorser_successful_proposals',
        store => 'peers'
    );

    $self->search_metric(
        metrics => $metrics,
        label => 'endorser_endorsement_failures',
        dimensions =>  \@no_dimension,
        key => 'endorser_endorsement_failures',
        store => 'peers'
    );

    $self->search_metric(
        metrics => $metrics,
        label => 'consensus_etcdraft_active_nodes',
        dimensions =>  \@channel,
        key => 'consensus_etcdraft_active_nodes',
        store => 'orderers'
    );

    $self->search_metric(
        metrics => $metrics,
        label => 'consensus_etcdraft_cluster_size',
        dimensions =>  \@channel,
        key => 'consensus_etcdraft_cluster_size',
        store => 'orderers'
    );
    
    $self->search_metric(
        metrics => $metrics,
        label => 'consensus_etcdraft_is_leader',
        dimensions =>  \@channel,
        key => 'consensus_etcdraft_is_leader',
        store => 'orderers'
    );
    
    $self->search_metric(
        metrics => $metrics,
        label => 'consensus_etcdraft_leader_changes',
        dimensions =>  \@channel,
        key => 'consensus_etcdraft_leader_changes',
        store => 'orderers'
    );
    
    $self->search_metric(
        metrics => $metrics,
        label => 'broadcast_processed_count',
        dimensions =>  \@channel_status_type,
        key => 'broadcast_processed_count',
        store => 'orderers'
    );  

    $self->search_metric(
        metrics => $metrics,
        label => 'ledger_transaction_count',
        dimensions =>  \@chaincode_channel_transaction_type_validation_code,
        key => 'ledger_transaction_count',
        store => 'ledger'
    );

    $self->search_metric(
        metrics => $metrics,
        label => 'ledger_blockchain_height',
        dimensions =>  \@channel,
        key => 'ledger_blockchain_height',
        store => 'ledger'
    );

    $self->search_calc_avg_metric(
        metrics => $metrics,
        dimensions =>  \@chaincode_channel_succes,
        numerator => 'endorser_proposal_duration_sum',
        denominator => 'endorser_proposal_duration_count',
        key => 'endorser_propsal_duration_avg',
        store => 'peers'
    );
    
    $self->search_calc_avg_metric(
        metrics => $metrics,
        dimensions =>  \@channel,
        numerator => 'gossip_state_commit_duration_sum',
        denominator => 'gossip_state_commit_duration_count',
        key => 'gossip_state_commit_duration_avg',
        store => 'peers'
    );

    $self->search_calc_avg_metric(
        metrics => $metrics,
        dimensions =>  \@channel,
        numerator => 'ledger_block_processing_time_sum',
        denominator => 'ledger_block_processing_time_count',
        key => 'ledger_block_processing_time_avg',
        store => 'ledger'
    );

    $self->search_calc_avg_metric(
        metrics => $metrics,
        dimensions =>  \@channel_status_type ,
        numerator => 'broadcast_validate_duration_sum',
        denominator => 'broadcast_validate_duration_count',
        key => 'broadcast_validate_duration_avg',
        store => 'orderers'
    );

    $self->search_calc_avg_metric(
        metrics => $metrics,
        dimensions =>  \@channel_status_type ,
        numerator => 'broadcast_enqueue_duration_sum',
        denominator => 'broadcast_enqueue_duration_count',
        key => 'broadcast_enqueue_duration_avg',
        store => 'orderers'
    );

    $self->{cache_name} = 'hyperledger_' . $options{custom}->get_uuid()  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{hostname}) ? $self->{option_results}->{hostname}->[0] : 'me') . '_' .
        (defined($self->{option_results}->{port}) ? $self->{option_results}->{port}->[0] : 'default') . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_channel}) ? md5_hex($self->{option_results}->{filter_channel}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_status}) ? md5_hex($self->{option_results}->{filter_status}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_chaincode}) ? md5_hex($self->{option_results}->{filter_chaincode}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_success}) ? md5_hex($self->{option_results}->{filter_success}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_type}) ? md5_hex($self->{option_results}->{filter_type}) : md5_hex('all')). '_' .
        (defined($self->{option_results}->{filter_transaction_type}) ? md5_hex($self->{option_results}->{filter_transaction_type}) : md5_hex('all')) ;
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
