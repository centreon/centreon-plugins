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
use bigint;
use Math::BigFloat;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'peers', cb_prefix_output => 'prefix_output_peer', type => 0 },
        { name => 'orderers', cb_prefix_output => 'prefix_output_orderer', type => 0 }
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
        { label => 'validation-duration-avg', nlabel => 'broadcast.validate.duration.avg', set => {
                key_values => [ { name => 'broadcast_validate_duration_avg' } ],
                output_template => 'Average endorsing duration (ms) : %s',
                perfdatas => [
                    { value => 'broadcast_validate_duration_avg', template => '%s', min => 0,
                      label_extra_instance => 1 },
                ],
            }
        },
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

    
    foreach my $data (@{$options{metrics}->{$options{label}}->{data}}) {
        print Dumper("data => " . $data);
        my $all_filters_ok = 1;
        foreach my $dimension (@{$options{dimensions}}) {
            $all_filters_ok = 0;
            print Dumper("Dimension > " . $dimension);
            print Dumper("data > " . $data);
            last if (!defined($data->{dimensions}->{$dimension}));
            my $dimension_value = $data->{dimensions}->{$dimension};
            print Dumper($dimension_value);
            my $filter = "filter" . $dimension;
            last if (defined($self->{option_results}->{$filter}) && $self->{option_results}->{$filter} ne '' &&
                 $dimension_value !~ /$self->{option_results}->{$filter}/);
            $all_filters_ok = 1
        }
        next if (!$all_filters_ok);
        
        # if (!defined($self->{channel}->{$dimension})) {
        #     $self->{channel}->{$dimension} = { display => $dimension };
        # }
        
        $self->{$options{store}} = {} if (!defined($self->{$options{store}}));
        my $key = $self->change_macros(template => $options{key}, dimensions => $data->{dimensions});
        print Dumper("key -> " . $key);
        print Dumper("value -> " . $key);
        $self->{$options{store}}->{$key} = $data->{value};
    }
}

sub search_calc_avg_metric {
    my ($self, %options) = @_;

    return if (!defined($options{metrics}->{$options{numerator}}));
    return if (!defined($options{metrics}->{$options{denominator}}));
    use Data::Dumper;

    my $numerator_value = undef;
    my $denominator_value = undef;
    foreach my $data (@{$options{metrics}->{$options{numerator}}->{data}}) {
        print Dumper("data => " . $data);
        my $all_filters_ok = 1;
        foreach my $dimension (@{$options{dimensions}}) {
            $all_filters_ok = 0;
            print Dumper("Dimension > " . $dimension);
            print Dumper("data > " . $data);
            last if (!defined($data->{dimensions}->{$dimension}));
            my $dimension_value = $data->{dimensions}->{$dimension};
            print Dumper($dimension_value);
            my $filter = "filter" . $dimension;
            last if (defined($self->{option_results}->{$filter}) && $self->{option_results}->{$filter} ne '' &&
                 $dimension_value !~ /$self->{option_results}->{$filter}/);
            $all_filters_ok = 1
        }
        next if (!$all_filters_ok);
        
        # if (!defined($self->{channel}->{$dimension})) {
        #     $self->{channel}->{$dimension} = { display => $dimension };
        # }
        $numerator_value = $data->{value};
        last;
    }
    return if ($numerator_value eq undef);

    foreach my $data (@{$options{metrics}->{$options{denominator}}->{data}}) {
        print Dumper("data => " . $data);
        my $all_filters_ok = 1;
        foreach my $dimension (@{$options{dimensions}}) {
            $all_filters_ok = 0;
            print Dumper("Dimension > " . $dimension);
            print Dumper("data > " . $data);
            last if (!defined($data->{dimensions}->{$dimension}));
            my $dimension_value = $data->{dimensions}->{$dimension};
            print Dumper($dimension_value);
            my $filter = "filter" . $dimension;
            last if (defined($self->{option_results}->{$filter}) && $self->{option_results}->{$filter} ne '' &&
                 $dimension_value !~ /$self->{option_results}->{$filter}/);
            $all_filters_ok = 1
        }
        next if (!$all_filters_ok);
        
        # if (!defined($self->{channel}->{$dimension})) {
        #     $self->{channel}->{$dimension} = { display => $dimension };
        # }
        $numerator_value = $data->{value};
        last;
    }
    return if ($numerator_value eq undef);

    $self->{$options{store}} = {} if (!defined($self->{$options{store}}));
    # my $key = $self->change_macros(template => $options{key}, dimensions => $data->{dimensions});
    print Dumper("key -> " . $options{key});
    print Dumper("value -> " . $options{key});
    $self->{$options{store}}->{$options{key}} = Math::BigFloat->new($numerator_value / $denominator_value);
    
}

sub manage_selection {
    my ($self, %options) = @_;

    my $metrics = centreon::common::monitoring::openmetrics::scrape::parse(%options, strip_chars => "[\"']");
    $self->{channel} = {};

    $self->search_metric(
        metrics => $metrics,
        label => 'gossip_membership_total_peers_known',
        dimensions =>  ("channel"),
        key => 'gossip_membership_total_peers_known',
        store => 'peers'
    );
    $self->search_metric(
        metrics => $metrics,
        label => 'consensus_etcdraft_active_nodes',
        dimensions =>  ('channel'),
        key => 'consensus_etcdraft_active_nodes',
        store => 'orderers'
    );

    $self->search_metric(
        metrics => $metrics,
        label => 'consensus_etcdraft_cluster_size',
        dimensions =>  ('channel'),
        key => 'consensus_etcdraft_cluster_size',
        store => 'orderers'
    );

    $self->search_calc_avg_metric(
        metrics => $metrics,
        dimensions =>  ('channel', 'status'),
        numerator => 'endorser_proposal_duration_sum',
        denominator => 'endorser_proposal_duration_count',
        key => 'endorser_propsal_duration_avg',
        store => 'peers'
    );

    $self->search_calc_avg_metric(
        metrics => $metrics,
        dimensions =>  ('channel', 'status', 'type'),
        numerator => 'broadcast_validate_duration_sum',
        denominator => 'broadcast_validate_duration_count',
        key => 'endorser_propsal_duration_avg',
        store => 'orderers'
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
