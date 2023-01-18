#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package apps::monitoring::ntopng::restapi::mode::netflowhealth;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_alerted_output {
    my ($self, %options) = @_;

    return sprintf(
        '%s flows (%s with alerts - %.2f%%)',
        $self->{result_values}->{flows},
        $self->{result_values}->{alertedFlows},
        $self->{result_values}->{alertedFlowsPrct}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'flows-detected', nlabel => 'flows.detected.count', display_ok => 0, set => {
                key_values => [ { name => 'flows' } ],
                output_template => 'number of flows: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'flows-alerted-detected', nlabel => 'flows.alerted.detected.count', display_ok => 0, set => {
                key_values => [ { name => 'alertedFlows' } ],
                output_template => 'number of alerted flows: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'flows-alerted-prct', nlabel => 'flows.alerted.percentage', set => {
                key_values => [ { name => 'alertedFlowsPrct' }, { name => 'alertedFlows' }, { name => 'flows' } ],
                closure_custom_output => $self->can('custom_alerted_output'),
                perfdatas => [
                    { template => '%s', unit => '%', min => 0, max => 100 }
                ]
            }
        },
        { label => 'packets-download', nlabel => 'packets.download.persecond', display_ok => 0, set => {
                key_values => [ { name => 'packetsDownload', per_second => 1 } ],
                output_template => 'packets download: %.2f/s',
                perfdatas => [
                    { template => '%.2f', unit => '/s', min => 0 }
                ]
            }
        },
        { label => 'packets-upload', nlabel => 'packets.upload.persecond', display_ok => 0, set => {
                key_values => [ { name => 'packetsUpload', per_second => 1 } ],
                output_template => 'packets upload: %.2f/s',
                perfdatas => [
                    { template => '%.2f', unit => '/s', min => 0 }
                ]
            }
        },
        { label => 'packets-dropped', nlabel => 'packets.dropped.persecond', display_ok => 0, set => {
                key_values => [ { name => 'packetsDropped', per_second => 1 } ],
                output_template => 'packets dropped: %.2f/s',
                perfdatas => [
                    { template => '%.2f', unit => '/s', min => 0 }
                ]
            }
        },
        { label => 'traffic-in', nlabel => 'traffic.in.bitspersecond', display_ok => 0, set => {
                key_values => [ { name => 'bytesDownload', per_second => 1 } ],
                output_template => 'traffic in: %s%s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%d', unit => 'bps', min => 0 }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'traffic.out.bitspersecond', display_ok => 0, set => {
                key_values => [ { name => 'bytesUpload', per_second => 1 } ],
                output_template => 'traffic out: %s%s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%d', unit => 'bps', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'interface:s' => { name => 'interface', default => 0 }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {
        'info' => 0, 'warning' => 0, 'error' => 0
    };
    $self->{alarms}->{global} = { alarm => {} };

    my $results = $options{custom}->request_api(
        endpoint => "/lua/rest/v2/get/interface/data.lua",
        get_param => ['ifid=' . $self->{option_results}->{interface} ]
    );

    $self->{global} = {
        alertedFlows     => $results->{rsp}->{alerted_flows},
        flows            => $results->{rsp}->{num_flows},
        alertedFlowsPrct => $results->{rsp}->{num_flows} > 0 ? 100 * $results->{rsp}->{alerted_flows} / $results->{rsp}->{num_flows} : 0,
        packetsDownload  => $results->{rsp}->{packets_download},
        packetsUpload    => $results->{rsp}->{packets_upload},
        packetsDropped   => $results->{rsp}->{drops},
        bytesUpload      => $results->{rsp}->{bytes_upload} * 8,
        bytesDownload    => $results->{rsp}->{bytes_download} * 8
    };

    #my $percent_alerted = sprintf("%.2f", 100*$results->{rsp}->{alerted_flows} / $results->{rsp}->{num_flows});
    #$self->{output}->output_add(severity  => 'OK', short_msg => $self->{global}->{flows} . " flows (" . $self->{global}->{alerted_flows} . " with alerts - $percent_alerted%)" );

    $self->{cache_name} = 'ntopng_' . $options{custom}->get_hostname() . '_' . $self->{mode} . '_' . 
        md5_hex(
            defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '' . '_' .
            defined($self->{option_results}->{interface}) ? $self->{option_results}->{interface} : ''
        );
}
        
1;

__END__

=head1 MODE

Check netflow health.

=over 8

=item B<--interface>

Interface name to check (0 by default).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'flows-detected', 'flows-alerted-detected', 'flows-alerted-prct', 
'packets-download', 'packets-upload', 'packets-dropped', 'traffic-in', 'traffic-out'.

=back

=cut
