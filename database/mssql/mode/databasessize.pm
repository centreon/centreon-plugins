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

package database::mssql::mode::databasessize;

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
                                  "filter:s"                => { name => 'filter', },
                                  "free"                    => { name => 'free', },
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
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{output}->output_add(severity => 'OK',
                                short_msg => "All databases are ok.");

    $self->{sql}->connect();
    $self->{sql}->query(query => q{DBCC SQLPERF(LOGSPACE)});

    my $result = $self->{sql}->fetchall_arrayref();

    my @databases_selected;
    foreach my $row (@$result) {
        next if (defined($self->{option_results}->{filter}) && $$row[0] !~ /$self->{option_results}->{filter}/); 
        push @databases_selected, $$row[0];
    }

    foreach my $database (@databases_selected) {
        $self->{sql}->query(query => "use [$database]; exec sp_spaceused;");
        my $result2 = $self->{sql}->fetchall_arrayref();
        foreach my $row (@$result2) {
            my $size_brut = $$row[1];
            my $size = convert_bytes($size_brut);
            my $free_brut = $$row[2];
            my $free = convert_bytes($free_brut);
            my $use = $size - $free;
            my $percent_use = ($use / $size) * 100;
            my $percent_free = 100 - $percent_use;
            my ($use_value, $use_unit) = $self->{perfdata}->change_bytes(value => $use);
            $self->{output}->output_add(long_msg => sprintf("DB '%s' Size: %s Used: %.2f %s (%.2f%%) Free: %s (%.2f%%)", $database, $size_brut, $use_value, $use_unit, $percent_use, $free_brut, $percent_free));
            if (defined($self->{option_results}->{free})) {
                my $exit_code = $self->{perfdata}->threshold_check(value => $percent_free, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
                if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
                    $self->{output}->output_add(severity => $exit_code,
                                                short_msg => sprintf("DB '%s' Size: %s Free: %s (%.2f%%)", $database, $size_brut, $free_brut, $percent_use));
                }
                $self->{output}->perfdata_add(label => sprintf("db_%s_free",$database),
                                              unit => 'B',
                                              value => int($free),
                                              warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $size, cast_int => 1),
                                              critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $size, cast_int => 1),
                                              min => 0,
                                              max => int($size));
            } else {
                my $exit_code = $self->{perfdata}->threshold_check(value => $percent_use, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
                if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
                    $self->{output}->output_add(severity => $exit_code,
                                                short_msg => sprintf("DB '%s' Size: %s Used: %.2f %s (%.2f%%)", $database, $size_brut, $use_value, $use_unit, $percent_use));
                }
                $self->{output}->perfdata_add(label => sprintf("db_%s_used",$database),
                                              unit => 'B',
                                              value => int($use),
                                              warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $size, cast_int => 1),
                                              critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $size, cast_int => 1),
                                              min => 0,
                                              max => int($size));
            }
        }
    }


    $self->{output}->display();
    $self->{output}->exit();
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

Check MSSQL databases size.

=over 8

=item B<--warning>

Threshold warning in percent used.

=item B<--critical>

Threshold critical in percent used.

=item B<--filter>

Filter database.

=item B<--free>

Check free space instead of used space.

=back

=cut
