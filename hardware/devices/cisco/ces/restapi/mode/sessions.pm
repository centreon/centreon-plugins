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

package hardware::devices::cisco::ces::restapi::mode::sessions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'sessions-current', nlabel => 'system.sessions.current.count', set => {
                key_values => [ { name => 'sessions' } ],
                output_template => 'total current sessions: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        method => 'POST',
        url_path => '/putxml',
        query_form_post => '<Command><Security><Session><List/></Session></Security></Command>',
        ForceArray => ['Session']
    );

    $self->{global} = { sessions => 0 };

    return if (!defined($result->{SessionListResult}->{Session}));

    foreach (@{$result->{SessionListResult}->{Session}}) {
        $self->{output}->output_add(
            long_msg => sprintf(
                'session [username: %s] [origin: %s] [address: %s]',
                $_->{UserName},
                $_->{Origin},
                $_->{RemoteAddress}
            )
        );
        $self->{global}->{sessions}++;
    }
}

1;

__END__

=head1 MODE

Check sessions (since CE 8.2)

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'sessions-current'.

=back

=cut
