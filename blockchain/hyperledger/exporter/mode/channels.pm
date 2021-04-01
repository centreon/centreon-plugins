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

package blockchain::hyperledger::exporter::mode::channels;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::monitoring::openmetrics::scrape;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        {
            name => 'channel', type => 3, cb_prefix_output => 'prefix_channel_output', cb_long_output => 'channel_long_output', indent_long_output => '    ', message_multiple => 'All channels are ok',
            group => [
                { name => 'channel_global', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } },
                { name => 'channel_gscd', type => 0, cb_prefix_output => 'prefix_gscd_output', skipped_code => { -10 => 1 } },
                { name => 'channel_gpvd', type => 0, cb_prefix_output => 'prefix_gpvd_output',  skipped_code => { -10 => 1 } },
            ]
        }
    ];

    foreach ((
        ['gscd', 'gossip.state.commit', 'gossip_state_commit_duration'], 
        ['gpvd', 'gossip.privdata.validation', 'gossip_privdata_validation_duration']
    )) {
        $self->{maps_counters}->{'channel_' . $_->[0]} = [
            { label => $_->[0] . '-total', nlabel => 'channel.' . $_->[1] . '.total.count', set => {
                    key_values => [ { name => $_->[2] . '_count', diff => 1 } ],
                    output_template => '%s (total)',
                    perfdatas => [
                        { value => $_->[2] . '_count', template => '%s', min => 0,
                          label_extra_instance => 1 },
                    ],
                }
            }
        ];

        foreach my $label (('0.005', '0.01', '0.025', '0.05', '0.1', '0.25', '0.5', '1', '2.5', '5', '10', '+Inf')) {
            my $perf_label = $label;
            $perf_label =~ s/\+Inf/infinite/;
            push @{$self->{maps_counters}->{'channel_' . $_->[0]}},
            {
                label => $_->[0] . '-time-le-' . $perf_label, nlabel => 'channel.' . $_->[1] . '.time.le.' . $perf_label . '.count', set => {
                    key_values => [ { name => $_->[2] . '_bucket_' . $label, diff => 1 } ],
                    output_template => '%s (<= ' . $perf_label . ' sec)',
                    perfdatas => [
                        { value => $_->[2] . '_bucket_' . $label , template => '%s', min => 0,
                          label_extra_instance => 1 },
                    ],
                }
            };
        }
    }

    $self->{maps_counters}->{channel_global} = [
        { label => 'ledger-transaction', nlabel => 'channel.ledger.transaction.count', set => {
                key_values => [ { name => 'ledger_transaction_count', diff => 1 } ],
                output_template => 'number of transactions processed: %s',
                perfdatas => [
                    { value => 'ledger_transaction_count', template => '%s', min => 0,
                      label_extra_instance => 1 },
                ],
            }
        },
        { label => 'gossip-membership-total-peers-known', nlabel => 'channel.gossip.membership.total.peers.known.count', set => {
                key_values => [ { name => 'gossip_membership_total_peers_known' } ],
                output_template => 'total known peers: %s',
                perfdatas => [
                    { value => 'gossip_membership_total_peers_known', template => '%s', min => 0,
                      label_extra_instance => 1 },
                ],
            }
        },
        { label => 'gossip-state-height', nlabel => 'channel.gossip.state.height.count', set => {
                key_values => [ { name => 'gossip_state_height' } ],
                output_template => 'current ledger height: %s',
                perfdatas => [
                    { value => 'gossip_state_height', template => '%s', min => 0,
                      label_extra_instance => 1 },
                ],
            }
        },
        { label => 'ledger-blockchain-height', nlabel => 'channel.ledger.blockchain.height.count', set => {
                key_values => [ { name => 'ledger_blockchain_height' } ],
                output_template => 'height of the chain in blocks: %s',
                perfdatas => [
                    { value => 'ledger_blockchain_height', template => '%s', min => 0,
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
        label => 'gossip_state_commit_duration_bucket',
        dimension => 'channel',
        key => 'gossip_state_commit_duration_bucket_%{le}',
        store => 'channel_gscd'
    );
    $self->search_metric(
        metrics => $metrics,
        label => 'gossip_state_commit_duration_count',
        dimension => 'channel',
        key => 'gossip_state_commit_duration_count',
        store => 'channel_gscd'
    );

    $self->search_metric(
        metrics => $metrics,
        label => 'gossip_privdata_validation_duration_bucket',
        dimension => 'channel',
        key => 'gossip_privdata_validation_duration_bucket_%{le}',
        store => 'channel_gpvd'
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
