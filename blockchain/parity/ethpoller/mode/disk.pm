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

package blockchain::parity::ethpoller::mode::disk;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use bigint;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', cb_prefix_output => 'prefix_module_output', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
       { label => 'disk-free', nlabel => 'eth.poller.disk.free', set => {
                key_values => [ { name => 'disk_free' } ],
                output_template => "Disk free: %d ",
                perfdatas => [
                    { label => 'disk_free', value => 'disk_free', unit => 'B', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'disk-available', nlabel => 'eth.poller.disk.available', set => {
                key_values => [ { name => 'disk_available' } ],
                output_template => "Disk available: %d ",
                perfdatas => [
                    { label => 'disk_available', value => 'disk_available', unit => 'B', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'disk-size', nlabel => 'eth.poller.disk.size', set => {
                key_values => [ { name => 'disk_size' } ],
                output_template => "Disk size: %d ",
                perfdatas => [
                    { label => 'disk_size', value => 'disk_size', template => '%d', unit => 'B', min => 0 }
                ],                
            }
        },
        { label => 'disk-used', nlabel => 'eth.poller.disk.used', set => {
                key_values => [ { name => 'disk_used' } ],
                output_template => "Disk used: %d ",
                perfdatas => [
                    { label => 'disk_used', value => 'disk_used', template => '%d', unit => 'B', min => 0 }
                ],                
            }
        },
        { label => 'disk-usage', nlabel => 'eth.poller.disk.usage', set => {
                key_values => [ { name => 'disk_usage' } ],
                output_template => "Disk usage: %d %%",
                perfdatas => [
                    { label => 'disk_usage', value => 'disk_usage', template => '%.2f', unit => '%', min => 0 }
                ],                
            }
        },
        { label => 'blockchain-dir', nlabel => 'eth.poller.blockchain.directory', set => {
                key_values => [ { name => 'blockchain_dir' } ],
                output_template => "Blockchain directory: %d",
                perfdatas => [
                    { label => 'blockchain_dir', value => 'blockchain_dir', unit => 'B', template => '%d', min => 0 }
                ],                
            }
        }
    ];

}

sub prefix_output {
    my ($self, %options) = @_;

    return "Disk '";
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

    my $result = $options{custom}->request_api(url_path => '/disk');

    $self->{global} = { disk_free => $result->{free},
                        disk_available => $result->{available},
                        disk_size => $result->{size},
                        disk_used => $result->{used},
                        disk_usage => $result->{usage},
                        blockchain_dir => $result->{dir}
                         };

    $self->{output}->output_add(severity  => 'OK', long_msg => 'Ledger: ' . $result->{dir} . ' (' . $result->{usage} . '%)');
}

1;

__END__

=head1 MODE

Check Parity eth-poller for disk monitoring

=cut
