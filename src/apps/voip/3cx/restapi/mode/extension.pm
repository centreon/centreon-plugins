#
# Copyright 2024 Centreon (http://www.centreon.com/)
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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use Date::Parse;

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = '';
    if ($self->{result_values}->{registered} eq 'true') {
        $msg .= 'registered';
    } else {
        $msg .= 'unregistered';
    }
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
        { name => 'global', type => 0 },
        { name => 'extension', type => 1, cb_prefix_output => 'prefix_service_output', message_multiple => 'All extensions are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'count', nlabel => '3cx.extensions.count', display_ok => 0, set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Extensions count : %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{extension} = [
        { label => 'status', type => 2, set => {
                key_values => [
                    { name => 'extension' }, { name => 'registered' }, { name => 'dnd' },
                    { name => 'profile' }, { name => 'status' }, { name => 'duration' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return "Extension '" . $options{instance_value}->{extension} ."' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-extension:s'  => { name => 'filter_extension' },
        'dnd-profile-name:s'  => { name => 'dnd_profile_name', default => 'DND' }
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

    my $extension = $options{custom}->api_extension_list();
    $self->{extension} = {};
    foreach my $item (@$extension) {
        # v20: build display string from Number + FirstName + LastName
        $item->{_str} = $item->{Number}
            . (defined($item->{FirstName}) && length($item->{FirstName}) ? ' ' . $item->{FirstName} : '')
            . (defined($item->{LastName})  && length($item->{LastName})  ? ' ' . $item->{LastName}  : '');

        if (defined($self->{option_results}->{filter_extension}) && $self->{option_results}->{filter_extension} ne '' &&
            $item->{_str} !~ /$self->{option_results}->{filter_extension}/) {
            $self->{output}->output_add(long_msg => "skipping extension '" . $item->{_str} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{global}->{count}++;

        # v20: DND boolean field no longer exists, derive it from CurrentProfileName
        my $profile  = defined($item->{CurrentProfileName}) ? $item->{CurrentProfileName} : '';
        my $dnd_name = $self->{option_results}->{dnd_profile_name};
        my $is_dnd   = (lc($profile) eq lc($dnd_name)) ? 'true' : 'false';

        $self->{extension}->{$item->{_str}} = {
            extension  => $item->{_str},
            registered => $item->{IsRegistered} ? 'true' : 'false',
            dnd        => $is_dnd,
            profile    => $profile,
            status     => defined($status{$item->{_str}}->{Status}) ? $status{$item->{_str}}->{Status} : '',
            duration   => 0
        };
        if (defined($status{$item->{_str}}->{EstablishedAt})) {
            $self->{extension}->{$item->{_str}}->{duration} = time - Date::Parse::str2time($status{$item->{_str}}->{EstablishedAt});
        }
    }
}

1;

__END__

=head1 MODE

Check extensions status (3CX v20+)

=over 8

=item B<--filter-extension>

Filter extension (by number, first name or last name).

=item B<--dnd-profile-name>

Name of the profile to consider as DND (Do Not Disturb). Default: 'DND'.
In 3CX v20, the DND boolean field no longer exists. DND status is derived
from the CurrentProfileName field. Use this option to specify the exact
profile name configured in your 3CX instance for DND.
Example: --dnd-profile-name='Do not disturb'

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{extension}, %{registered}, %{dnd}, %{profile}, %{status}, %{duration}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{extension}, %{registered}, %{dnd}, %{profile}, %{status}, %{duration}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{extension}, %{registered}, %{dnd}, %{profile}, %{status}, %{duration}

=item B<--warning-*> B<--critical-*>

Thresholds (can be: 'count').

=back

=cut
