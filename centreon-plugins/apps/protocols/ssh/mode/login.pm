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

package apps::protocols::ssh::mode::login;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf('%s', $self->{result_values}->{message});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];
    $self->{maps_counters}->{global} = [
        { 
            label => 'status', 
            type => 2,
            critical_default => '%{message} !~ /authentification succeeded/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'message' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'time', nlabel => 'response.time.seconds' , set => {
                key_values => [ { name => 'time_elapsed' } ],
                output_template => 'Response time %.3fs',
                perfdatas => [
                    { label => 'time', template => '%.3f', unit => 's', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $timing0 = [gettimeofday];
    my $result = $options{custom}->login();
    my $timeelapsed = tv_interval($timing0, [gettimeofday]);
    $self->{global} = { %$result, time_elapsed => $timeelapsed };
}

1;

__END__

=head1 MODE

Check SSH connection.

=over 8

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{message}

=item B<--critical-status>

Set critical threshold for status (Default: '%{message} !~ /authentification succeeded/i'
Can used special variables like: %{status}, %{message}

=item B<--warning-time>

Threshold warning in seconds.

=item B<--critical-time>

Threshold critical in seconds.

=back

=cut
