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
use centreon::plugins::misc qw/flatten_arrays flatten_to_hash/;
use centreon::plugins::constants qw(:values);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_result_output {
    my ($self, %options) = @_;

    my @data;
    foreach my $key (sort keys %{$self->{result_values}}) {
        next if $key eq '__title';
        next if $self->{result_values}->{$key} eq '';
        next if $self->{instance_mode}->_match_filter(filter => 'hide', field => $key);
        next if @{$self->{instance_mode}->{display}} && not $self->{instance_mode}->_match_filter(filter => 'display', field => $key);

        push @data, "[$key: " . $self->{result_values}->{$key}."]";
    }

    my $str = lc $self->{severity}.'_label';
    my $prefix = exists $self->{instance_mode}->{$str} ?
                    $self->{instance_mode}->{$str} :
                    '';

    $prefix = "$prefix " if $prefix ne '';

    my $title = $self->{result_values}->{__title} // '';
    $title = "$title " if $title ne '';

    return $title.$prefix.join ' ', @data;
}

sub custom_result_threshold {
    my ($self, %options) = @_;

    $self->{severity} = catalog_status_threshold_ng($self, %options);

    return $self->{severity};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
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

    $self->{record_values} = [ { name => '__title' } ];
    $self->{record_values_hash} = {};

     $self->{maps_counters}->{query_results} = [ 
        {   label => 'value', type => 2,
            set => {
                key_values => $self->{record_values},
                closure_custom_threshold_check => $self->can('custom_result_threshold'), #\&catalog_status_threshold_ng,
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
        'query:s'                   => { name => 'query', default => '' },
        'search-mode:s'             => { name => 'search_mode', default => 'auto' },

        'ok-label:s'                => { name => 'ok_label', default => '' },
        'warning-label:s'           => { name => 'warning_label', default => 'trigger WARNING status' },
        'critical-label:s'          => { name => 'critical_label', default => 'trigger CRITICAL status' },
        'event-field:s'             => { name => 'event_field', default => '' },
        'event-label:s'             => { name => 'event_label', default => 'event' },

        # Values to be shown/hidden
        'display:s@'                => { name => 'display' },
        'hide:s@'                   => { name => 'hide' },

        # Values to be included/excluded from the query results
        'exclude:s@'                => { name => 'exclude' },
        'include:s@'                => { name => 'include' },
        'include-internal-field:s@' => { name => 'include_internal_field' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{$_} = $self->{option_results}->{$_} for qw(query ok_label warning_label critical_label search_mode event_field event_label);

    $self->{output}->option_exit(short_msg => 'Please set --query option.')
        if $self->{query} eq '';

    $self->{output}->option_exit(short_msg => "Invalid search mode '" . $self->{search_mode} . "'.")
        if $self->{search_mode} !~ /^(auto|fast|smart|verbose)$/;

    # query parameter points to a file when starting with '@'
    if ($self->{query} =~ /[\t\s]*@(.+)/) {
        my $file = $1;
        $self->{output}->option_exit(short_msg => "Invalid query parameter: '$file' is not a valid file.")
            unless -f $file;
        $self->{output}->output_add(long_msg => "Reading query from file '$file'.", debug => 1);
        $self->{query} = centreon::plugins::misc::slurp_file(output => $self->{output}, file => $file);
    }

    $self->{$_} = flatten_arrays($self->{option_results}->{$_}) for qw(display hide exclude include);

    $self->{include_internal_field} = flatten_to_hash($self->{option_results}->{include_internal_field});
}

sub _match_filter {
    my ($self, %options) = @_;

    my $filters = $self->{$options{filter}};
    my $field = $options{field};

    foreach my $filter (@{$filters}) {
        return 1 if $field =~ /$filter/;
    }

    return 0;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $query_value = $options{custom}->query_value(
        query => $self->{query},
        search_mode => $self->{search_mode}
    );

    my $index=0;
    $self->{query_results} = {};
    my %record_values_hash = ();

    if ($query_value->{result}) {
        $query_value->{result} = [ $query_value->{result} ] if ref $query_value->{result} eq 'HASH';

        foreach my $results (@{$query_value->{result}}) {
            my $title = $self->{event_label} ne '' ? $self->{event_label}.'-'.$index : '';

            my %values;
            if (ref $results->{field} eq 'ARRAY') {
                foreach my $record (@{$results->{field}}) {
                    $title = $options{custom}->get_value(record => $record)
                        if $self->{event_field} ne '' && $record->{k} eq $self->{event_field};

                    # always filter out internal fields unless they are explicitly included with include_internal_field option
                    next if $record->{k} =~ /^_/ && not $self->{include_internal_field}->{$record->{k}};

                    # exclude fields matching 'exclude filters'
                    next if $self->_match_filter(filter => 'exclude', field => $record->{k});

                    # exclude fields not matching 'include filters'
                    next if @{$self->{include}} && not $self->_match_filter(filter => 'include', field => $record->{k});

                    $record_values_hash{$record->{k}} = 1;
                    $values{$record->{k}} = $options{custom}->get_value(dbg => $record->{k}, record => $record);
                }

                next unless %values;
            } else {
                $record_values_hash{$results->{field}->{k}} = 1;
                # get first value only (we don't handle more complex structures)
                $values{$results->{field}->{k}} = $options{custom}->get_value(record => $results->{field});

                $title = $values{$results->{field}->{k}}
                    if $self->{event_field} ne '' && $results->{field}->{k} eq $self->{event_field};
            }
            $values{__title} = $title;
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

Query has to start with "search" or "|".
Example: --query=C<index=_internal | head 1 | table sourcetype>

=item B<--search-mode>

Specify the search mode (default: 'auto').
Can be: 'auto', 'fast', 'smart', 'verbose'.
The 'auto' value lets Splunk use its default mode.
Check https://help.splunk.com/en/splunk-cloud-platform/search/search-manual/10.0.2503/using-the-search-app/search-modes for more details.

=item B<--include>

Define the Splunk fields to be managed by the plugin (can be a regexp).
This option can be used multiple times and multiple values can be passed as a comma separated list.
If this parameter is empty (default) all fields are managed by the plugin, otherwise, only matching fields are managed.
Only managed fields can be displayed and used for checks.

=item B<--exclude>

Define the Splunk fields to be ignored by the plugin (can be a regexp).
This option can be used multiple times and multiple values can be passed as a comma separated list.
If this parameter is not empty, all matching fields are ignored by the plugin.
Only managed fields can be displayed and used for checks.

=item B<--display>

Define the Splunk fields to be displayed (can be a regexp).
This option can be used multiple times and multiple values can be passed as a comma separated list.
Only managed fields are considered.
If this parameter is empty (default), all fields are displayed; otherwise, only matching fields are displayed.

=item B<--hide>

Define the Splunk fields to hide (can be a regexp).
This option can be used multiple times and multiple values can be passed as a comma separated list.
Only managed fields are considered.
If this parameter is not empty, all matching fields are hidden.

=item B<--include-internal-field>

By default fields starting with '_' are considered as internal and ignored.
This option allows to include them.
Example: --include-internal-field=_raw
This option can be used multiple times and multiple values can be passed as a comma separated list.

=item B<--ok-label>

Define the label to use for events that trigger the OK status (default: '').

=item B<--warning-label>

Define the label to use for events that trigger the WARNING status (default: 'trigger WARNING status').

=item B<--critical-label>

Define the label to use for events that trigger the CRITICAL status (default: 'trigger CRITICAL status').

=item B<--warning-count> 

Warning threshold for the number of events returned by the query

Example: --warning-count=5

=item B<--critical-count>

Critical threshold for the number of events returned by the query

Example: --critical-count=15

=item B<--warning-value>

Define the conditions to match for the status to be WARNING.
Field names can be used as variables, and complex expressions are supported.

Example: --warning-value='%{sourcetype} =~ /orchestrator/'

=item B<--critical-value>

Define the conditions to match for the status to be CRITICAL.
Field names can be used as variables, and complex expressions are supported.

Example: --critical-value='%{sourcetype} =~ /orchestrator/'

=back

=cut
