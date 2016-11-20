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

package storage::synology::snmp::mode::components;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_synoSystempowerStatus = '.1.3.6.1.4.1.6574.1.3.0';
my $oid_synoSystemsystemFanStatus = '.1.3.6.1.4.1.6574.1.4.1.0';
my $oid_synoSystemcpuFanStatus = '.1.3.6.1.4.1.6574.1.4.2.0';
my $oid_synoDisk = '.1.3.6.1.4.1.6574.2.1';
my $oid_synoDiskdiskStatus = '.1.3.6.1.4.1.6574.2.1.1.5';
my $oid_synoSystemsystemStatus = '.1.3.6.1.4.1.6574.1.1.0';
my $oid_synoRaid = '.1.3.6.1.4.1.6574.3.1.1';
my $oid_synoRaidraidName = '.1.3.6.1.4.1.6574.3.1.1.2';
my $oid_synoRaidraidStatus = '.1.3.6.1.4.1.6574.3.1.1.3';

my $thresholds = {
    psu => [
        ['Normal', 'OK'],
        ['Failed', 'CRITICAL'],
    ],
    fan => [
        ['Normal', 'OK'],
        ['Failed', 'CRITICAL'],
    ],
    disk => [
        ['Normal', 'OK'],
        ['Initialized', 'OK'],
        ['NotInitialized', 'OK'],
        ['SystemPartitionFailed', 'CRITICAL'],
        ['Crashed', 'CRITICAL'],
    ],
    raid => [
        ['Normal', 'OK'],
        ['Repairing', 'OK'],
        ['Migrating', 'OK'],
        ['Expanding', 'OK'],
        ['Deleting', 'OK'],
        ['Creating', 'OK'],
        ['RaidSyncing', 'OK'],
        ['RaidParityChecking', 'OK'],
        ['RaidAssembling', 'OK'],
        ['Canceling', 'OK'],
        ['Degrade', 'WARNING'],
        ['Crashed', 'CRITICAL'],
    ],
    system => [
        ['Normal', 'OK'],
        ['Failed', 'CRITICAL'],
    ],
};

my %map_states_fan = (
    1 => 'Normal',
    2 => 'Failed',
);

my %map_states_psu = (
    1 => 'Normal',
    2 => 'Failed',
);

my %map_states_disk = (
    1 => 'Normal',
    2 => 'Initialized',
    3 => 'NotInitialized',
    4 => 'SystemPartitionFailed',
    5 => 'Crashed',
);

my %map_states_raid = (
    1 => 'Normal',
    2 => 'Repairing',
    3 => 'Migrating',
    4 => 'Expanding',
    5 => 'Deleting',
    6 => 'Creating',
    7 => 'RaidSyncing',
    8 => 'RaidParityChecking',
    9 => 'RaidAssembling',
    10 => 'Canceling',
    11 => 'Degrade',
    12 => 'Crashed',
);

my %map_states_system = (
    1 => 'Normal',
    2 => 'Failed',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "exclude:s"               => { name => 'exclude' },
                                  "component:s"             => { name => 'component', default => 'all' },
                                  "no-component:s"          => { name => 'no_component' },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                });

    $self->{components} = {};
    $self->{no_components} = undef;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{no_component})) {
        if ($self->{option_results}->{no_component} ne '') {
            $self->{no_components} = $self->{option_results}->{no_component};
        } else {
            $self->{no_components} = 'critical';
        }
    }

    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }

}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};


    $self->{results} = $self->{snmp}->get_leef(oids => [$oid_synoSystempowerStatus, $oid_synoSystemcpuFanStatus, $oid_synoSystemsystemFanStatus, $oid_synoSystemsystemStatus]);

    if ($self->{option_results}->{component} eq 'all') {
        $self->check_fan_cpu();
        $self->check_fan_psu();
        $self->check_psu();
        $self->check_disk();
        $self->check_system();
        $self->check_raid();
    } elsif ($self->{option_results}->{component} eq 'fan_cpu') {
        $self->check_fan_cpu();
    } elsif ($self->{option_results}->{component} eq 'fan_psu') {
            $self->check_fan_psu();
    } elsif ($self->{option_results}->{component} eq 'psu') {
        $self->check_psu();
    } elsif ($self->{option_results}->{component} eq 'disk') {
        $self->check_disk();
    } elsif ($self->{option_results}->{component} eq 'system') {
        $self->check_status();
    } elsif ($self->{option_results}->{component} eq 'raid') {
        $self->check_raid();
    } else {
        $self->{output}->add_option_msg(short_msg => "Wrong option. Cannot find component '" . $self->{option_results}->{component} . "'.");
        $self->{output}->option_exit();
    }

    my $total_components = 0;
    my $display_by_component = '';
    my $display_by_component_append = '';
    foreach my $comp (sort(keys %{$self->{components}})) {
        # Skipping short msg when no components
        next if ($self->{components}->{$comp}->{total} == 0 && $self->{components}->{$comp}->{skip} == 0);
        $total_components += $self->{components}->{$comp}->{total} + $self->{components}->{$comp}->{skip};
        my $count_by_components = $self->{components}->{$comp}->{total} + $self->{components}->{$comp}->{skip};
        $display_by_component .= $display_by_component_append . $self->{components}->{$comp}->{total} . '/' . $count_by_components . ' ' . $self->{components}->{$comp}->{name};
        $display_by_component_append = ', ';
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %s components are ok [%s].",
                                                     $total_components,
                                                     $display_by_component)
                                );

    if (defined($self->{option_results}->{no_component}) && $total_components == 0) {
        $self->{output}->output_add(severity => $self->{no_components},
                                    short_msg => 'No components are checked.');
    }

    $self->{output}->display();
    $self->{output}->exit();
}

