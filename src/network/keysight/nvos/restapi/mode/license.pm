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

package network::keysight::nvos::restapi::mode::license;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'License expiration status: ' . $self->{result_values}->{status} . ' [info: ' . $self->{result_values}->{info} . ']';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{status} =~ /MINOR/i',
            critical_default => '%{status} =~ /MAJOR|CRITICAL/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'info' } ],
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
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        method => 'GET',
        endpoint => '/api/system/',
    );

    $self->{global} = {
        status => $result->{subsystem_alarms}->{subsystem_alarms}->{'License Expiration Status'}->{state},
        info => $result->{subsystem_alarms}->{subsystem_alarms}->{'License Expiration Status'}->{info}->[0]
    };
}

1;

__END__

=head1 MODE

Check Keysight license status.

=over 8

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /MINOR/i').
You can use the following variables: %{status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /MAJOR|CRITICAL/i').
You can use the following variables: %{status}

=back

=cut