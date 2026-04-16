#
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

package network::security::cato::networks::api::mode::events;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

use centreon::plugins::misc qw(flatten_arrays);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'Record '.$self->{result_values}->{event_id}.': '.
               join ', ', map { $_.'="'.$self->{result_values}->{$_}.'"' }
                          grep { defined $self->{result_values}->{$_} }
                              @{$self->{instance_mode}->{display}};
}

sub set_counters {
    my ($self, %options) = @_;
    $self->{maps_counters_type} = [
            { name => 'global', type => 0, skipped_code => { -10 => 1 } },
            { name => 'records', type => 1, message_multiple => 'All records are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'count', nlabel => 'count',
            set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Number of records: %d',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        }
    ];

    $self->{records_values} = [ { name => 'status' }, { name => 'event_id' } ];

    $self->{maps_counters}->{records} = [
        { label => 'event', type => 2,
            set => {
                key_values => $self->{records_values},
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
            "type:s@"                => { name => 'type' },
            "sub-type:s@"            => { name => 'sub_type' },
            "include-status:s@"      => { name => 'include_status' },
            "exclude-status:s@"      => { name => 'exclude_status' },
            "include:s@"             => { name => 'include' },
            "exclude:s@"             => { name => 'exclude' },
            "display:s@"             => { name => 'display' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

    $self->{types} = flatten_arrays($self->{option_results}->{type});
    $self->{sub_types} = flatten_arrays($self->{option_results}->{sub_type});

    # By defaut we exclude closed events
    # Default array values are defined here because add_options does not handle them properly
    $self->{option_results}->{exclude_status} = ['Closed']
        unless defined $self->{option_results}->{exclude_status};

    # By default we display these fields
    $self->{option_results}->{display} = [ 'event_id', 'time_str', 'event_type', 'event_sub_type', 'severity', 'title', 'event_message', 'pop_name', 'src_site_name', 'dest_site_name' ] 
        unless defined $self->{option_results}->{display};

    $self->{$_} = flatten_arrays($self->{option_results}->{$_}) foreach qw/include exclude include_status exclude_status display/;
    # Check that each --include and --exclude expression refers to some variables
    foreach my $option (qw/include exclude/) {
        $self->{output}->option_exit(short_msg => "Option --$option need to contains expression with variable (eg: %{status} =~ /Closed/)")
            if @{$self->{include}} && not grep { /%\{/ } @{$self->{include}};
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $marker = '';

    my $first_request = 1;
    my $gen_id=0;

    $self->{records} = {};

    while (1) {
        # All eventsFeeds requests can return a maximum of 3000 records. If there are more results we have to use the
        # marker value to loop until all data is retrieved.
        my $results = $options{custom}->get_eventsfeed( marker => $marker,
                                                        types => $self->{types},
                                                        sub_types => $self->{sub_types} );

        last unless $results->{marker};


        foreach my $account (@{$results->{accounts}}) {
            next unless ref $account->{records} eq 'ARRAY' && @{$account->{records}};

            if ($first_request) {
                $first_request = 0;

                # On the first request w we make sure that include options contain ony variable that are present in
                # the data returned by the Cato API.
                # Full list of variables: https://api.catonetworks.com/documentation/#definition-EventFieldName
                foreach my $option (@{$self->{include}}) {
                    while ($option =~ /%\{([a-z_]+)\}/g) {
                        my $value = $1;
                        $self->{output}->option_exit(exit_literal => 'unknown', short_msg => "Value '$value' not present in data.")
                            unless exists $account->{records}->[0]->{fieldsMap}->{$value};
                    }
                }

                # Add the list of returned variables to the counter definition
                foreach my $value ( keys %{$account->{records}->[0]->{fieldsMap}} ) {
                    next if $value =~ /^(status|event_id)$/;

                    push @{$self->{records_values}}, { name => $value };
                }
            }

            RECORD: foreach my $record ( @{$account->{records}} )  {
                $record->{fieldsMap}->{status} //= '';
                # Handle the absence of event_id (should not happen)
                my $event_id = $record->{fieldsMap}->{event_id} = $record->{fieldsMap}->{event_id} // "UNK".$gen_id++;

                # There are four filters that can be used multiple times to filter the data:
                # --include and --exclude can containt complex expressions, for example: %{event_type} =~ /Security/
                # --include-status and --exclude-status filter on the value of the 'status' variable
                # When an include filter is defined the returned data must match at least one of them
                # When an exclude filter is defined the returned data must not match any of them
                if (@{$self->{include}}) {
                    my $whitelist = 0;
                    foreach my $option (@{$self->{include}}) {
                        my $used_option = $option;
                        # We substitute %{var} by 'value' to be able to eval the expression
                        $used_option =~ s/%\{([a-z_]+)\}/"'".$record->{fieldsMap}->{$1}."'"/e while $used_option =~ /%\{([a-z_]+)\}/g;

                        if ($self->{output}->test_eval(test => $used_option, values => $record->{fieldsMap})) {
                            $whitelist = 1;
                            last
                        }
                    }
                    unless ($whitelist) {
                        $self->{output}->output_add(long_msg => "skipping record '$event_id': no including filter match.", debug => 1);
                        next RECORD
                    }
                }
                if (@{$self->{exclude}}) {
                    foreach my $option (@{$self->{exclude}}) {
                        my $used_option = $option;
                        # We substitute %{var} by 'value' to be able to eval the expression
                        $used_option =~ s/%\{([a-z_]+)\}/"'".$record->{fieldsMap}->{$1}."'"/e while $used_option =~ /%\{([a-z_]+)\}/g;

                        if ($self->{output}->test_eval(test => $used_option, values => $record->{fieldsMap})) {
                            $self->{output}->output_add(long_msg => "skipping record '$event_id': excluding filter match.", debug => 1);
                            next RECORD
                        }
                    }
                }

                if (@{$self->{include_status}}) {
                    my $whitelist_status = 0;
                    foreach my $option (@{$self->{include_status}}) {
                        if ($record->{fieldsMap}->{status} =~ /$option/) {
                            $whitelist_status = 1;
                            last
                        }
                    }
                    unless ($whitelist_status) {
                        $self->{output}->output_add(long_msg => "skipping record '$event_id': no including status filter match.", debug => 1);
                        next RECORD
                    }
                }
                if (@{$self->{exclude_status}}) {
                    foreach my $option (@{$self->{exclude_status}}) {
                        if ($record->{fieldsMap}->{status} =~ /$option/) {
                            $self->{output}->output_add(long_msg => "skipping record '$event_id': excluding status filter match.", debug => 1);
                            next RECORD
                        }
                    }
                }

                $self->{records}->{$event_id} = $record->{fieldsMap};
            }
        }

        # Update the marker for the next request
        $marker = $results->{marker};

        # Less then 3000 records means that we have retrieved all data
        last if ($results->{fetchedCount} // 0) < 3000;
    }

    $self->{global} = { count => scalar keys %{$self->{records}} };
}

1;

__END__

=head1 MODE

Check events generated by activities.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='count'

=item B<--type>

Filter events by type (comma separated list, can be multiple).
Supported values are: C<Routing>, C<Security>, C<System>, C<Connectivity>, C<Performance>, C<Sockets Managements>.

Refer to the Cato API documentation for more information on the possible values https://api.catonetworks.com/documentation/#definition-EventFieldName

=item B<--sub-type>

Filter events by sub type (comma separated list, can be multiple).

=item B<--display>

Specify which field to display (comma separated list, can be multiple).
Example: --display='event_sub_type,severity,title'
Default value: C<event_id, time_str, event_type, event_sub_type, severity, title, event_message, pop_name, src_site_name, dest_site_name>
Fields that return no values are not displayed.
C<event_id> is always added to the list of displayed fields.

Refer to the Cato API documentation for more information on the possible values https://api.catonetworks.com/documentation/#definition-EventFieldName

=back

=head2 Filter the returned data

The following options can be used to filter the returned data.
When an include filter is defined the returned data must match at least one of them.
When an exclude filter is defined the returned data must not match any of them.

Refer to the Cato API documentation for more information on the possible values https://api.catonetworks.com/documentation/#definition-EventFieldName

=item B<--include-status>

Filter events by status (comma separated list, can be multiple, regexp can be used).
Possible values are C<Open>, C<Pending Analysis>, C<Pending more info>, C<Closed>, C<Reopened>, C<Monitoring>.

=item B<--exclude-status>

Exclude events by status (comma separated list, can be multiple, regexp can be used).
Possible values are C<Open>, C<Pending Analysis>, C<Pending more info>, C<Closed>, C<Reopened>, C<Monitoring>.
Default value: C<Closed>

=item B<--include>

Filter events using a complex expression based on returned fields values.
Example: --include='%{event_type} =~ /Security/ && %{severity} =~ /High/'

=item B<--exclude>

Exclude events using a complex expression based on returned fields values.
Example: --exclude='%{event_type} =~ /Security/ && %{status} !~ /Closed/'

=back

=head2 Thresholds

=item B<--warning-count>

Threshold.
Number of matching events.

=item B<--critical-count>

Threshold.
Number of matching events.

=item B<--warning-event>

Define the conditions to match for the status to be WARNING.
A expression using field values to define the warning threshold.
Example: --warning-event='%{event_type} =~ /Security/ && %{status} =~ /Closed/'

=item B<--critical-event>

Define the conditions to match for the status to be CRITICAL.
A expression using field values to define the critical threshold.
Example: --critical-event='%{event_type} =~ /Security/ && %{status} !~ /Closed/'

=back

=cut
