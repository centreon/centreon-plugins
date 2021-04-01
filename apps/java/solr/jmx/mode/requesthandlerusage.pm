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

package apps::java::solr::jmx::mode::requesthandlerusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'rh', type => 1, cb_prefix_output => 'prefix_rh_output', message_multiple => 'All request handlers are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{rh} = [
        { label => '15min-rate-requests', set => {
                key_values => [ { name => '15minRateRequestsPerSecond' }, { name => 'display' } ],
                output_template => '15min Rate Requests : %.7f/s',
                perfdatas => [
                    { label => '15min_rate_requests', value => '15minRateRequestsPerSecond', template => '%.7f', 
                      min => 0, unit => '/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'avg-requests', set => {
                key_values => [ { name => 'avgRequestsPerSecond' }, { name => 'display' } ],
                output_template => 'Average Requests : %.7f/s',
                perfdatas => [
                    { label => 'avg_requests', value => 'avgRequestsPerSecond', template => '%.7f',
                      min => 0, unit => '/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'avg-time', set => {
                key_values => [ { name => 'avgTimePerRequest' }, { name => 'display' } ],
                output_template => 'Average Time Per Request : %.3f ms',
                perfdatas => [
                    { label => 'avg_time', value => 'avgTimePerRequest', template => '%.3f', 
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'requests-count', set => {
                key_values => [ { name => 'requests', diff => 1 }, { name => 'display' } ],
                output_template => 'Requests Count : %s',
                perfdatas => [
                    { label => 'requests_count', value => 'requests', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name', default => '(/select|/update)$' }
    });

    return $self;
}

sub prefix_rh_output {
    my ($self, %options) = @_;
    
    return "Request Handler '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{rh} = {};
    $self->{request} = [
         { mbean => 'solr/*:id=org.apache.solr.handler.component.SearchHandler,type=*',
           attributes => [ { name => '15minRateRequestsPerSecond' }, { name => 'avgTimePerRequest' }, 
                          { name => 'avgRequestsPerSecond' }, { name => 'requests' } ] },
         { mbean => 'solr/*:id=org.apache.solr.handler.UpdateRequestHandler,type=*',
           attributes => [ { name => '15minRateRequestsPerSecond' }, { name => 'avgTimePerRequest' }, 
                          { name => 'avgRequestsPerSecond' }, { name => 'requests' } ] },
    ];
    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 1);

    foreach my $mbean (keys %{$result}) {
        $mbean =~ /solr\/(.*?):id=.*?\.(.*?)Handler,type=(.*?)(?:,|$)/;
        my $rhname = $1 . '.' . $2 . '.' . $3;

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $rhname !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $rhname . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{rh}->{$rhname} = { 
            display => $rhname,
            %{$result->{$mbean}},
        };
    }
    
    if (scalar(keys %{$self->{rh}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No request handler found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "solr_" . $self->{mode} . '_' . md5_hex($options{custom}->get_connection_info()) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check request handler usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^requests-count$'

=item B<--filter-name>

Filter request handler name (can be a regexp).
Default: '(/select|/update)$'.

=item B<--warning-*>

Threshold warning.
Can be: 'requests-count', 'avg-requests', 'avg-time',
'15min-rate-requests'.

=item B<--critical-*>

Threshold critical.
Can be: 'requests-count', 'avg-requests', 'avg-time',
'15min-rate-requests'.

=back

=cut
