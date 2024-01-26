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

package database::mssql::mode::listdatabases;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use database::mssql::mode::resources::types qw($database_state);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "filter-database:s"   => { name => 'filter_database' },
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
    $options{sql}->query(query => q{
        SELECT
            D.name AS [database_name],
            D.state
        FROM sys.databases D
    });

    my $result = $options{sql}->fetchall_arrayref();
    my $databases = {};
    foreach (@$result) {
        next if (defined($self->{option_results}->{filter_database}) && $self->{option_results}->{filter_database} ne '' &&
            $_->[0] !~ /$self->{option_results}->{filter_database}/);

        $databases->{ $_->[0] } = {
            name => $_->[0],
            state => $database_state->{ $_->[1] }
        };
    }

    return $databases;
}

sub run {
    my ($self, %options) = @_;

    my $databases = $self->manage_selection(%options);
    foreach (values %$databases) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[name: %s] [state: %s]',
                $_->{name},
                $_->{state}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List databases:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $databases = $self->manage_selection(%options);
    foreach (values %$databases) {
        $self->{output}->add_disco_entry(%$_);
    }
}

1;

__END__

=head1 MODE

List MSSQL databases

=over 8

=item B<--filter-database>

Filter the databases to monitor with a regular expression.

=back

=cut
