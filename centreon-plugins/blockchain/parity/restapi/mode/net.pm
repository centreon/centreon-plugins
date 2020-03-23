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

package blockchain::parity::restapi::mode::net;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
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
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'listening' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'peers', nlabel => 'parity.network.peers.count', set => {
                key_values => [ { name => 'peers' } ],
                output_template => "connected peers: %s ",
                perfdatas => [
                    { label => 'peer_count', value => 'peers_absolute', template => '%d', min => 0 }
                ],                
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
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

    my $query_form_post_listening = { method => 'net_listening', params => [],  id => "1", jsonrpc => "2.0" };
    my $result_listening = $options{custom}->request_api(method => 'POST', query_form_post => $query_form_post_listening);
    
    my $query_form_post_peer = { method => 'net_peerCount', params => [],  id => "1", jsonrpc => "2.0" };
    my $result_peer = $options{custom}->request_api(method => 'POST', query_form_post => $query_form_post_peer);

    $self->{network} = { listening => $result_listening->{result},
                         peers => hex($result_peer->{result}) }
    
}

1;

__END__

=head1 MODE

Check network module metrics parity (net_isListening, net_peerCount)

=over 8

=item B<--unknown-status>

Set unknown threshold for listening status (Default: '').

=item B<--warning-status>

Set warning threshold for listening status (Default: '').

=item B<--critical-status>

Set critical threshold for listening status (Default: '%{listening} !~ /true/').

=item B<--warning-peers> B<--critical-peers>

Warning and Critical threhsold on the number of peer

=back

=cut
