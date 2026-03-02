#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package database::postgres::mode::timesync;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Time::HiRes;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'warning:s'  => { redirect => 'warning-time-offset-seconds' },
        'critical:s' => { redirect => 'critical-time-offset-seconds' }
    });

    return $self;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'offset', nlabel => 'time.offset.seconds', set => {
                key_values => [ { name => 'offset' } ],
                output_template => '%.3fs time diff between servers',
                perfdatas => [
                    { template => '%.3f', min => 0, unit => 's' },
                ],
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();

    $options{sql}->query(query => q{
        SELECT extract(epoch FROM now()) AS epok
    });

    my ($result) = $options{sql}->fetchrow_array();
    $self->{output}->option_exit(short_msg => "Cannot get server time.")
        unless $result;

    my $ltime = Time::HiRes::time();
    my $diff = $result - $ltime;

    $self->{global} = { offset => $diff };
}

1;

__END__

=head1 MODE

Compares the local system time with the time reported by Postgres

=over 8

=item B<--warning-offset>

Warning threshold in seconds. (use a range. it can be -0.3 or +0.3)

=item B<--critical-offset>

Critical threshold in seconds. (use a range. it can be -0.3 or +0.3)

=back

=cut
