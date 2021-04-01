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

package storage::netapp::ontap::snmp::mode::snapshotage;

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
    
    $options{options}->add_options(arguments => {
        'name:s'     => { name => 'name' },
        'regexp'     => { name => 'use_regexp' },
        'warning:s'  => { name => 'warning' },
        'critical:s' => { name => 'critical' },
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
    
