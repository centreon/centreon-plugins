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

package blockchain::parity::ethpoller::mode::fork;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{listening} !~ /true/' },
    });
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "parity_ethpoller_" . $self->{mode} . '_' . (defined($self->{option_results}->{hostname}) ? $self->{option_results}->{hostname} : 'me') . '_' .
       (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $result = $options{custom}->request_api(url_path => '/fork');
   
    # use Data::Dumper;
    # print Dumper($result);
   
    # Unix time conversion
    my $res_timestamp = localtime(hex($result->{last_update}->{timestamp}));  

    # Alerts management 
    # my $cache = Cache::File->new( cache_root => './parity-eth-poller-cache' );

    # if (my $cached_timestamp = $cache->get('fork_timestamp')) {
    #     if ($cached_timestamp ne $res_timestamp) {
    #         #alert
    #     }
    # } else {
    #     $cache->set('fork_timestamp', $res_timestamp);
    # }

    $self->{output}->output_add(severity  => 'OK', long_msg => 'Fork: [fork_timestamp: ' . $res_timestamp . 
                            '] [fork_occurence: ' . $result->{occurence} . '] [fork_blockNumber: ' . $result->{last_update}->{blockNumber} . 
                            '] [fork_in: ' . $result->{last_update}->{in} . '] [fork_out: ' . $result->{last_update}->{out} . ']');

}

1;

__END__

=head1 MODE

Check Parity eth-poller for forks details

=over 8

=item B<--unknown-status>

Set unknown threshold for listening status (Default: '').

=item B<--warning-status>

Set warning threshold for listening status (Default: '').

=item B<--critical-status>

Set critical threshold for listening status (Default: '%{is_mining} !~ /true/').

=item B<--warning-peers> B<--critical-peers>

Warning and Critical threhsold on the number of peer

=back

=cut
