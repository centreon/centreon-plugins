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

package database::informix::sql::mode::listdatabases;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "exclude:s"               => { name => 'exclude', },
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
SELECT name FROM sysdatabases ORDER BY name
});
    $self->{list_databases} = [];
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        if (defined($self->{option_results}->{exclude}) && $row->{name} !~ /$self->{option_results}->{exclude}/) {
            $self->{output}->output_add(long_msg => "Skipping database '" . centreon::plugins::misc::trim($row->{name}) . "': no matching filter name");
            next;
        }
        push @{$self->{list_databases}}, centreon::plugins::misc::trim($row->{name});
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->manage_selection();
    
    foreach my $name (sort @{$self->{list_databases}}) {
        $self->{output}->output_add(long_msg => "'" . $name . "'");
    }
    $self->{output}->output_add(severity => 'OK',
                                short_msg => "List of databases:");

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name']);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{sql} = $options{sql};

    $self->manage_selection();
    foreach (sort @{$self->{list_databases}}) {
        $self->{output}->add_disco_entry(name => $_);
    }
}

1;

__END__

=head1 MODE

Display databases.

=over 8

=item B<--exclude>

Filter databases.

=back

=cut
