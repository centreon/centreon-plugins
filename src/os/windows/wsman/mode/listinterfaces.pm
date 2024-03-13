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

package os::windows::wsman::mode::listinterfaces;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my @labels = ('name', 'status', 'speed', 'enabled'); 
my $map_status = {
    0  => 'down', 
    1  => 'connecting', 
    2  => 'up', 
    3  => 'disconnecting', 
    4  => 'hardwareNotPresent', 
    5  => 'hardwareDisable', 
    6  => 'hardwarMalfunction', 
    7  => 'mediaDisconnect', 
    8  => 'auth', 
    9  => 'authSucceeded', 
    10 => 'AuthFailed', 
    11 => 'invalidAddress', 
    12 => 'credentialsRequired'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $entries = $options{wsman}->request(
        uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/*',
        wql_filter => 'Select DeviceID, Name, MaxSpeed, NetConnectionStatus, NetEnabled from Win32_NetworkAdapter',
        result_type => 'array'
    );

    my $results = {};
    foreach (@$entries) {
        my $status = (!defined($_->{NetConnectionStatus}) || $_->{NetConnectionStatus} eq '') ? 0 : $_->{NetConnectionStatus};
        $results->{ $_->{DeviceID} } = {
            name => $_->{Name},
            speed => (!defined($_->{MaxSpeed}) || $_->{MaxSpeed} eq '') ? 0 : $_->{MaxSpeed},
            status => $map_status->{$status},
            enabled => (!defined($_->{NetEnabled}) || $_->{NetEnabled} eq '') ? 'false' : $_->{NetEnabled}
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(wsman => $options{wsman});
    foreach my $instance (sort keys %$results) {
        $self->{output}->output_add(long_msg => 
            join('', map("[$_: " . $results->{$instance}->{$_} . ']', @labels))
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List interfaces:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [@labels]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(wsman => $options{wsman});
    foreach (sort keys %$results) {
        $self->{output}->add_disco_entry(
            %{$results->{$_}}
        );
    }
}
1;

__END__

=head1 MODE

List interfaces.

=over 8

=back

=cut
