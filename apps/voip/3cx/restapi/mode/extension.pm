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
        'filter-extension:s' => { name => 'filter_extension' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my %status;
    my $activecalls = $options{custom}->api_activecalls();
    foreach my $item (@$activecalls) {
        $status{$item->{Caller}} = {
            Status => $item->{Status},
            Duration => $item->{Duration},
            EstablishedAt => $item->{EstablishedAt},
        };
        $status{$item->{Callee}} = {
            Status => $item->{Status},
            Duration => $item->{Duration},
            EstablishedAt => $item->{EstablishedAt},
        };
    }

    my $extension = $options{custom}->api_extension_list();
    $self->{extension} = {};
    foreach my $item (@$extension) {
        if (!defined($item->{_str})) { # 3CX >= 16.0.6.641
            $item->{_str} = $item->{Number} . (length($item->{FirstName}) ? ' ' . $item->{FirstName} : '') . (length($item->{LastName}) ? ' ' . $item->{LastName} : '');
        }
        if (defined($self->{option_results}->{filter_extension}) && $self->{option_results}->{filter_extension} ne '' &&
            $item->{_str} !~ /$self->{option_results}->{filter_extension}/) {
            $self->{output}->output_add(long_msg => "skipping extension '" . $item->{_str} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{global}->{count}++;

        $self->{extension}->{$item->{_str}} = {
            extension => $item->{_str},
            registered => $item->{IsRegistered} ? 'true' : 'false',
            dnd => $item->{DND} ? 'true' : 'false',
            profile => $item->{CurrentProfile},
            status => $status{$item->{_str}}->{Status} ? $status{$item->{_str}}->{Status} : '',
            duration => 0
        };
        if (defined($status{$item->{_str}}->{EstablishedAt})) { # 3CX >= 16.0.6.641 (#2020-09-08T08:26:05+00:00)
            $self->{extension}->{$item->{_str}}->{duration} = time - Date::Parse::str2time($status{$item->{_str}}->{EstablishedAt});
        } elsif (defined($status{$item->{_str}}->{Duration}) && $status{$item->{_str}}->{Duration} =~ /(\d\d):(\d\d):(\d\d).*/) {
            $self->{extension}->{$item->{_str}}->{duration} = $1 * 3600 + $2 * 60 + $3;
        }
    }
}

1;

__END__

=head1 MODE

Check extentions status

=over 8

=item B<--filter-extension>

Filter extension.

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{extension}, %{registered}, %{dnd}, %{profile}, %{status}, %{duration}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{extension}, %{registered}, %{dnd}, %{profile}, %{status}, %{duration}

=item B<--critical-status>

Set critical threshold for status.
Can used special variables like: %{extension}, %{registered}, %{dnd}, %{profile}, %{status}, %{duration}

=item B<--warning-*> B<--critical-*>

Thresholds (Can be: 'count').

=back

=cut
