#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package database::oracle::mode::asmdiskgroupusage;

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
                                  "warning:s"           => { name => 'warning', },
                                  "critical:s"          => { name => 'critical', },
                                  "filter:s"            => { name => 'filter', },
                                  "free"                => { name => 'free', },
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
    $self->{sql} = $options{sql};

    $self->{output}->output_add(severity => 'OK',
                                short_msg => "All diskgroup are ok.");

    $self->{sql}->connect();
    my $query = q{SELECT name, state, type, total_mb, usable_file_mb, offline_disks FROM V$ASM_DISKGROUP};
    $self->{sql}->query(query => $query);
    my $result = $self->{sql}->fetchall_arrayref();

    foreach my $row (@$result) {
        my ($name, $state, $type, $total_mb, $usable_file_mb, $offline_disks) = @$row;
        next if (defined($self->{option_results}->{filter}) && $name !~ /$self->{option_results}->{filter}/);
        $state = lc $state;
        $type = lc $type;
        my ($percent_used, $percent_free, $used, $free, $size);
        $percent_used = ($total_mb - $usable_file_mb) / $total_mb * 100;
        $size = $total_mb * 1024 * 1024;
        $free = $usable_file_mb * 1024 * 1024;
        $used = $size - $free;
        $percent_free = 100 - $percent_used;

        my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $used);
        my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $free);
        my ($size_value, $size_unit) = $self->{perfdata}->change_bytes(value => $size);


        if ( ($offline_disks > 0 && $type eq 'extern' ) || ($offline_disks > 1 && $type eq 'high' ) ) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("dg %s has %s offline disks", $name, $offline_disks));
        } elsif ($offline_disks > 0 && ($type eq 'normal' || $type eq 'high') ) {
            $self->{output}->output_add(severity => 'WARNING',
                                    short_msg => sprintf("dg %s has %s offline disks", $name, $offline_disks));
        }

        if ($state eq 'mounted' || $state eq 'dismounted' || $state eq 'connected') {
            if (defined($self->{option_results}->{free})) {
                my $exit_code = $self->{perfdata}->threshold_check(value => $percent_free, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
                if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
                    $self->{output}->output_add(severity => $exit_code,
                                            short_msg => sprintf("dg '%s' Free: %.2f%s (%.2f%%) Size: %.2f%s", $name, $free_value, $free_unit, $percent_free, $size_value, $size_unit));
                }
                $self->{output}->perfdata_add(label => sprintf("dg_%s_free",lc $name),
                                          unit => 'B',
                                          value => $free,
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $size, cast_int => 1),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $size, cast_int => 1),
                                          min => 0,
                                          max => $size);
            } else {
                my $exit_code = $self->{perfdata}->threshold_check(value => $percent_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
                if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
                    $self->{output}->output_add(severity => $exit_code,
                                            short_msg => sprintf("dg '%s' Used: %.2f%s (%.2f%%) Size: %.2f%s", $name, $used_value, $used_unit, $percent_used, $size_value, $size_unit));
                }
                $self->{output}->perfdata_add(label => sprintf("dg_%s_usage",lc $name),
                                          unit => 'B',
                                          value => $used,
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $size, cast_int => 1),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $size, cast_int => 1),
                                          min => 0,
                                          max => $size);
            }
        }
        else {
            $self->{output}->output_add(severity => 'CRITICAL',
                short_msg => sprintf("dg %s has a problem, state is %s", $name, $state));
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Oracle ASM diskgroup usage and statut.

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--filter>

Filter diskgroup.

=item B<--free>

Check free space instead of used space.

=back

=cut
