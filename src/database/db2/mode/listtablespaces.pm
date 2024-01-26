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

package database::db2::mode::listtablespaces;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $order = ['name', 'type', 'datatype'];

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'notemp' => { name => 'notemp' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(query => q{SELECT tbspace, tbspacetype, datatype FROM syscat.tablespaces});
    my $tablespaces = {};
    while (my $row = $options{sql}->fetchrow_arrayref()) {
        if (defined($self->{option_results}->{notemp}) && ($row->[2] eq 'T' || $row->[2] eq 'U')) {
            $self->{output}->output_add(long_msg => "skipping  '" . $row->[0] . "': temporary or undo.", debug => 1);
            next;
        }

        $tablespaces->{ $row->[0] } = {
            name => $row->[0],
            type => $row->[1] =~ /^[dD]/ ? 'dms' : 'sms',
            datatype => $row->[2]
        };
    }

    return $tablespaces;
}

sub run {
    my ($self, %options) = @_;

    my $tablespaces = $self->manage_selection(%options);
    foreach (sort keys %$tablespaces) {
        my $entry = '';
        foreach my $label (@$order) {
            $entry .= '[' . $label . ': ' . $tablespaces->{$_}->{$label} . '] ';
        }
        $self->{output}->output_add(long_msg => $entry);
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List tablespaces:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => $order);
}

sub disco_show {
    my ($self, %options) = @_;

    my $tablespaces = $self->manage_selection(%options);
    foreach (sort keys %$tablespaces) {
        $self->{output}->add_disco_entry(%{$tablespaces->{$_}});
    }
}

1;

__END__

=head1 MODE

List tablespaces.

=over 8

=item B<--notemp>

skip tablespaces for temporary tables.

=back

=cut
