################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package storage::netapp::snmp::mode::snapshotage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use DateTime;

my $oid_slvMonth = '.1.3.6.1.4.1.789.1.5.5.2.1.2';
my $oid_slvDay = '.1.3.6.1.4.1.789.1.5.5.2.1.3';
my $oid_slvHour = '.1.3.6.1.4.1.789.1.5.5.2.1.4';
my $oid_slvMinutes = '.1.3.6.1.4.1.789.1.5.5.2.1.5';
my $oid_slvName = '.1.3.6.1.4.1.789.1.5.5.2.1.6';
my $oid_slvVolumeName = '.1.3.6.1.4.1.789.1.5.5.2.1.9';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "name:s"          => { name => 'name' },
                                  "regexp"          => { name => 'use_regexp' },
                                  "warning:s"       => { name => 'warning' },
                                  "critical:s"      => { name => 'critical' },
                                });
    $self->{snapshot_id_selected} = [];
    
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

sub manage_selection {
    my ($self, %options) = @_;

    $self->{result_names} = $self->{snmp}->get_table(oid => $oid_slvName, nothing_quit => 1);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{result_names}})) {
        next if ($oid !~ /\.([0-9]+\.[0-9]+)$/);
        my $instance = $1;

        # Get all without a name
        if (!defined($self->{option_results}->{name})) {
            push @{$self->{snapshot_id_selected}}, $instance; 
            next;
        }
        
        if (!defined($self->{option_results}->{use_regexp}) && $self->{result_names}->{$oid} eq $self->{option_results}->{name}) {
            push @{$self->{snapshot_id_selected}}, $instance; 
        }
        if (defined($self->{option_results}->{use_regexp}) && $self->{result_names}->{$oid} =~ /$self->{option_results}->{name}/) {
            push @{$self->{snapshot_id_selected}}, $instance;
        }
    }

    if (scalar(@{$self->{snapshot_id_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No snapshot found for name '" . $self->{option_results}->{name} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    $self->{snmp}->load(oids => [$oid_slvName, $oid_slvMonth, $oid_slvDay, $oid_slvHour, $oid_slvMinutes, $oid_slvVolumeName],
                        instances => $self->{snapshot_id_selected},
                        instance_regexp => '(\d+\.\d+)$');
    my $result = $self->{snmp}->get_leef();
    
    if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All snapshot age are ok.');
    }

    my $count = 0;
    my $now = time();
    foreach my $instance (sort @{$self->{snapshot_id_selected}}) {
        $count++;
        my $name = $self->{result_names}->{$oid_slvName . '.' . $instance};
        my $month = $result->{$oid_slvMonth . '.' . $instance};
        my $day = $result->{$oid_slvDay . '.' . $instance};
        my $hour = $result->{$oid_slvHour . '.' . $instance};
        my $minutes = $result->{$oid_slvMinutes . '.' . $instance};
        my $volume_name = $result->{$oid_slvVolumeName . '.' . $instance};

        my ($sec,$min,$hr,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
        $year = $year + 1900;     
        my $dt = DateTime->new(
                                year       => $year,
                                month      => $month,
                                day        => $day,
                                hour       => $hour,
                                minute     => $minutes,
                                second     => 0,
                                time_zone  => 'local',
        );
        my $distant_time = $dt->epoch;

        my $age = $now - $distant_time;

        # Fix if snapshot was last year
        if ($age < 0) {
            $dt = DateTime->new(
                                year       => $year - 1,
                                month      => $month,
                                day        => $day,
                                hour       => $hour,
                                minute     => $minutes,
                                second     => 0,
                                time_zone  => 'local',
            );
            $distant_time = $dt->epoch;
            $age = $now - $distant_time;
        }

        my $readable_age = centreon::plugins::misc::change_seconds(value => $age);
        $self->{output}->output_add(long_msg => sprintf("Snapshot '%s' age: %s [Volume: %s]", $name, $readable_age, $volume_name));

        my $exit = $self->{perfdata}->threshold_check(value => $age, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Snapshot '%s' age: %s [Volume: %s]", $name, $readable_age, $volume_name));
        }
    }
    
    $self->{output}->perfdata_add(label => 'snapshots',
                                  value => $count,
                                  min => 0);
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check snapshot age of volumes.

=over 8

=item B<--warning>

Threshold warning in seconds.

=item B<--critical>

Threshold critical in seconds.

=item B<--name>

Set the snapshot name.

=item B<--regexp>

Allows to use regexp to filter snapshot name (with option --name).

=back

=cut
    
