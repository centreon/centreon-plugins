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

package apps::voip::3cx::restapi::mode::extension;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw/:counters :values/;
use centreon::plugins::misc qw/is_excluded is_not_empty int_to_bool/;
use Date::Parse;

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = $self->{result_values}->{registered} eq 'true'
                ? 'registered'
                : 'unregistered';
    if ($self->{result_values}->{dnd} eq 'true') {
        $msg .= ', in DND';
    } else {
        $msg .= ', not in DND';
    }
    $msg .= ', ' . $self->{result_values}->{profile};
    if ($self->{result_values}->{status} ne '') {
        $msg .= ', ' . $self->{result_values}->{status};
        $msg .= ' since ' . sprintf '%02dh %02dm %02ds', (gmtime($self->{result_values}->{duration}))[2,1,0];
    }
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL },
        { name => 'extension', type => COUNTER_TYPE_INSTANCE, prefix_output => "Extension '%{extension}' ", message_multiple => 'All extensions are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'count', nlabel => '3cx.extensions.count', display_ok => 0, set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Extensions count : %{count}',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{extension} = [
        { label => 'status', type => COUNTER_KIND_TEXT, set => {
                key_values => [
                    { name => 'extension' }, { name => 'registered' }, { name => 'dnd' },
                    { name => 'profile' }, { name => 'status' }, { name => 'duration' }
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
        'filter-extension:s'   => { redirect => 'include_extension' },
        'include-extension:s'  => { name => 'include_extension', default => '' },
        'exclude-extension:s'  => { name => 'exclude_extension', default => '' },
        'dnd-profile-name:s'   => { name => 'dnd_profile_name', default => 'DND' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my %status;
    my $activecalls = $options{custom}->api_activecalls();

    foreach my $item (@$activecalls) {
        $status{$item->{Caller}} = {
            Status        => $item->{Status},
            EstablishedAt => $item->{EstablishedAt},
        };
        $status{$item->{Callee}} = {
            Status        => $item->{Status},
            EstablishedAt => $item->{EstablishedAt},
        };
    }

    $self->{global} = { count => 0 };
    my $extension = $options{custom}->api_extension_list();
    $self->{extension} = {};
    foreach my $item (@$extension) {
        # v20: build display string from Number + FirstName + LastName
        $item->{_str} = $item->{Number}
            . (is_not_empty($item->{FirstName}) ? ' ' . $item->{FirstName} : '')
            . (is_not_empty($item->{LastName})  ? ' ' . $item->{LastName}  : '');

        next if is_excluded($item->{_str}, $self->{option_results}->{include_extension}, $self->{option_results}->{exclude_extension}, output => $self->{output});

        $self->{global}->{count}++;

        # v20: DND boolean field no longer exists, derive it from CurrentProfileName
        my $profile  = $item->{CurrentProfileName} // '';
        my $dnd_name = $self->{option_results}->{dnd_profile_name};
        my $is_dnd   = int_to_bool(lc($profile) eq lc($dnd_name));

        $self->{extension}->{$item->{_str}} = {
            extension  => $item->{_str},
            registered => int_to_bool($item->{IsRegistered}),
            dnd        => $is_dnd,
            profile    => $profile,
            status     => $status{$item->{_str}}->{Status} // '',
            duration   => 0
        };

        if (exists $status{$item->{_str}} && $status{$item->{_str}}->{EstablishedAt}) {
            $self->{extension}->{$item->{_str}}->{duration} = time - str2time($status{$item->{_str}}->{EstablishedAt});
        }
    }
}

1;

__END__

=head1 MODE

Check extensions status (3CX v20+)

=over 8

=item B<--include-extension>

Filter extension (by number, first name or last name).

=item B<--exclude-extension>

Exclude extension (by number, first name or last name).

=item B<--dnd-profile-name>

Name of the profile to consider as C<DND> (Do Not Disturb). Default: C<DND>.
In 3CX version 20, the C<DND> boolean field no longer exists. C<DND> status is derived
from the C<CurrentProfileName> field. Use this option to specify the exact
profile name configured in your 3CX instance for C<DND>.
Example: --dnd-profile-name='Do not disturb'

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{extension}, %{registered}, %{dnd}, %{profile}, %{status}, %{duration}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<extension>, C<registered>, C<dnd>, C<profile>, C<status>, C<duration>

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: C<extension>, C<registered>, C<dnd>, C<profile>, C<status>, C<duration>

=item B<--warning-count>

Threshold for extensions count.

=item B<--critical-count>

Threshold for extensions count.

=back

=cut
