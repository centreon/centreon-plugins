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

package apps::monitoring::splunk::mode::numericvalue;

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

sub custom_result_perfdata {
    my ($self, %options) = @_;
    foreach my $key (sort keys %{$self->{result_values}}) {
        next if $self->{result_values}->{$key} eq '';

        next if $self->{instance_mode}->_match_filter(filter => 'hide', value => $key);
        next if @{$self->{instance_mode}->{display}} && not $self->{instance_mode}->_match_filter(filter => 'display', value => $key);

        my $data = $self->{perfdata}->{data};

        $self->{output}->perfdata_add(
            label    => $data->{name}->{$key} // $data->{label}->{generic} // $key,
            unit     => $data->{unit}->{$key} // $data->{unit}->{generic} // '',
            value    => $self->{result_values}->{$key},
            warning  => $self->{perfdata}->get_perfdata_for_output(label => 
                            defined $self->{perfdata}->{threshold_label}->{"warning-$key"} ?
                                "warning-$key" :
                                'warning-generic'),
            critical => $self->{perfdata}->get_perfdata_for_output(label =>
                            defined $self->{perfdata}->{threshold_label}->{"critical-$key"} ?
                                "critical-$key" :
                                'critical-generic'),
            min      => $data->{min}->{$key} // $data->{min}->{generic} // '',
            max      => $data->{max}->{$key} // $data->{max}->{generic} // '',
        );
    }
}

