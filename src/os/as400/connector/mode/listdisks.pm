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

package os::as400::connector::mode::listdisks;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    return $options{custom}->request_api(command => 'listDisks', args => { uuid => 'svc-discovery' });
}

my $map_disk_status = {
    0 => 'noUnitControl', 1 => 'active', 2 => 'failed',
    3 => 'otherDiskSubFailed', 4 => 'hwFailurePerf', 5 => 'hwFailureOk',
    6 => 'rebuilding', 7 => 'noReady', 8 => 'writeProtected', 9 => 'busy',
    10 => 'notOperational', 11 => 'unknownStatus', 12 => 'noAccess',
    13 => 'rwProtected'
};

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach my $entry (@{$results->{result}}) {
        $self->{output}->output_add(
            long_msg => sprintf(
                "[name: %s][status: %s]",
                $entry->{name},
                $map_disk_status->{ $entry->{status} }
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List disks:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'status']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach my $entry (@{$results->{result}}) {
        $self->{output}->add_disco_entry(
            name => $entry->{name},
            status => $map_disk_status->{ $entry->{status} }
        );
    }
}

1;

__END__

=head1 MODE

List disks.

=over 8

=back

=cut
