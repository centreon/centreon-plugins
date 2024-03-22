#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package apps::infor::m3::monitor::api::mode::news;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'news [severity: %s] [count: %s] [first seen: %s] [last seen: %s] %s',
        $self->{result_values}->{severity},
        $self->{result_values}->{count},
        $self->{result_values}->{first_seen},
        $self->{result_values}->{last_seen},
        $self->{result_values}->{message}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'News ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', },
        { name => 'news', type => 2, message_multiple => '0 problem(s) detected', display_counter_problem => { nlabel => 'news.problems.current.count', min => 0 },
          group => [ { name => 'entry', skipped_code => { -11 => 1 } } ]
        }
    ];

    foreach (0, 1, 2, 3, 4) {
        push @{$self->{maps_counters}->{global}},
            { label => 'news-severity-' . $_, nlabel => 'news.severity.' . $_ . '.count', display_ok => 0, set => {
                    key_values => [ { name => $_ }, { name => 'total' } ],
                    output_template => 'severity ' . $_ . ': %s',
                    perfdatas => [
                        { template => '%s', min => 0, max => 'total' }
                    ]
                }
            };
    }

    $self->{maps_counters}->{entry} = [
        {
            label => 'status',
            type => 2,
            warning_default => '',
            critical_default => '%{severity} <= 2 || %{message} =~ /Job may be looping/i',
            set => {
                key_values => [
                    { name => 'message' }, { name => 'severity' },
                    { name => 'count' }, { name => 'first_seen' }, { name => 'last_seen' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-message:s' => { name => 'filter_message' },
        'retention:s'      => { name => 'retention' },
        'timezone:s'       => { name => 'timezone', default => 'UTC' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        method => 'GET',
        url_path => '/monitor',
        get_param => ['category=news'],
        force_array => ['news']
    );

    $self->{news} = { global => { entry => {} } };
    $self->{global} = {
        0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0
    };

    my ($i, $current_time) = (1, time());
    my $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});

    foreach my $entry (@{$result->{category}->{news}}) {        
        $entry->{lastSeen} =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)/;
        my $dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6, %$tz);
        my $last_seen = $dt->epoch();

        if (defined($self->{option_results}->{retention})) {
            next if ($current_time - $last_seen > $self->{option_results}->{retention});
        }

        $self->{global}->{total}++;

        next if (defined($self->{option_results}->{filter_message}) && $self->{option_results}->{filter_message} ne '' && $entry->{message} !~ /$self->{option_results}->{filter_message}/);

        $self->{news}->{global}->{entry}->{$i} = {
            message => $entry->{message},
            severity => $entry->{severity},
            count => $entry->{count},
            first_seen => $entry->{firstSeen},
            last_seen => $entry->{lastSeen}
        };
        $self->{global}->{ $entry->{severity} }++;
        $i++;
    }
}

1;

__END__

=head1 MODE

Check news.

=over 8

=item B<--filter-message>

Exclude message not matching expression.

=item B<--warning-status>

Set warning threshold for status.
Can use special variables like: %{status}, %{name}, %{description}.

=item B<--critical-status>

Set critical threshold for status (Default: "%{status} !~ /up/").
Can use special variables like: %{status}, %{name}, %{description}.

=back

=cut