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

package database::mssql::mode::listdatabases;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

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
    
    $self->{sql} = $options{sql};
    $self->{sql}->connect();
    $self->{sql}->query(query => q{DBCC SQLPERF(LOGSPACE)});

    my $result = $self->{sql}->fetchall_arrayref();

    foreach my $database (@$result) {
        if (defined($self->{option_results}->{filter_database}) && $self->{option_results}->{filter_database} ne '' &&
            $$database[0] !~ /$self->{option_results}->{filter_database}/i) {
            next;
        }
        
        $self->{sql}->query(query => "use [" . $$database[0] . "]; exec sp_spaceused;");
        my $result2 = $self->{sql}->fetchall_arrayref();
        
        foreach my $row (@$result2) {
            $self->{databases}->{$$row[0]} = {
                display => $$row[0],
                total => convert_bytes($$row[1]),
            };
        }
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $database (sort keys %{$self->{databases}}) {
        $self->{output}->output_add(long_msg => sprintf("[name = %s] [total = %s]",
                                                         $self->{databases}->{$database}->{display}, $self->{databases}->{$database}->{total}));
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List databases:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name', 'total']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $database (sort keys %{$self->{databases}}) {
        $self->{output}->add_disco_entry(
            name => $self->{databases}->{$database}->{display},
            total => $self->{databases}->{$database}->{total},
        );
    }
}

sub convert_bytes {
    my ($brut) = @_;
    my ($value,$unit) = split(/\s+/,$brut);
    if ($unit =~ /kb*/i) {
        $value = $value * 1024;
    } elsif ($unit =~ /mb*/i) {
        $value = $value * 1024 * 1024;
    } elsif ($unit =~ /gb*/i) {
        $value = $value * 1024 * 1024 * 1024;
    } elsif ($unit =~ /tb*/i) {
        $value = $value * 1024 * 1024 * 1024 * 1024;
    }
    return $value;
}

1;

__END__

=head1 MODE

List MSSQL databases

=over 8

=item B<--filter-database>

Filter database by name (Can be a regex).

=back

=cut
