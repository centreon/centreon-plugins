#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package apps::graylog::restapi::mode::query;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'queue-messages', nlabel => 'graylog.query.match.count', set => {
                key_values => [ { name => 'queue_messages' } ],
                output_template => 'current queue messages : %s',
                perfdatas => [
                    { label => 'queue_msg', value => 'queue_messages', template => '%d',
                      min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "query:s"       => { name => 'query' },
	"timeframe:s"   => { name => 'timeframe', default => '300'}
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->query_absolute(query => $self->{option_results}->{query},
                                                  timeframe => $self->{option_results}->{timeframe});
    $self->{global} = {
	queue_messages => $result->{total_results}
    };
}

1;

__END__

=head1 MODE

Perform Lucene queries against Graylog API

Example:
perl centreon_plugins.pl --plugin=apps::graylog::restapi::plugin 
--mode=query --hostname=10.0.0.1 --username='username' --password='password' --credentials --query='my query'

More information on https://docs.graylog.org/en/<version>/pages/configuration/rest_api.html

=over 8

=item B<--query>

Set a Lucene query.

=item B<--timeframe>

Set timeframe in seconds (E.g '300' to check last 5 minutes).

=item B<--warning-queue-messages> B<--critical-queue-messages>

Threshold on the number of results.

=back

=cut
