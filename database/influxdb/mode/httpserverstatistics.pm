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

package database::influxdb::mode::httpserverstatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
   
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
   
    $self->{maps_counters}->{global} = [
        { label => 'requests-query-count', nlabel => 'requests.query.count.persecond', set => {
                key_values => [ { name => 'queryReq', per_second => 1 } ],
                output_template => 'Query Requests: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 },
                ],
            }
        },
        { label => 'requests-write-count', nlabel => 'requests.write.count.persecond', set => {
                key_values => [ { name => 'writeReq', per_second => 1 } ],
                output_template => 'Write Requests: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 },
                ],
            }
        },
        { label => 'requests-ping-count', nlabel => 'requests.ping.count.persecond', set => {
                key_values => [ { name => 'pingReq', per_second => 1 } ],
                output_template => 'Ping Requests: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 },
                ],
            }
        },
        { label => 'requests-status-count', nlabel => 'requests.status.count.persecond', set => {
                key_values => [ { name => 'statusReq', per_second => 1 } ],
                output_template => 'Status Requests: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 },
                ],
            }
        },
        { label => 'requests-active', nlabel => 'requests.active.count', set => {
                key_values => [ { name => 'reqActive' } ],
                output_template => 'Active Requests: %d',
                perfdatas => [
                    { template => '%d', min => 0 },
                ],
            }
        },
        { label => 'requests-write-active', nlabel => 'requests.write.active.count', set => {
                key_values => [ { name => 'writeReqActive' } ],
                output_template => 'Active Write Requests: %d',
                perfdatas => [
                    { template => '%d', min => 0 },
                ],
            }
        },
        { label => 'requests-response-data', nlabel => 'requests.response.data.bytes', set => {
                key_values => [ { name => 'queryRespBytes', per_second => 1 } ],
                output_change_bytes => 1,
                output_template => 'Response Data: %s%s/s',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B/s' },
                ],
            }
        },
        { label => 'requests-write-data', nlabel => 'requests.write.data.bytes', set => {
                key_values => [ { name => 'writeReqBytes', per_second => 1 } ],
                output_change_bytes => 1,
                output_template => 'Write Data: %s%s/s',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B/s' },
                ],
            }
        },
        { label => 'errors-server', nlabel => 'errors.server.persecond', set => {
                key_values => [ { name => 'serverError', per_second => 1 } ],
                output_template => 'Server Errors: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 },
                ],
            }
        },
        { label => 'errors-client', nlabel => 'errors.client.persecond', set => {
                key_values => [ { name => 'clientError', per_second => 1 } ],
                output_template => 'Client Errors: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0 },
                ],
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{custom} = $options{custom};

    $self->{global} = {};
    
    my $results = $self->{custom}->query(queries => [ "SHOW STATS FOR 'httpd'" ]);
    
    my $i = 0;
    foreach my $column (@{$$results[0]->{columns}}) {
        $column =~ s/influxdb_//;
        $self->{global}->{$column} = $$results[0]->{values}[0][$i];
        $i++;
    }

    $self->{cache_name} = "influxdb_" . $self->{mode} . '_' . $self->{custom}->get_hostname() . '_' . $self->{custom}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check several statistics from the HTTP server serving API.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'requests-query-count', 'requests-write-count',
'requests-ping-count', 'requests-status-count', 'requests-active',
'requests-write-active', 'requests-response-data',
'requests-write-data',  'errors-server', 'errors-client'.

=item B<--critical-*>

Threshold critical.
Can be: 'requests-query-count', 'requests-write-count',
'requests-ping-count', 'requests-status-count', 'requests-active',
'requests-write-active', 'requests-response-data',
'requests-write-data',  'errors-server', 'errors-client'.

=back

=cut
