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

package blockchain::hyperledger::exporter::ledger::mode::metrics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::monitoring::openmetrics::scrape;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);


sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', cb_prefix_output => 'prefix_output_ledger', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
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

sub prefix_output_leger {
    my ($self, %options) = @_;

    return "Ledger metrics '";
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
        $self->{global}->{$options{key}} = 'no value';
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
    $self->{global} = {} if (!defined($self->{global}));

    $self->{global}->{$options{key}} = $value;
}

sub search_calc_avg_metric {
    my ($self, %options) = @_;

    if (!defined($options{metrics}->{$options{numerator}}) || !defined($options{metrics}->{$options{denominator}})) {
        $self->{global}->{$options{key}} = 'no value';
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

    $self->{global} = {} if (!defined($self->{global}));

    $self->{global}->{$options{key}} = $numerator_value / $denominator_value;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $metrics = centreon::common::monitoring::openmetrics::scrape::parse(%options, strip_chars => "[\"']");
    #$self->{channel} = {};
    my @channel = ("channel");
    my @chaincode_channel_transaction_type_validation_code = ('chaincode','channel','transaction_type','validation_code');

    $self->search_metric(
        metrics => $metrics,
        label => 'ledger_transaction_count',
        dimensions =>  \@chaincode_channel_transaction_type_validation_code,
        key => 'ledger_transaction_count' 
    );

    $self->search_metric(
        metrics => $metrics,
        label => 'ledger_blockchain_height',
        dimensions =>  \@channel,
        key => 'ledger_blockchain_height'
    ); 

    $self->search_calc_avg_metric(
        metrics => $metrics,
        dimensions =>  \@channel,
        numerator => 'ledger_block_processing_time_sum',
        denominator => 'ledger_block_processing_time_count',
        key => 'ledger_block_processing_time_avg'
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
