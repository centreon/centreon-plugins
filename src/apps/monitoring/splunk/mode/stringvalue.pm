# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::monitoring::splunk::mode::stringvalue;

use strict;
use warnings;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::misc qw/flatten_arrays/;
use centreon::plugins::constants qw(:values);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_result_output {
    my ($self, %options) = @_;

    my @data;
    foreach my $key (sort keys %{$self->{result_values}}) {
        next if $self->{result_values}->{$key} eq '';

        next if $self->{instance_mode}->_match_filter(filter => 'hide', value => $key);
        next if @{$self->{instance_mode}->{display}} && not $self->{instance_mode}->_match_filter(filter => 'display', value => $key);

        push @data, "[$key: " . $self->{result_values}->{$key}."]";
    }

    my $str = lc $self->{output}->{errors_num}->{$self->{perfdata}->{output}->{global_status}}.'_label';
    my $prefix = exists $self->{instance_mode}->{$str} ?
                    $self->{instance_mode}->{$str} :
                    '';

    $prefix = "$prefix " if $prefix ne '';

    return $prefix.join ' ', @data;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 , skipped_code => { NO_VALUE => 1 }},
        { name => 'query_results', type => 1, message_multiple => 'All values are OK', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'count', nlabel => 'splunk.event.count', set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Events: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{record_values} = [ ];
    $self->{record_values_hash} = {};

     $self->{maps_counters}->{query_results} = [ 
        {   label => 'value', type => 2,
            set => {
                key_values => $self->{record_values},
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
                closure_custom_output => $self->can('custom_result_output'),
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'query:s'          => { name => 'query', default => '' },
        'display:s@'       => { name => 'display' },
        'hide:s@'          => { name => 'hide' },
        'exclude:s@'       => { name => 'exclude' },
        'include:s@'       => { name => 'include' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);


    $self->{$_} = $self->{option_results}->{$_} for qw(query ok_label warning_label critical_label);


    $self->{output}->option_exit(short_msg => 'Please set --query option.')
        if $self->{query} eq '';

    # query parameter points to a file when starting with '@'
    if ($self->{query} =~ /[\t\s]*@(.+)/) {
        my $file = $1;
        $self->{output}->option_exit(short_msg => "Invalid query parameter: '$file' is not a valid file.")
            unless -f $file;
        $self->{output}->output_add(long_msg => "Reading query from file '$file'.", debug => 1);
        $self->{query} = centreon::plugins::misc::slurp_file(output => $self->{output}, file => $file);
    }

    $self->{$_} = flatten_arrays($self->{option_results}->{$_}) for qw(display hide exclude include);
}

sub _match_filter {
    my ($self, %options) = @_;

    my $filters = $self->{$options{filter}};
    my $value = $options{value};

    foreach my $filter (@{$filters}) {
        return 1 if $value =~ /$filter/;
    }

    return 0;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $query_value = $options{custom}->query_value(
        query => $self->{query},
        timeframe => $self->{timeframe},
    );

    my $index=0;
    $self->{query_results} = {};
    my %record_values_hash = ();

    if ($query_value->{result}) {
        $query_value->{result} = [ $query_value->{result} ] if ref $query_value->{result} eq 'HASH';

        foreach my $results (@{$query_value->{result}}) {
            my %values = ();
            if (ref $results->{field} eq 'ARRAY') {
                map { $record_values_hash{$_->{k}} =1;
                      $values{$_->{k}} = $_->{value}->{text};
                    }
                        grep { @{$self->{include}} == 0 || $self->_match_filter(filter => 'include', value => $_->{k} ) }   # exclude fields not matching 'include filters'
                        grep { not $self->_match_filter(filter => 'exclude', value => $_->{k} ) }   # exclude fields matching 'exclude filters'
                        grep { $_->{k} !~ /^_/ }      # always filter out internal fields
                            @{$results->{field}};
                next unless keys %values;
            } else {
                $record_values_hash{$results->{field}->{k}} = 1;
                $values{$results->{field}->{k}} = $results->{field}->{value}->{text};
            }

            $self->{query_results}->{ $index++ } = \%values;
        }
    }

    push @{$self->{record_values}}, { name => $_ } foreach sort keys %record_values_hash;

    foreach my $instance (values %{$self->{query_results}}) {
        foreach (keys %record_values_hash) {
            $instance->{$_} = '' unless exists $instance->{$_};
        }
    }

    $self->{global} = {
        'count' => $index
    };
}

1;

__END__

=head1 MODE

Retrieve string values from a Splunk Query

=over 8

=item B<--query>

Specify a query to be sent to Splunk.

If the query starts with '@', it is considered as a file name to read the query from.

Query has to start with "search ". Of it does not "search " will be automatically prepended at execution time.
Example: --query=C<index=_internal | head 1 | table sourcetype>

=item B<--include>

Define the Splunk fields to be managed by the plugin (can be a regexp).
This option can be used multiple times and multiple values can be passed as a comma separated list.
If this parameter is empty (default) all fields are managed by the plugin, otherwise, only matching fields are managed.
Only managed fields can be displayed or used for checks.

=item B<--exclude>

Define the Splunk fields to be ignored by the plugin (can be a regexp).
This option can be used multiple times and multiple values can be passed as a comma separated list.
If this parameter is not empty, all matching fields are ignored by the plugin.
Only managed fields can be displayed or used for checks.

=item B<--display>

Define the Splunk fields to be displayed (can be a regexp).
This option can be used multiple times and multiple values can be passed as a comma separated list.
Only managed fields are considered.
If this parameter is empty (default), all fields are displayed; otherwise, only matching fields are displayed.
Fields are always displayed in the long output in verbose mode.

=item B<--hide>

Define the Splunk fields to hide (can be a regexp).
This option can be used multiple times and multiple values can be passed as a comma separated list.
Only managed fields are considered.
If this parameter is not empty, all matching fields are hidden.

=item B<--warning-count> 

Warning threshold for the number of events returned by the query

Example: --warning-count=5

=item B<--critical-count>

Critical threshold for the number of events returned by the query

Example: --critical-count=15

=item B<--warning-value>

Define the conditions to match for the status to be WARNING.
This option can be used multiple times and multiple values can be passed as a comma separated list.
Field names can be used as variables, and complex expressions are supported.

Example: --warning-value='%{sourcetype} =~ /orchestrator/'

=item B<--critical-value>

Define the conditions to match for the status to be CRITICAL.
This option can be used multiple times and multiple values can be passed as a comma separated list.
Field names can be used as variables, and complex expressions are supported.

Example: --critical-value='%{sourcetype} =~ /orchestrator/'

=back

=cut
