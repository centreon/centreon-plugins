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

package apps::java::hibernate::jmx::mode::stats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'app', type => 1, cb_prefix_output => 'prefix_app_output', message_multiple => 'All hibernate applications are ok', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{app} = [
        { label => 'connect-count', set => {
                key_values => [ { name => 'connect', diff => 1 }, { name => 'display' } ],
                output_template => 'Connect Count : %s',
                perfdatas => [
                    { label => 'connect_count', value => 'connect', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'close-count', set => {
                key_values => [ { name => 'close', diff => 1 }, { name => 'display' } ],
                output_template => 'Close Count : %s',
                perfdatas => [
                    { label => 'close_count', value => 'close', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'query-count', set => {
                key_values => [ { name => 'query', diff => 1 }, { name => 'display' } ],
                output_template => 'Query Count : %s',
                perfdatas => [
                    { label => 'query_count', value => 'query', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'insert-count', set => {
                key_values => [ { name => 'insert', diff => 1 }, { name => 'display' } ],
                output_template => 'Insert Count : %s',
                perfdatas => [
                    { label => 'insert_count', value => 'insert', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'update-count', set => {
                key_values => [ { name => 'update', diff => 1 }, { name => 'display' } ],
                output_template => 'Update Count : %s',
                perfdatas => [
                    { label => 'update_count', value => 'update', template => '%s', 
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
    
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-name:s"       => { name => 'filter_name' },
                                });
    
    return $self;
}

sub prefix_app_output {
    my ($self, %options) = @_;
    
    return "Application '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{app} = {};
    $self->{request} = [
         { mbean => 'Hibernate:Application=*,type=statistics',
          attributes => [ { name => 'SessionCloseCount' }, { name => 'ConnectCount' }, 
                          { name => 'EntityInsertCount' }, { name => 'CollectionUpdateCount' },
                          { name => 'QueryExecutionCount' }, { name => 'StatisticsEnabled' } ] },
         { mbean => 'Hibernate:type=statistics',
          attributes => [ { name => 'SessionCloseCount' }, { name => 'ConnectCount' }, 
                          { name => 'EntityInsertCount' }, { name => 'CollectionUpdateCount' },
                          { name => 'QueryExecutionCount' }, { name => 'StatisticsEnabled' } ] },
    ];
    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 1);

    foreach my $mbean (keys %{$result}) {
        $mbean =~ /Application=(.*?),/;
        my $app = defined($1) ? $1 : 'global';

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $app !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $app . "': no matching filter.", debug => 1);
            next;
        }
        if (!$result->{$mbean}->{StatisticsEnabled}) {
            $self->{output}->output_add(long_msg => "skipping '" . $app . "': statistics is disabled.", debug => 1);
            next;
        }
        
        $self->{app}->{$app} = { 
            display => $app, 
            close => $result->{$mbean}->{SessionCloseCount},
            connect => $result->{$mbean}->{ConnectCount},
            insert => $result->{$mbean}->{EntityInsertCount},
            query => $result->{$mbean}->{QueryExecutionCount},
            update => $result->{$mbean}->{CollectionUpdateCount},
        };
    }
    
    if (scalar(keys %{$self->{app}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No application found (or staistics is disabled).");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "hibernate_" . $self->{mode} . '_' . md5_hex($options{custom}->get_connection_info()) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check hibernate statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^connect-count$'

=item B<--filter-name>

Filter application name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'connect-count', 'query-count', 'insert-count',
'update-count' 'close-count'.

=item B<--critical-*>

Threshold critical.
Can be: 'connect-count', 'query-count', 'insert-count',
'update-count' 'close-count'.

=back

=cut
