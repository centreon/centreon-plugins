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

package apps::elasticsearch::restapi::mode::nodes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'nodes', type => 0, cb_prefix_output => 'prefix_output' },
    ];
    
    $self->{maps_counters}->{nodes} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total : %s',
                perfdatas => [
                    { label => 'total', value => 'total_absolute', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'masteronly', set => {
                key_values => [ { name => 'master_only' } ],
                output_template => 'Master Only : %s',
                perfdatas => [
                    { label => 'master_only', value => 'master_only_absolute', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'dataonly', set => {
                key_values => [ { name => 'data_only' } ],
                output_template => 'Data Only : %s',
                perfdatas => [
                    { label => 'data_only', value => 'data_only_absolute', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'masterdata', set => {
                key_values => [ { name => 'master_data' } ],
                output_template => 'Master Data : %s',
                perfdatas => [
                    { label => 'master_data', value => 'master_data_absolute', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'client', set => {
                key_values => [ { name => 'client' } ],
                output_template => 'Client : %s',
                perfdatas => [
                    { label => 'client', value => 'client_absolute', template => '%s',
                      min => 0 },
                ],
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Nodes ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "elastic-path:s"      => { name => 'elastic_path', default => '/_cluster/stats' },
                                });
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
                                                           
    my $result = $options{custom}->get(path => $self->{option_results}->{elastic_path});
    $self->{nodes} = { 
        %{$result->{nodes}->{count}}
    };
}

1;

__END__

=head1 MODE

Check Elasticsearch nodes.

=over 8

=item B<--elastic-path>

Set path to get Elasticsearch information (Default: '/_cluster/stats')

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^total$'

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'masteronly', 'dataonly', 'masterdata', 'client'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'masteronly', 'dataonly', 'masterdata', 'client'.

=back

=cut
