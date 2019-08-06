#
# Copyright 2019 Centreon (http://www.centreon.com/)
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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("%s", $self->{result_values}->{message});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{message} = $options{new_datas}->{$self->{instance} . '_message'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'message' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'time', set => {
                key_values => [ { name => 'time_elapsed' } ],
                output_template => 'Response time %.3fs',
                perfdatas => [
                    { label => 'time', value => 'time_elapsed_absolute', template => '%.3f', unit => 's', min => 0 },
                ],
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
                                "warning-status:s"            => { name => 'warning_status', default => '' },
                                "critical-status:s"           => { name => 'critical_status', default => '%{message} !~ /authentification succeeded/i' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
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
