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

package apps::mq::vernemq::restapi::mode::sessions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_session_output {
    my ($self, %options) = @_;

    return 'Sessions ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_session_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'online', nlabel => 'sessions.online.count', set => {
                key_values => [ { name => 'online' } ],
                output_template => 'current online: %s',
                perfdatas => [
                    { value => 'online', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'total', nlabel => 'sessions.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'current total: %s',
                perfdatas => [
                    { value => 'total', template => '%s', min => 0 }
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
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $sessions = $options{custom}->request_api(
        endpoint => '/session/show'
    );

    $self->{global} = { total => 0, online => 0 };
    foreach (@{$sessions->{table}}) {
        $self->{global}->{online}++ if ($_->{is_online});
        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check sessions.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total', 'online'.

=back

=cut
