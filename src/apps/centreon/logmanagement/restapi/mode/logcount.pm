#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package apps::centreon::logmanagement::restapi::mode::logcount;

use strict;
use warnings;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_result_output {
    my ($self, %options) = @_;
    return "Log count: " . $self->{result_values}->{count};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'logcount', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{logcount} = [
        { label => 'count', nlabel => 'log.count', set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Log count: %s',
                perfdatas => [
                    { template => '%d', min => 0, unit => 'logs' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'query:s'     => { name => 'query', default => '' },
        'period:i'    => { name => 'period', default => 3600 }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{$_} = $self->{option_results}->{$_} for qw/query period/;

    $self->{output}->option_exit(short_msg => 'Please set --query option.')
        if $self->{query} eq '';

    $self->{output}->option_exit(short_msg => 'Please set a valid --period option.')
        if $self->{period} <= 0;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get_log_count(
        query => $self->{query},
        period => $self->{period},
        interval => $self->{period}  # Use same value for both period and interval
    );

    # Extract the log count from the API response
    # API response format: {"curves":[{"metric":"count","times":[...],"data":[count_value,...],"attributes":[]}]}
    my $count = 0;
    
    # Parse the response to extract the count from curves->data[0]
    if (defined($result->{curves}) && ref($result->{curves}) eq 'ARRAY' && @{$result->{curves}} > 0) {
        my $first_curve = $result->{curves}->[0];
        if (defined($first_curve->{data}) && ref($first_curve->{data}) eq 'ARRAY' && @{$first_curve->{data}} > 0) {
            $count = $first_curve->{data}->[0];
            # Convert to integer if it's a float like 0.0
            $count = int($count) if $count =~ /\.\d+/;
        }
    }
    
    # If we still don't have a count, try fallback methods
    if ($count == 0) {
        # Try alternative response structures
        if (defined($result->{data}->{count})) {
            $count = $result->{data}->{count};
        } elsif (defined($result->{count})) {
            $count = $result->{count};
        } elsif (defined($result->{result}->{count})) {
            $count = $result->{result}->{count};
        }
    }
    
    # If we still can't find the count, show debug info and exit
    if ($count == 0 && (!defined($result->{curves}) || !@{$result->{curves}})) {
        $self->{output}->output_add(long_msg => "API response: " . JSON::XS->new->utf8->encode($result), debug => 1);
        $self->{output}->option_exit(exit_litteral => 'critical', short_msg => "Cannot find log count in API response");
    }

    $self->{logcount} = {
        count => $count
    };
}

1;

__END__

=head1 MODE

Get log count from Centreon Log Management based on query and period.

The plugin parses the API response to extract the log count from the curves data structure.
Expected response format: {"curves":[{"metric":"count","times":[...],"data":[count,...],"attributes":[]}]}

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^count$'

=item B<--query>

Set query to execute (required).
Example: --query='service_name:httpd'

=item B<--period>

Set the time period in seconds (default: 3600, 1 hour). This value is used for both the period and interval parameters in the API request.
Example: --period=86400 (for 24 hours)

=item B<--warning-count>

Threshold warning on the log count.
Example: --warning-count=100

=item B<--critical-count>

Threshold critical on the log count.
Example: --critical-count=500

=back

=cut