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

package blockchain::parity::ethpoller::mode::watchlist;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

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

    my $results = $options{custom}->request_api(url_path => '/watchlist');

    # use Data::Dumper;
    # print Dumper($results);

    # Alerts management 
    # my $cache = Cache::File->new( cache_root => './parity-eth-poller-cache' );

    foreach my $account (@{$results->{Accounts}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $account->{id} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $account->{id} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{output}->output_add(severity  => 'OK', long_msg => 'Account ' . $account->{id} . ': [label: ' . $account->{label} . '] [nonce: ' . $account->{nonce} .
                            '] [timestamp: ' . localtime(hex($account->{last_update}->{timestamp})) . '] [blockNumber: ' . $account->{last_update}->{blockNumber} . 
                            '] [receiver: ' . $account->{last_update}->{receiver} . '] [value: ' . $account->{last_update}->{value} . ']' );
    }

    foreach my $minner (@{$results->{Miners}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $minner->{id} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $minner->{id} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{output}->output_add(severity  => 'OK', long_msg => 'Minner ' . $minner->{id} . ': [label: ' . $minner->{label} . '] [blocks: ' . $minner->{blocks} .
                            '] [timestamp: ' . localtime(hex($minner->{last_update}->{timestamp})) . '] [blockNumber: ' . $minner->{last_update}->{blockNumber}  . ']');
    }
    
    foreach my $contract (@{$results->{Constracts}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $contract->{id} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $contract->{id} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{output}->output_add(severity  => 'OK', long_msg => 'Contract ' . $contract->{id} . ': [label: ' . $contract->{label} . '] [balance: ' . $contract->{balance} .
                            '] [timestamp: ' . localtime(hex($contract->{last_update}->{timestamp})) . '] [blockNumber: ' . $contract->{last_update}->{blockNumber} . 
                            '] [sender: ' . $contract->{last_update}->{sender} . '] [value: ' . $contract->{last_update}->{value} . ']');

        # if (my $cached_balance = $cache->get('contract_balance_' . $contract->{id})) {
        #     if ($cached_balance != $contract->{balance}) {
        #         #alert
        #     }
        # } else {
        #     $cache->set('contract_balance_' . $contract->{id}, $contract->{balance});
        # }

    }

    foreach my $function (@{$results->{Functions}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $function->{id} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $function->{id} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{output}->output_add(severity  => 'OK', long_msg => '[Function ' . $function->{id} . ']: label: ' . $function->{label} . '] [calls: ' . $function->{calls} .
                            '] [timestamp: ' . localtime(hex($function->{last_update}->{timestamp})) . '] [blockNumber: ' . $function->{last_update}->{blockNumber} . 
                            '] [sender: ' . $function->{last_update}->{sender} . '] [receiver: ' . $function->{last_update}->{receiver} . 
                            '] [value: ' . $function->{last_update}->{value}  . ']');
    }

     foreach my $event (@{$results->{Events}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $event->{id} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $event->{id} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{output}->output_add(severity  => 'OK', long_msg => '[Event ' . $event->{id} . ']: label: ' . $event->{label} . '] [calls: ' . $event->{calls} .
                            '] [timestamp: ' . localtime(hex($event->{last_update}->{timestamp})) . '] [blockNumber: ' . $event->{last_update}->{blockNumber} . 
                            '] [sender: ' . $event->{last_update}->{sender} . '] [receiver: ' . $event->{last_update}->{receiver} . ']');
    }

}

1;

__END__

=head1 MODE

Check Parity eth-poller for accounts tracking

=cut
