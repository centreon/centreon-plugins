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
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', cb_prefix_output => 'prefix_module_output', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
       { label => 'stats_blockInterval', nlabel => 'parity.stats.block.interval', set => {
                key_values => [ { name => 'stats_blockInterval' } ],
                output_template => "Block interval: %d ",
                perfdatas => [
                    { label => 'stats_blockInterval', value => 'stats_blockInterval_absolute', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'stats_contracts', nlabel => 'eth.poller.stats.contracts.number', set => {
                key_values => [ { name => 'stats_contracts' } ],
                output_template => "Cumulative contracts: %d ",
                perfdatas => [
                    { label => 'stats_contracts', value => 'stats_contracts_absolute', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'stats_blocks', nlabel => 'eth.poller.stats.blocks.number', set => {
                key_values => [ { name => 'stats_blocks' } ],
                output_template => "Cumulative blocks: %d ",
                perfdatas => [
                    { label => 'stats_blocks', value => 'stats_blocks_absolute', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'stats_transactions', nlabel => 'eth.poller.stats.transactions.number', set => {
                key_values => [ { name => 'stats_transactions' } ],
                output_template => "Cumulative transactions: %d ",
                perfdatas => [
                    { label => 'stats_transactions', value => 'stats_transactions_absolute', template => '%d', min => 0 }
                ],                
            }
        },
    ];

}

sub prefix_output {
    my ($self, %options) = @_;

    return "Stats '";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s" => { name => 'filter_name' },
    });
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(url_path => '/stats');

    # use Data::Dumper;
    # print Dumper($result);

    $self->{global} = { stats_blockInterval => $result->{blockInterval},
                        stats_contracts => $result->{cumulative}->{contracts},
                        stats_blocks => $result->{cumulative}->{blocks},
                        stats_transactions => $result->{cumulative}->{transactions}
                         };
}

1;

__END__

=head1 MODE

Check Parity eth-poller for accounts tracking

=cut
