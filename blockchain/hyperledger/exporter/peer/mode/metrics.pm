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

package blockchain::hyperledger::exporter::peer::mode::metrics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::monitoring::openmetrics::scrape;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);


sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'peer', cb_prefix_output => 'prefix_output_peer', type => 0 },
        { name => 'duration', cb_prefix_output => 'prefix_output_peer', type => 0 }
    ];

    $self->{maps_counters}->{peer} = [
        { label => 'peer-known', nlabel => 'peers.known.count', set => {
                key_values => [ { name => 'gossip_membership_total_peers_known' } ],
                output_template => 'Number of known peers: %s',
                perfdatas => [
                    { value => 'gossip_membership_total_peers_known', template => '%s', min => 0,
                      label_extra_instance => 1 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{duration} = [
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

sub prefix_output_peer {
    my ($self, %options) = @_;

    return "Peer metrics '";
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
    my @channel = ("channel");
    my @chaincode_channel_succes = ('chaincode', 'channel', 'success');
    my @no_dimension = ();

    $self->search_metric(
        metrics => $metrics,
        label => 'gossip_membership_total_peers_known',
        dimensions =>  \@channel,
        key => 'gossip_membership_total_peers_known',
        store => 'peer'
    );

    $self->search_metric(
        metrics => $metrics,
        label => 'endorser_successful_proposals',
        dimensions =>  \@no_dimension,
        key => 'endorser_successful_proposals',
        store => 'duration'
    );

    $self->search_metric(
        metrics => $metrics,
        label => 'endorser_endorsement_failures',
        dimensions =>  \@no_dimension,
        key => 'endorser_endorsement_failures',
        store => 'duration'
    );

    $self->search_calc_avg_metric(
        metrics => $metrics,
        dimensions =>  \@chaincode_channel_succes,
        numerator => 'endorser_proposal_duration_sum',
        denominator => 'endorser_proposal_duration_count',
        key => 'endorser_propsal_duration_avg',
        store => 'duration'
    );
    
    $self->search_calc_avg_metric(
        metrics => $metrics,
        dimensions =>  \@channel,
        numerator => 'gossip_state_commit_duration_sum',
        denominator => 'gossip_state_commit_duration_count',
        key => 'gossip_state_commit_duration_avg',
        store => 'duration'
    );


    $self->{cache_name} = 'hyperledger_' . $options{custom}->get_uuid()  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) ;
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
