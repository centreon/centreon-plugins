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

package blockchain::parity::ethpoller::mode::stats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use bigint;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'block', cb_prefix_output => 'prefix_output_block', type => 0 },
        { name => 'transaction', cb_prefix_output => 'prefix_output_transaction', type => 0 }
    ];

    $self->{maps_counters}->{block} = [
       { label => 'block_freq', nlabel => 'parity.stats.block.frequency', set => {
                key_values => [ { name => 'block_freq' } ],
                output_template => "Block frequency: %d (block/min)",
                perfdatas => [
                    { label => 'block_freq', value => 'block_freq_absolute', template => '%d', min => 0 }
                ],                
            }
        }
    ];

    $self->{maps_counters}->{transaction} = [
       { label => 'transaction_freq', nlabel => 'parity.stats.transaction.frequency', set => {
                key_values => [ { name => 'transaction_freq' } ],
                output_template => "Transaction frequency: %d (tx/min)",
                perfdatas => [
                    { label => 'transaction_freq', value => 'transaction_freq_absolute', template => '%d', min => 0 }
                ],                
            }
        }
    ];
}

sub prefix_output_block {
    my ($self, %options) = @_;

    return "Block stats '";
}

sub prefix_output_fork {
    my ($self, %options) = @_;

    return "Fork stats '";
}

sub prefix_output_transaction {
    my ($self, %options) = @_;

    return "Transaction stats '";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s" => { name => 'filter_name' },
    });
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "parity_ethpoller_" . $self->{mode} . '_' . (defined($self->{option_results}->{hostname}) ? $self->{option_results}->{hostname} : 'me') . '_' .
       (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $result = $options{custom}->request_api(url_path => '/stats');

    my $old_block_timestamp = $self->{statefile_cache}->get(name => 'last_block_timestamp');
    my $old_block_count = $self->{statefile_cache}->get(name => 'last_block_count');

    my $old_tx_timestamp = $self->{statefile_cache}->get(name => 'last_tx_timestamp');
    my $old_tx_count = $self->{statefile_cache}->get(name => 'last_tx_count');

    my $datas = {};
    $datas->{last_block_timestamp} = time();
    $datas->{last_block_count} = $result->{block}->{count};

    $datas->{last_tx_timestamp} = time();
    $datas->{last_tx_count} = $result->{block}->{count};

    use Data::Dumper;
    print Dumper($old_tx_timestamp);

    my $res_timestamp = 0;

    if ($old_block_count && $old_block_timestamp) {
        $res_timestamp = $result->{block}->{timestamp} == 0 ? '' : $result->{block}->{timestamp};
        my $calculated_block_freq = ($result->{block}->{count} - $old_block_count) / (time() - $old_block_timestamp);
        $self->{block} = { block_freq => $calculated_block_freq };
        $self->{output}->output_add(severity  => 'OK', long_msg => 'Last block (#' . $result->{block}->{count} . ') was at ' . $res_timestamp);
    } else {
        $self->{output}->output_add(severity  => 'OK', long_msg => 'Last block (#' . $result->{block}->{block} . ') was at ' . $res_timestamp . '. Block frequency is being calculated...');
    }

    if ($old_tx_count && $old_tx_timestamp) {
        $res_timestamp = $result->{transaction}->{timestamp} == 0 ? '' : $result->{transaction}->{timestamp};
        my $calculated_tx_freq = ($result->{transaction}->{count} - $old_tx_count) / (time() - $old_tx_timestamp);
        $self->{transaction} = { transaction_freq => $calculated_tx_freq };
        $self->{output}->output_add(severity  => 'OK', long_msg => 'Last transaction (#' . $result->{transaction}->{count} . ') was at ' . $res_timestamp);
    } else {
        $self->{output}->output_add(severity  => 'OK', long_msg => 'Last transaction (#' . $result->{transaction}->{count} . ') was at ' . $res_timestamp . '. Transaction frequency is being calculated...');
    }

    if ($result->{fork}->{count} > 0) {
        $self->{output}->output_add(severity  => 'OK', long_msg => 'Last fork (#' . $result->{fork}->{count} . ') was at ' . $res_timestamp);   
    } else {
        $self->{output}->output_add(severity  => 'OK', long_msg => 'No fork occurence');
    }
}

1;

__END__

=head1 MODE

Check Parity eth-poller for stats 

=cut
