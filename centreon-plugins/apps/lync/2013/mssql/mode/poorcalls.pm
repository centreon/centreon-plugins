#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package apps::lync::2013::mssql::mode::poorcalls;

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
                output_template => '%d Poor calls',
                perfdatas => [
                    { label => 'poor_calls', value => 'count_absolute', template => '%d',
                      unit => 'calls', min => 0, label_extra_instance => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{uri} = [
        { label => 'user', set => {
                key_values => [ { name => 'count' }, { name => 'display' } ],
                output_template => 'count : %d',
                perfdatas => [
                    { label => 'poor_calls', value => 'count_absolute', template => '%d',
                      unit => 'calls', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  'lookback:s' => { name => 'lookback', default => '65' },
                                  'filter-user:s' => { name => 'filter_user' },
                                });
    return $self;
}

sub prefix_uri_output {
    my ($self, %options) = @_;

    return "'" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};
    $self->{sql}->connect();

    $self->{sql}->query(query => "SELECT URI, LastPoorCallTime
                                   FROM [QoEMetrics].[dbo].[User]
                                   WHERE LastPoorCallTime>=dateadd(minute,-".$self->{option_results}->{lookback}.",getdate())");
    my $total;
    while (my $row = $self->{sql}->fetchrow_hashref()) {
        if (defined($self->{option_results}->{filter_user}) && $self->{option_results}->{filter_user} ne '' &&
            $row->{URI} !~ /$self->{option_results}->{filter_user}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $row->{URI} . "': no matching filter.", debug => 1);
            next;
        }
        $self->{global}->{count}++;
        $self->{uri}->{$row->{URI}} = {count => 0, display => $row->{URI}} if (!defined($self->{uri}->{$row->{URI}}));
        $self->{uri}->{$row->{URI}}->{count}++;
    }

}

1;

__END__

=head1 MODE

Check Lync Poor Calls during last X minutes (Total and per users)

=over 8

=item B<--filter-user>

Filter user name (can be a regexp)

=item B<--filter-counters>

Only display some counters (regexp can be used).

=item B<--lookback>

Minutes to lookback (From you to UTC) default: 65

=item B<--warning-*>

Set warning threshold for number of poor calls. Can be : 'total', 'user'

=item B<--critical-*>

Set critical threshold for number of poor calls. Can be : 'total', 'user'

=back

=cut
