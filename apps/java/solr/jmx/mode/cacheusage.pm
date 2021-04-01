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

package apps::java::solr::jmx::mode::cacheusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'solrcache', type => 1, cb_prefix_output => 'prefix_cache_output', message_multiple => 'All caches are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{solrcache} = [
        { label => 'evictions-count', set => {
                key_values => [ { name => 'cumulative_evictions', diff => 1 }, { name => 'display' } ],
                output_template => 'Evictions Count : %s',
                perfdatas => [
                    { label => 'evictions_count', value => 'cumulative_evictions', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'lookups-count', set => {
                key_values => [ { name => 'cumulative_lookups', diff => 1 }, { name => 'display' } ],
                output_template => 'Lookups Count : %s',
                perfdatas => [
                    { label => 'lookups_count', value => 'cumulative_lookups', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'inserts-count', set => {
                key_values => [ { name => 'cumulative_inserts', diff => 1 }, { name => 'display' } ],
                output_template => 'Inserts Count : %s',
                perfdatas => [
                    { label => 'inserts_count', value => 'cumulative_inserts', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'hits-count', set => {
                key_values => [ { name => 'cumulative_hits', diff => 1 }, { name => 'display' } ],
                output_template => 'Hits Count : %s',
                perfdatas => [
                    { label => 'hits_count', value => 'cumulative_hits', template => '%s', 
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

sub prefix_cache_output {
    my ($self, %options) = @_;
    
    return "Cache '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{solrcache} = {};
    $self->{request} = [
         { mbean => 'solr/*:id=*,type=documentCache',
           attributes => [ { name => 'cumulative_evictions' }, { name => 'cumulative_lookups' }, 
                          { name => 'cumulative_inserts' }, { name => 'cumulative_hits' } ] },
         { mbean => 'solr/*:id=*,type=filterCache',
           attributes => [ { name => 'cumulative_evictions' }, { name => 'cumulative_lookups' }, 
                          { name => 'cumulative_inserts' }, { name => 'cumulative_hits' } ] },
         { mbean => 'solr/*:id=*,type=queryResultCache',
           attributes => [ { name => 'cumulative_evictions' }, { name => 'cumulative_lookups' }, 
                          { name => 'cumulative_inserts' }, { name => 'cumulative_hits' } ] },
    ];
    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 1);

    foreach my $mbean (keys %{$result}) {
        $mbean =~ /solr\/(.*?):.*?,type=(.*?)(?:,|$)/;
        my $cache = $1 . '.' . $2;

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $cache !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $cache . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{solrcache}->{$cache} = { 
            display => $cache,
            %{$result->{$mbean}},
        };
    }
    
    if (scalar(keys %{$self->{solrcache}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No cache found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "solr_" . $self->{mode} . '_' . md5_hex($options{custom}->get_connection_info()) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check cache usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^evictions-count$'

=item B<--filter-name>

Filter cache name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'evictions-count', 'lookups-count', 'inserts-count',
'hits-count'.

=item B<--critical-*>

Threshold critical.
Can be: 'evictions-count', 'lookups-count', 'inserts-count',
'hits-count'.

=back

=cut
