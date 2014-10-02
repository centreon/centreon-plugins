################################################################################
# Copyright 2005-2014 MERETHIS
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

package storage::qnap::snmp::mode::hardware;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_CPU_Temperature_entry = '.1.3.6.1.4.1.24681.1.2.5';
my $oid_CPU_Temperature = '.1.3.6.1.4.1.24681.1.2.5.0';
my $oid_SystemTemperature_entry = '.1.3.6.1.4.1.24681.1.2.6';
my $oid_SystemTemperature = '.1.3.6.1.4.1.24681.1.2.6.0';
my $oid_HdDescr = '.1.3.6.1.4.1.24681.1.2.11.1.2';
my $oid_HdTemperature = '.1.3.6.1.4.1.24681.1.2.11.1.3';
my $oid_HdStatus = '.1.3.6.1.4.1.24681.1.2.11.1.4';
my $oid_SysFanDescr = '.1.3.6.1.4.1.24681.1.2.15.1.2';
my $oid_SysFanSpeed = '.1.3.6.1.4.1.24681.1.2.15.1.3';

my $thresholds = {
    disk => [
        ['noDisk', 'OK'],
        ['ready', 'OK'],
        ['invalid', 'CRITICAL'],
        ['rwError', 'CRITICAL'],
        ['unknown', 'UNKNOWN'],
    ],
};

my %map_states_disk = (
    0 => 'ready',
    '-5' => 'noDisk',
    '-6' => 'invalid',
    '-9' => 'rwError',
    '-4' => 'unknown',
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
                                  "absent-problem:s"        => { name => 'absent' },
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
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                { oid => $oid_CPU_Temperature_entry },
                                                { oid => $oid_SystemTemperature_entry },
                                                { oid => $oid_HdDescr },
                                                { oid => $oid_HdTemperature },
                                                { oid => $oid_HdStatus },
                                                { oid => $oid_SysFanDescr },
                                                { oid => $oid_SysFanSpeed },
                                               ]);

    if ($self->{option_results}->{component} eq 'all') {    
        $self->check_temperature();
        $self->check_disk();
        $self->check_fan();
    } elsif ($self->{option_results}->{component} eq 'temperature') {
        $self->check_temperature();
    } elsif ($self->{option_results}->{component} eq 'disk') {
        $self->check_disk();
    } elsif ($self->{option_results}->{component} eq 'fan') {
        $self->check_fan();
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

sub absent_problem {
    my ($self, %options) = @_;
    
    if (defined($self->{option_results}->{absent}) && 
        $self->{option_results}->{absent} =~ /(^|\s|,)($options{section}(\s*,|$)|${options{section}}[^,]*#\Q$options{instance}\E#)/) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("Component '%s' instance '%s' is not present", 
                                                         $options{section}, $options{instance}));
    }

    $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section $options{instance} instance (not present)"));
    $self->{components}->{$options{section}}->{skip}++;
    return 1;
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

sub check_disk {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking disks");
    $self->{components}->{disk} = {name => 'disks', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'disk'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_HdDescr}})) {
        $oid =~ /\.(\d+)$/;
        my $instance = $1;
        my $disk_descr = $self->{results}->{$oid_HdDescr}->{$oid};
        my $disk_state = $self->{results}->{$oid_HdStatus}->{$oid_HdStatus . '.' . $instance};
        my $disk_temp = defined($self->{results}->{$oid_HdTemperature}->{$oid_HdTemperature . '.' . $instance}) ? 
                            $self->{results}->{$oid_HdTemperature}->{$oid_HdTemperature . '.' . $instance} : 'unknown';

        next if ($self->check_exclude(section => 'disk', instance => $instance));
        next if ($map_states_disk{$disk_state} eq 'noDisk' && 
                 $self->absent_problem(section => 'instance', instance => $instance));
        
        $self->{components}->{disk}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Disk '%s' [instance: %s, temperature: %s] state is %s.",
                                    $disk_descr, $instance, $disk_temp, $map_states_disk{$disk_state}));
        my $exit = $self->get_severity(section => 'disk', value => $map_states_disk{$disk_state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Disk '%s' state is %s.", $disk_descr, $map_states_disk{$disk_state}));
        }
        
        if ($disk_temp =~ /([0-9]+)\s*C/) {
            $self->{output}->perfdata_add(label => 'temp_disk_' . $instance, unit => 'C',
                                          value => $1
                                          );
        }
    }
}

sub check_temperature {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'temperature'));

    my $cpu_temp = defined($self->{results}->{$oid_CPU_Temperature_entry}->{$oid_CPU_Temperature}) ? 
                           $self->{results}->{$oid_CPU_Temperature_entry}->{$oid_CPU_Temperature} : 'unknown';
    if ($cpu_temp =~ /([0-9]+)\s*C/ && !$self->check_exclude(section => 'temperature', instance => 'cpu')) {
        my $value = $1;
        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("CPU Temperature is '%s' Celsisus",
                                                        $value));
        $self->{output}->perfdata_add(label => 'temp_cpu', unit => 'C',
                                      value => $value
                                      );
    }
    
    my $system_temp = defined($self->{results}->{$oid_SystemTemperature_entry}->{$oid_SystemTemperature}) ? 
                           $self->{results}->{$oid_SystemTemperature_entry}->{$oid_SystemTemperature} : 'unknown';
    if ($system_temp =~ /([0-9]+)\s*C/ && !$self->check_exclude(section => 'temperature', instance => 'system')) {
        my $value = $1;
        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("System Temperature is '%s' Celsius",
                                                        $value));
        $self->{output}->perfdata_add(label => 'temp_system', unit => 'C',
                                      value => $value
                                      );
    }
}

sub check_fan {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_SysFanDescr}})) {
        $oid =~ /\.(\d+)$/;
        my $instance = $1;
        my $fan_descr = $self->{results}->{$oid_SysFanDescr}->{$oid};
        my $fan_speed = defined($self->{results}->{$oid_SysFanSpeed}->{$oid_SysFanSpeed . '.' . $instance}) ? 
                            $self->{results}->{$oid_SysFanSpeed}->{$oid_SysFanSpeed . '.' . $instance} : 'unknown';

        next if ($self->check_exclude(section => 'fan', instance => $instance));
        
        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' [instance: %s] speed is '%s'.",
                                    $fan_descr, $instance, $fan_speed));

        if ($fan_speed =~ /([0-9]+)\s*rpm/i) {
            $self->{output}->perfdata_add(label => 'fan_' . $instance, unit => 'rpm',
                                          value => $1
                                          );
        }
    }
}

1;

__END__

=head1 MODE

Check hardware (NAS.mib) (Fans, Temperatures, Disks).

=over 8

=item B<--component>

Which component to check (Default: 'all').
Can be: 'fan', 'disk', 'temperature'.

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=disk)
Can also exclude specific instance: --exclude='disk#1#'

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=disk

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='disk,CRITICAL,^(?!(ready)$)'

=back

=cut
    
