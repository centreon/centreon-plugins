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

package apps::monitoring::loggly::restapi::mode::fields;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'field', type => 1, cb_prefix_output => 'prefix_field_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'events', nlabel => 'events.count', display_ok => 1, set => {
                key_values => [ { name => 'events' } ],
                output_template => 'Matching events: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'fields', nlabel => 'fields.count', display_ok => 1, set => {
                key_values => [ { name => 'fields' } ],
                output_template => 'Matching fields: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
    ];

    $self->{maps_counters}->{field} = [
        { label => 'field-events', nlabel => 'field.events.count', set => {
                key_values => [ { name => 'count' }, { name => 'display' } ],
                output_template => 'matching events: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub prefix_field_output {
    my ($self, %options) = @_;

    return "Field '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
        'time-period:s'  => { name => 'time_period' },
        'query:s'        => { name => 'query' },
        'field:s'        => { name => 'field' },
        'filter-field:s' => { name => 'filter_field' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{time_period}) || $self->{option_results}->{time_period} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --time-period option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{query}) || $self->{option_results}->{query} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --query option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{field}) || $self->{option_results}->{field} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --field option.");
        $self->{output}->option_exit();
    }
    # 300 limitation comes from the API : https://documentation.solarwinds.com/en/Success_Center/loggly/Content/admin/api-retrieving-data.htm
    if (defined($self->{option_results}->{'warning-fields-count'}) && $self->{option_results}->{'warning-fields-count'} >= 300) {
        $self->{output}->add_option_msg(short_msg => "Threshold --warning-fields must be lower than 300.");
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{'critical-fields-count'}) && $self->{option_results}->{'critical-fields-count'} >= 300) {
        $self->{output}->add_option_msg(short_msg => "Threshold --critical-fields must be lower than 300.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->api_fields(
        time_period => $self->{option_results}->{time_period},
        query => $self->{option_results}->{query},
        field => $self->{option_results}->{field}
    );

    my ($events, $fields) = (0, 0);

    $self->{field} = {};
    foreach (@{$results->{$self->{option_results}->{field}}}) {
        if (!defined($self->{option_results}->{filter_field}) || ($_->{term} =~ /$self->{option_results}->{filter_field}/i)) {
            $fields++;
            $events += $_->{count};
            $self->{field}->{$fields} = {
                display => $_->{term},
                count => $_->{count}
            };
        }
    }

    $self->{global} = { events => $events, fields => $fields };
}

1;

__END__

=head1 MODE

Count unique field-values from events matching the query.

=over 8

=item B<--time-period>

Set request period, in minutes.

=item B<--query>

Set the query.

=item B<--field>

Set the field to count unique values for (ex: json.host).

=item B<--filter-field>

Set the a field filter.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'events', 'fields', field-events'.

=back

=cut