sub custom_result_threshold {
    my ($self, %options) = @_;

    my @exits = ( 'ok' );
    foreach my $key (sort keys %{$self->{result_values}}) {
        next if $self->{result_values}->{$key} eq '';

        my $ret = 'ok';

        # For each threshold we try to use the specific threshold, if it does not exist we
        # fall back to the generic one
        my $used_critical_key = "critical-$key";
        my $used_warning_key = "warning-$key";
        my $used_unknown_key = "unknown-$key";
        $used_critical_key = 'critical-generic'
            unless defined $self->{perfdata}->{threshold_label}->{$used_critical_key};
        $used_warning_key = 'warning-generic'
            unless defined $self->{perfdata}->{threshold_label}->{$used_warning_key};
        $used_unknown_key = 'unknown-generic'
            unless defined $self->{perfdata}->{threshold_label}->{$used_unknown_key};

        $ret = $self->{perfdata}->threshold_check(
            value     => $self->{result_values}->{$key},
            threshold => [
                { label => $used_critical_key, exit_litteral => 'critical' },
                { label => $used_warning_key, exit_litteral => 'warning' },
                { label => $used_unknown_key, exit_litteral => 'unknown' }
            ]
        );

        push @exits, $ret;
    }

    # Return the worst status
    return $self->{output}->get_most_critical(status => [ @exits ] );
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
        {   label => 'numeric.value', type => 0,
            set => {
                key_values => $self->{record_values},
                closure_custom_output          => $self->can('custom_result_output'),
                closure_custom_perfdata        => $self->can('custom_result_perfdata'),
                closure_custom_threshold_check => $self->can('custom_result_threshold')

            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'query:s'           => { name => 'query', default => '' },

        # Values to be shown/hidden
        'display:s@'        => { name => 'display' },
        'hide:s@'           => { name => 'hide' },

        # Values to be included/excluded from the query results
        'exclude:s@'        => { name => 'exclude' },
        'include:s@'        => { name => 'include' },

        # Define thresholds and perfdata for each value
        'warning-value:s@'  => { name => 'warning_value' },
        'critical-value:s@' => { name => 'critical_value' },
        'perfdata-name:s@'  => { name => 'perfdata_name' },
        'perfdata-unit:s@'  => { name => 'perfdata_unit' },
        'perfdata-min:s@'   => { name => 'perfdata_min' },
        'perfdata-max:s@'   => { name => 'perfdata_max' },
    });


    $self->{perfdata_def} = { unit => { }, min => { }, max => { } };

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{query} = $self->{option_results}->{query};
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

    $self->{$_} = flatten_arrays($self->{option_results}->{$_}) for qw(display hide exclude include critical_value warning_value);

    my $perfdatas;
    $perfdatas->{$_} = flatten_arrays($self->{option_results}->{$_}) for qw(perfdata_name perfdata_unit perfdata_min perfdata_max);

    foreach my $level (qw/critical warning unknown/) {
        foreach my $def (@{$self->{$level."_value"}}) {
            $self->{output}->option_exit(short_msg => "Invalid threshold: $def.")
                unless $def =~ /^(.*?)=?([^=]+)$/;
            my $label = $1 || 'generic';
            my $value = $2;

            $self->{output}->option_exit(short_msg => "Wrong threshold $level-$label option '$value'.")
                unless $self->{perfdata}->threshold_validate(label => "$level-$label", value => $value);
        }
    }

    foreach my $type (qw/name unit min max/) {
        $self->{perfdata}->{data}->{$type} = {};
        foreach (@{$perfdatas->{"perfdata_".$type}}) {
            next unless /^(.*?)=?([^=]+)$/;

            my $label = $1 || 'generic';
            my $value = $2;

            $self->{perfdata}->{data}->{$type}->{$label} = $value;
        }
    }
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
                        grep { $_->{k} !~ /^_/ && $_->{value}->{text} =~ /^[\d\.\-\+]+$/ }      # always filter out internal fields
                            @{$results->{field}};
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

Retrieve numeric values from a Splunk Query

=over 8

=item B<--query>

Specify a query to be sent to Splunk.

If the query starts with '@', it is considered as a file name to read the query from.

Query has to start with "search ". Of it does not "search " will be automatically prepended at execution time.
Example: --query=C<index=main | table skippedRatio | where skippedRatio > 0.2>

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

=item B<--perfdata-unit>

Perfdata unit in perfdata output.
This option can be used multiple times and multiple values can be passed as a comma separated list.
The field name and the unit are separated by an equals sign.
If the [field] name is not set, the [unit] applies to all fields that do not have a defined unit.

Syntax: C<--perfdata-unit=[field]=[unit]>

For example to set a unit C<%> for the field C<skippedRatio>: C<--perfdata-unit=skippedRatio=%>
Or to set a unit for all fields without a specific unit: C<--perfdata-unit=%>

=item B<--perfdata-name>

Perfdata name in perfdata output.
This option can be used multiple times and multiple values can be passed as a comma separated list.
The field name and the name are separated by an equals sign.
If the [field] name is not set, the [name] applies to all fields that do not have a defined name.

Syntax: C<--perfdata-name=[field]=[name]>

For example to set name C<test> for the field C<skippedRatio>: C<--perfdata-name=skippedRatio=test>
Or to set a name for all fields without a specific name: C<--perfdata-name=test>

=item B<--perfdata-min>

Minimum value to add in perfdata output.
This option can be used multiple times and multiple values can be passed as a comma separated list.
The field name and the minimum value are separated by an equals sign.
If the [field] name is not set, the [minimum value] applies to all fields that do not have a defined minimum value.

Syntax: C<--perfdata-min=[field]=[minimum value]>

For example to set minimum value C<1> for the field C<skippedRatio>: C<--perfdata-min=skippedRatio=1>
Or to set a minimum value for all fields without a specific name: C<--perfdata-min=1>


=item B<--perfdata-max>

Maximum value to add in perfdata output.
This option can be used multiple times and multiple values can be passed as a comma separated list.
The field name and the maximum value are separated by an equals sign.
If the [field] name is not set, the [maximum value] applies to all fields that do not have a defined maximum value.

Syntax: C<--perfdata-max=[field]=[maximum value]>

For example to set maximum value C<100> for the field C<skippedRatio>: C<--perfdata-max=skippedRatio=100>
Or to set a maximum value for all fields without a specific name: C<--perfdata-max=100>

=item B<--warning-count> 

Warning threshold for query matches.

Example: --warning-count=5

=item B<--critical-count>

Critical threshold for query matches.

Example: --critical-count=15

=item B<--warning-value>

Warning threshold for a specific field value.
This option can be used multiple times and multiple values can be passed as a comma separated list.
The field name and the threshold are separated by an equals sign.
If the [field] name is not set, the [threshold] applies to all fields that do not have a defined threshold.

Syntax: C<--warning-value=[field]=[threshold]>

For example to set a threshold of C<:1> for the field C<skippedRatio>: C<--warning-value=skippedRatio=:1>
Or to set a threshold for all fields without a specific threshold: C<--warning-value=:1>

=item B<--critical-value>

Critical threshold for a specific field value.
This option can be used multiple times and multiple values can be passed as a comma separated list.
The field name and the threshold are separated by an equals sign.
If the [field] name is not set, the [threshold] applies to all fields that do not have a defined threshold.

Syntax: C<--critical-value=[field]=[threshold]>

For example to set a threshold of C<:1> for the field C<skippedRatio>: C<--critical-value=skippedRatio=:1>
Or to set a threshold for all fields without a specific threshold: C<--critical-value=:1>

=back

=cut
