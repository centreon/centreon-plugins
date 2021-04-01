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

package database::cassandra::jmx::mode::clientrequestsusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cr', type => 1, cb_prefix_output => 'prefix_cr_output', message_multiple => 'All client requests are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{cr} = [
        { label => 'total-latency', nlabel => 'client.request.latency.microsecond', set => {
                key_values => [ { name => 'TotalLatency_Count', diff => 1 }, { name => 'display' } ],
                output_template => 'Total Latency : %s us',
                perfdatas => [
                    { label => 'total_latency', value => 'TotalLatency_Count', template => '%s', 
                      min => 0, unit => 'us', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'timeouts', nlabel => 'client.request.timeout.count', set => {
                key_values => [ { name => 'Timeouts_Count', diff => 1 }, { name => 'display' } ],
                output_template => 'Timeouts : %s',
                perfdatas => [
                    { label => 'timeouts', value => 'Timeouts_Count', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'unavailables', nlabel => 'client.request.unavailable.count', set => {
                key_values => [ { name => 'Unavailables_Count', diff => 1 }, { name => 'display' } ],
                output_template => 'Unavailables : %s',
                perfdatas => [
                    { label => 'unavailbles', value => 'Unavailables_Count', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'failures', nlabel => 'client.request.failure.count', set => {
                key_values => [ { name => 'Failures_Count', diff => 1 }, { name => 'display' } ],
                output_template => 'Failures : %s',
                perfdatas => [
                    { label => 'failures', value => 'Failures_Count', template => '%s', 
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
        "filter-name:s"       => { name => 'filter_name' },
    });
    
    return $self;
}

sub prefix_cr_output {
    my ($self, %options) = @_;
    
    return "Client Request '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{cr} = {};
    $self->{request} = [
         { mbean => 'org.apache.cassandra.metrics:name=TotalLatency,scope=*,type=ClientRequest', attributes => [ { name => 'Count' } ] },
         { mbean => 'org.apache.cassandra.metrics:name=Timeouts,scope=*,type=ClientRequest', attributes => [ { name => 'Count' } ] },
         { mbean => 'org.apache.cassandra.metrics:name=Unavailables,scope=*,type=ClientRequest', attributes => [ { name => 'Count' } ] },
         { mbean => 'org.apache.cassandra.metrics:name=Failures,scope=*,type=ClientRequest', attributes => [ { name => 'Count' } ] },
    ];
    
    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 1);
    foreach my $mbean (keys %{$result}) {
        $mbean =~ /scope=(.*?)(?:,|$)/;
        my $scope = $1;
        $mbean =~ /name=(.*?)(?:,|$)/;
        my $name = $1;
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $scope !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $scope . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{cr}->{$scope} = { display => $scope } if (!defined($self->{cr}->{$scope}));
        foreach (keys %{$result->{$mbean}}) {
            $self->{cr}->{$scope}->{$name . '_' . $_} = $result->{$mbean}->{$_};
        }
    }
    
    if (scalar(keys %{$self->{cr}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No client request found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "cassandra_" . $self->{mode} . '_' . md5_hex($options{custom}->get_connection_info()) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check client requests usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='latency'

=item B<--filter-name>

Filter name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-latency', 'timeouts', 'unavailables', 'failures'.

=back

=cut
