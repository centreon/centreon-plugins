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

package os::windows::wsman::mode::listprocesses;

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

my @labels = ('name', 'pid', 'status'); 
my %map_process_status = (
    0 => 'running',
    1 => 'other', 
    2 => 'ready', 
    3 => 'running', 
    4 => 'blocked'
);

sub manage_selection {
    my ($self, %options) = @_;

    my $entries = $options{wsman}->request(
        uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/*',
        wql_filter => 'select Name,ExecutionState,CommandLine,ExecutablePath,Handle from Win32_Process',
        result_type => 'array'
    );

    my $results = [];
    foreach (@$entries) {
        my $status = (!defined($_->{ExecutionState}) || $_->{ExecutionState} eq '') ? 0 : $_->{ExecutionState};
        push @$results, {
            name => $_->{Name},
            status => $map_process_status{$status},
            pid => $_->{Handle}
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(wsman => $options{wsman});
    foreach my $entry (@$results) {
        $self->{output}->output_add(long_msg => 
            join('', map("[$_: " . $entry->{$_} . ']', @labels))
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List processes:'
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
    foreach my $entry (@$results) {
        $self->{output}->add_disco_entry(%$entry);
    }
}
1;

__END__

=head1 MODE

List processes.

=over 8

=back

=cut
