#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::forcepoint::sdwan::snmp::mode::listdisks;

use strict;
use warnings;

use base qw(centreon::plugins::mode);

use centreon::plugins::misc;

my %map_state = (
    1 => 'online',
    2 => 'offline',
);

my $mapping = {
    hrstorageMount => { oid => '.1.3.6.1.2.1.25.3.8.1.2' },
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
    });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $self->{snmp}->get_table(
        oid => $mapping->{hrstorageMount}->{oid},
        dont_quit => 1
    );
    $self->{disks} = {};

    while (my ($oid, $value) = each %{$snmp_result}) {
        $self->{disks}->{ $oid } = { name => $value };
    }
}

# Sorts the disks hash by name
sub _sort_output {
    my ($self, %disks) = @_;

    sort {
        $self->{disks}->{$a}->{name} cmp $self->{disks}->{$b}->{name}
    } keys %disks;
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();

    foreach my $oid ($self->_sort_output(%{$self->{disks}})) {
        $self->{output}->output_add(long_msg => "[name = " . $self->{disks}->{$oid}->{name} . "]");
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

    $self->{output}->add_disco_format(elements => ['name']);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    foreach my $oid ($self->_sort_output(%{$self->{disks}})) {
        $self->{output}->add_disco_entry(
            name => $self->{disks}->{$oid}->{name},
        );
    }
}

1;

__END__

=head1 MODE

List disks.

=cut
