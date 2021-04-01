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

package blockchain::parity::restapi::mode::net;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'Listening status: %s ',
        $self->{result_values}->{listening},
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'network', cb_prefix_output => 'prefix_module_output', type => 0 },
    ];

    $self->{maps_counters}->{network} = [
       { label => 'peers', nlabel => 'parity.network.peers.count', set => {
                key_values => [ { name => 'peers' } ],
                output_template => "connected peers: %s ",
                perfdatas => [
                    { label => 'peer_count', value => 'peers', template => '%d', min => 0 }
                ],                
            }
        },
    ];
}

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

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

sub prefix_module_output {
    my ($self, %options) = @_;
    
    return "Parity network module: ";
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "parity_restapi_" . $self->{mode} . '_' . (defined($self->{option_results}->{hostname}) ? $self->{option_results}->{hostname} : 'me') . '_' .
       (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $query_form_post = [ { method => 'net_listening', params => [], id => "1", jsonrpc => "2.0" },
                            { method => 'net_peerCount', params => [], id => "2", jsonrpc => "2.0" } ];

    my $result = $options{custom}->request_api(method => 'POST', query_form_post => $query_form_post);

    my $peer_count = hex(@{$result}[1]->{result});

    $self->{network} = { peers => hex(@{$result}[1]->{result}) };

    $self->{output}->output_add(long_msg => "Node status: [is_listening: " . @{$result}[0]->{result} . ']', severity => 'OK');
}

1;

__END__

=head1 MODE

Check network module metrics parity (net_isListening, net_peerCount)