sub check_exclude {
    my ($self, %options) = @_;

    if (defined($options{instance})) {
        if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)${options{section}}[^,]*#\Q$options{instance}\E#/) {
            $self->{components}->{$options{section}}->{skip}++;
            $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section $options{instance} instance."));
            return 1;
        }
    } elsif (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)$options{section}(\s|,|$)/) {
        $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section."));
        return 1;
    }
    return 0;
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default

    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }

    return $status;
}

sub check_fan_cpu {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking cpu fan");
    $self->{components}->{cpu_fan} = {name => 'cpu_fan', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'cpu_fan'));
    $self->{components}->{cpu_fan}->{total}++;

    my $cpu_fan_state =  $self->{results}->{$oid_synoSystemcpuFanStatus};
    $self->{output}->output_add(long_msg => sprintf("CPU Fan state is %s.",
                                      $map_states_fan{$cpu_fan_state}));
    my $exit = $self->get_severity(section => 'fan', value => $map_states_fan{$cpu_fan_state});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("CPU Fan state is %s.", $map_states_fan{$cpu_fan_state}));
    }
}

sub check_fan_psu {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking psu fan");
    $self->{components}->{psu_fan} = {name => 'psu_fan', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'psu_fan'));
    $self->{components}->{psu_fan}->{total}++;

    my $psu_fan_state = $self->{results}->{$oid_synoSystempowerStatus};
    $self->{output}->output_add(long_msg => sprintf("PSU Fan state is %s.",
                                      $map_states_fan{$psu_fan_state}));
    my $exit = $self->get_severity(section => 'fan', value => $map_states_fan{$psu_fan_state});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("PSU Fan state is %s.", $map_states_fan{$psu_fan_state}));
    }
}


sub check_psu {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supply");
    $self->{components}->{psu} = {name => 'psu', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'psu'));
    $self->{components}->{psu}->{total}++;

    my $psu_state = $self->{results}->{$oid_synoSystempowerStatus};
    $self->{output}->output_add(long_msg => sprintf("Power Supply state is %s.",
                                    $map_states_psu{$psu_state}));
    my $exit = $self->get_severity(section => 'psu', value => $map_states_psu{$psu_state});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Power Supply state is %s.", $map_states_psu{$psu_state}));
    }
}

sub check_system {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking system status");
    $self->{components}->{system} = {name => 'system', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'system'));
    $self->{components}->{system}->{total}++;

    my $system_state = $self->{results}->{$oid_synoSystemsystemStatus};
    $self->{output}->output_add(long_msg => sprintf("System status is %s.",
                                    $map_states_system{$system_state}));
    my $exit = $self->get_severity(section => 'system', value => $map_states_system{$system_state});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("System status is %s.", $map_states_system{$system_state}));
    }
}

sub check_disk {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking disk");
    $self->{components}->{disk} = {name => 'disk', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'disk'));


    my $results = $self->{snmp}->get_table(oid => $oid_synoDisk);

    my $instance = 0;

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$results)) {
        next if ($key !~ /^$oid_synoDiskdiskStatus\.(\d+)/);
        my $index = $1;
        $instance = $1;
        my $disk_state = $results->{$oid_synoDiskdiskStatus . '.' . $index};

        next if ($self->check_exclude(section => 'disk', instance => $instance));

        $self->{components}->{disk}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Disk '%s' state is %s.",
                                    $index, $map_states_disk{$disk_state}));
        my $exit = $self->get_severity(section => 'disk', value => $map_states_disk{$disk_state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Disk '%s' state is %s.", $index, $map_states_disk{$disk_state}));
        }
    }
}

sub check_raid {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking raid");
    $self->{components}->{raid} = {name => 'raid', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'raid'));

    my $results = $self->{snmp}->get_table(oid => $oid_synoRaid, start => $oid_synoRaidraidName, end => $oid_synoRaidraidStatus);
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$results)) {
        next if ($key !~ /^$oid_synoRaidraidName\.(.*)/);
        my $id = $1;
        my $instance = $1;
        my $raid_name = $results->{$key};
        my $raid_state = $results->{$oid_synoRaidraidStatus . '.' . $id};

        next if ($self->check_exclude(section => 'raid', instance => $instance));

        $self->{components}->{raid}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Raid '%s' state is %s.",
                                    $raid_name, $map_states_raid{$raid_state}));
        my $exit = $self->get_severity(section => 'raid', value => $map_states_raid{$raid_state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Raid '%s' state is %s.", $raid_name, $map_states_raid{$raid_state}));

        }
    }
}

1;

__END__

=head1 MODE

Check hardware (SYNOLOGY-SYSTEM-MIB, SYNOLOGY-RAID-MIB) (Fans, Power Supplies, Disk status, Raid status, System status).

=over 8

=item B<--component>

Which component to check (Default: 'all').
Can be: 'psu', 'fan_cpu', 'fan_psu', 'disk', 'raid', 'system'.

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=psu)
Can also exclude specific instance: --exclude='psu#1#'

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='psu,CRITICAL,^(?!(on)$)'

=back

=cut

