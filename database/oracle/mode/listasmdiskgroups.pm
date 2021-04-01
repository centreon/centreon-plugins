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

package database::oracle::mode::listasmdiskgroups;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

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
    
    $self->{sql}->connect();
    $self->{sql}->query(query => q{
SELECT name, state, type FROM V$ASM_DISKGROUP
});
    $self->{list_dg} = {};
    my $result = $self->{sql}->fetchall_arrayref();
    foreach my $row (@$result) {
        $self->{list_dg}->{$row->[0]} = {
            state => $row->[1],
            type => $row->[2],
        };
    }

    $self->{sql}->disconnect();
}

sub run {
    my ($self, %options) = @_;
    $self->{sql} = $options{sql};

    $self->manage_selection();
    foreach my $name (sort keys %{$self->{list_dg}}) {
        $self->{output}->output_add(long_msg => 
            '[name = ' . $name . '] ' .
            '[state = ' . $self->{list_dg}->{$name}->{state} . '] ' .
            '[type = ' . $self->{list_dg}->{$name}->{type} . '] '
        );
    }
    $self->{output}->output_add(severity => 'OK',
                                short_msg => "List of asm disk groups:");

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'state', 'type']);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{sql} = $options{sql};

    $self->manage_selection();
    foreach my $name (sort keys %{$self->{list_dg}}) {
        $self->{output}->add_disco_entry(
            name => $name,
            state => $self->{list_dg}->{$name}->{state}, 
            type => $self->{list_dg}->{$name}->{type}
        );
    }
}

1;

__END__

=head1 MODE

List asm diskgroup.

=over 8

=back

=cut
