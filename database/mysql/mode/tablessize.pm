#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package database::mysql::mode::tablessize;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
                                  "db-table:s"              => { name => 'db_table', },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{db_table}) || $self->{option_results}->{db_table} !~ /\./) {
        $self->{output}->add_option_msg(short_msg => "Check --db-table option (mandatory) formatting");
        $self->{output}->option_exit();
    }

    ($self->{db}, $self->{table})  = split(/\./, $self->{option_results}->{db_table}) if (defined ($self->{option_results}->{db_table}));

}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};
    $self->{sql}->connect();

    my $multiple = 0;
    my $query = "SELECT table_name AS NAME, ROUND(data_length+index_length)
                 FROM information_schema.TABLES
                 WHERE table_schema = '" . $self->{db}. "' AND table_name LIKE '" . $self->{table} . "'";

    $self->{sql}->query(query => $query);
    my $result = $self->{sql}->fetchall_arrayref();

    if (!($self->{sql}->is_version_minimum(version => '5'))) {
        $self->{output}->add_option_msg(short_msg => "MySQL version '" . $self->{sql}->{version} . "' is not supported.");
        $self->{output}->option_exit();
    }

    if (scalar (@$result) > 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "All tables are ok.");
        $multiple = 1;
    }

    foreach my $row (@$result) {
        my $exit_code = $self->{perfdata}->threshold_check(value => $$row[1], threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        my ($value, $value_unit) = $self->{perfdata}->change_bytes(value => $$row[1]);
        $self->{output}->output_add(long_msg => sprintf("Table '" . $$row[0] . "' size: %s%s", $value, $value_unit));
        if ($multiple == 0 || !$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf("Table '%s' size is '%i%s'", $$row[0], $value, $value_unit));
        }
        $self->{output}->perfdata_add(label => $$row[0] . '_size', unit => 'B',
                                      value => $$row[1],
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
    }
    $self->{output}->output_add(severity => 'UNKNOWN',
                                short_msg => sprintf("Didn't find table '%s' in '%s' database !", $self->{table}, $self->{db})) if (scalar(@$result) == 0);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check MySQL tables size.

=over 8

=item B<--warning>

Threshold warning in bytes.

=item B<--critical>

Threshold critical in bytes.

=item B<--db-table>

Filter database and table to check  [use '%' wildcard with caution!]
e.g unique : --db-table database.table_name
e.g multiple : --db-table database.table_%

=back

=cut
