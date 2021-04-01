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

package centreon::common::microsoft::skype::mssql::mode::poorcalls;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'uri', type => 1, cb_prefix_output => 'prefix_uri_output', message_multiple => 'All users are ok' },

    ];

    $self->{maps_counters}->{global} = [
        { label => 'global', set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Poor Calls: %d',
                perfdatas => [
                    { label => 'poor_calls', value => 'count', template => '%d',
                      unit => 'calls', min => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{uri} = [
        { label => 'user', set => {
                key_values => [ { name => 'count' }, { name => 'display' } ],
                output_template => 'poor calls count: %d',
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                {
                                    "lookback:s"            => { name => 'lookback', default => '65' }, # not used
                                    "timeframe:s"           => { name => 'timeframe', default => '900' },
                                    "filter-user:s"         => { name => 'filter_user' },
                                    "filter-counters:s"     => { name => 'filter_counters', default => '' },
                                });
    return $self;
}

sub prefix_uri_output {
    my ($self, %options) = @_;

    return "User '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{sql} = $options{sql};
    $self->{sql}->connect();

    my $query = "SELECT URI, LastPoorCallTime
                FROM [QoEMetrics].[dbo].[User]
                WHERE LastPoorCallTime > (DATEADD(SECOND,-" . $self->{option_results}->{timeframe} . ",SYSUTCDATETIME()))
                AND LastPoorCallTime < SYSUTCDATETIME()";
    
    $self->{sql}->query(query => $query);

    $self->{global}->{count} = 0;

    while (my $row = $self->{sql}->fetchrow_hashref()) {
        if (defined($self->{option_results}->{filter_user}) && $self->{option_results}->{filter_user} ne '' &&
            $row->{URI} !~ /$self->{option_results}->{filter_user}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $row->{URI} . "': no matching filter.", debug => 1);
            next;
        }
        $self->{global}->{count}++;
        $self->{uri}->{$row->{URI}} = { count => 0, display => $row->{URI} } if (!defined($self->{uri}->{$row->{URI}}));
        $self->{uri}->{$row->{URI}}->{count}++;
    }
}

1;

__END__

=head1 MODE

Check poor calls from SQL Server (Lync 2013, Skype 2015).

=over 8

=item B<--filter-user>

Filter user name (can be a regexp)

=item B<--filter-counters>

Only display some counters (regexp can be used).

=item B<--timeframe>

Set the timeframe to query in seconds (Default: 900)

=item B<--warning-global>

Set warning threshold for number of poor calls.

=item B<--critical-global>

Set critical threshold for number of poor calls.

=back

=cut
