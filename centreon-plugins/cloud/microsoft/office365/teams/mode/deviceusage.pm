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

package cloud::microsoft::office365::teams::mode::deviceusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "Users Count By Device Type : ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'windows', set => {
                key_values => [ { name => 'windows' } ],
                output_template => 'Windows: %d',
                perfdatas => [
                    { label => 'windows', value => 'windows_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'mac', set => {
                key_values => [ { name => 'mac' } ],
                output_template => 'Mac: %d',
                perfdatas => [
                    { label => 'mac', value => 'mac_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'web', set => {
                key_values => [ { name => 'web' } ],
                output_template => 'Web: %d',
                perfdatas => [
                    { label => 'web', value => 'web_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'ios', set => {
                key_values => [ { name => 'ios' } ],
                output_template => 'iOS: %d',
                perfdatas => [
                    { label => 'ios', value => 'ios_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'android-phone', set => {
                key_values => [ { name => 'android_phone' } ],
                output_template => 'Android Phone: %d',
                perfdatas => [
                    { label => 'android_phone', value => 'android_phone_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'windows-phone', set => {
                key_values => [ { name => 'windows_phone' } ],
                output_template => 'Windows Phone: %d',
                perfdatas => [
                    { label => 'windows_phone', value => 'windows_phone_absolute', template => '%d',
                      min => 0 },
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
                                    "filter-counters:s" => { name => 'filter_counters' },
                                    "active-only"       => { name => 'active_only' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->office_get_teams_device_usage();

    $self->{global} = { windows => 0, mac => 0, web => 0, ios => 0, android_phone => 0, windows_phone => 0 };

    foreach my $user (@{$results}) {
        if ($self->{option_results}->{active_only} && defined($user->{'Last Activity Date'}) && $user->{'Last Activity Date'} eq '') {
            $self->{output}->output_add(long_msg => "skipping '" . $user->{'User Principal Name'} . "': no activity.", debug => 1);
            next;
        }

        $self->{global}->{windows}++ if ($user->{'Used Windows'} =~ /Yes/);
        $self->{global}->{mac}++ if ($user->{'Used Mac'} =~ /Yes/);
        $self->{global}->{web}++ if ($user->{'Used Web'} =~ /Yes/);
        $self->{global}->{ios}++ if ($user->{'Used iOS'} =~ /Yes/);
        $self->{global}->{android_phone}++ if ($user->{'Used Android Phone'} =~ /Yes/);
        $self->{global}->{windows_phone}++ if ($user->{'Used Windows Phone'} =~ /Yes/);
    }
}

1;

__END__

=head1 MODE

Check devices usage (reporting period over the last 7 days).

(See link for details about metrics :
https://docs.microsoft.com/en-us/office365/admin/activity-reports/microsoft-teams-device-usage?view=o365-worldwide)

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'windows', 'mac', 'web', 'ios', 'android-phone', 'windows-phone'.

=item B<--critical-*>

Threshold critical.
Can be: 'windows', 'mac', 'web', 'ios', 'android-phone', 'windows-phone'.

=item B<--active-only>

Filter only active entries ('Last Activity' set).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example to hide per user counters: --filter-counters='windows'

=back

=cut
