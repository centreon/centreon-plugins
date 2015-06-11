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

package network::extreme::snmp::mode::cpu;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {
    cpu => { 
        '000_5secs'   => { set => {
                        key_values => [ { name => 'extremeCpuMonitorSystemUtilization5secs' }, { name => 'num' }, ],
                        output_template => '5 seconds : %.2f %%',
                        perfdatas => [
                            { label => 'cpu_5secs', value => 'extremeCpuMonitorSystemUtilization5secs_absolute', template => '%.2f',
                              min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'num_absolute' },
                        ],
                    }
               },
        '001_10secs'   => { set => {
                        key_values => [ { name => 'extremeCpuMonitorSystemUtilization10secs' }, { name => 'num' }, ],
                        output_template => '10 seconds : %.2f %%',
                        perfdatas => [
                            { label => 'cpu_10secs', value => 'extremeCpuMonitorSystemUtilization10secs_absolute', template => '%.2f',
                              min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'num_absolute' },
                        ],
                    }
               },
        '002_30secs'   => { set => {
                        key_values => [ { name => 'extremeCpuMonitorSystemUtilization30secs' }, { name => 'num' }, ],
                        output_template => '10 seconds : %.2f %%',
                        perfdatas => [
                            { label => 'cpu_30secs', value => 'extremeCpuMonitorSystemUtilization30secs_absolute', template => '%.2f',
                              min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'num_absolute' },
                        ],
                    }
               },
        '003_1min'   => { set => {
                        key_values => [ { name => 'extremeCpuMonitorSystemUtilization1min' }, { name => 'num' }, ],
                        output_template => '10 seconds : %.2f %%',
                        perfdatas => [
                            { label => 'cpu_1min', value => 'extremeCpuMonitorSystemUtilization1min_absolute', template => '%.2f',
                              min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'num_absolute' },
                        ],
                    }
               },
        '004_5min'   => { set => {
                        key_values => [ { name => 'extremeCpuMonitorSystemUtilization5mins' }, { name => 'num' }, ],
                        output_template => '10 seconds : %.2f %%',
                        perfdatas => [
                            { label => 'cpu_5min', value => 'extremeCpuMonitorSystemUtilization5mins_absolute', template => '%.2f',
                              min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'num_absolute' },
                        ],
                    }
               },
        },
    total => {
        '000_total'   => { set => {
                        key_values => [ { name => 'total' } ],
                        output_template => 'CPU Usage : %.2f %%',
                        perfdatas => [
                            { label => 'cpu_total', value => 'total_absolute', template => '%.2f', min => 0, max => 100, unit => '%' },
                        ],
                    }
               },
    }
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                });                         

    foreach my $key (('cpu', 'total')) {
        foreach (keys %{$maps_counters->{$key}}) {
            my ($id, $name) = split /_/;
            if (!defined($maps_counters->{$key}->{$_}->{threshold}) || $maps_counters->{$key}->{$_}->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                            'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                            'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                               });
            }
            $maps_counters->{$key}->{$_}->{obj} = centreon::plugins::values->new(output => $self->{output}, perfdata => $self->{perfdata},
                                                      label => $name);
            $maps_counters->{$key}->{$_}->{obj}->set(%{$maps_counters->{$key}->{$_}->{set}});
        }
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach my $key (('cpu', 'total')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }    
}

sub check_total {
    my ($self, %options) = @_;
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits = ();
    foreach (sort keys %{$maps_counters->{total}}) {
        my $obj = $maps_counters->{total}->{$_}->{obj};
        $obj->set(instance => 'global');
    
        my ($value_check) = $obj->execute(values => $self->{global});

        if ($value_check != 0) {
            $long_msg .= $long_msg_append . $obj->output_error();
            $long_msg_append = ', ';
            next;
        }
        my $exit2 = $obj->threshold_check();
        push @exits, $exit2;

        my $output = $obj->output();
        $long_msg .= $long_msg_append . $output;
        $long_msg_append = ', ';
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
            $short_msg .= $short_msg_append . $output;
            $short_msg_append = ', ';
        }
        
        $obj->perfdata();
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "Total $short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "Total $long_msg");
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{cpu}}) == 1) {
        $multiple = 0;
    }

    if ($multiple == 1) {
        $self->check_total();
    }
    
    ####
    # By CPU 
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All CPU usages are ok');
    }
    
    foreach my $id (sort keys %{$self->{cpu}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (sort keys %{$maps_counters->{cpu}}) {
            my $obj = $maps_counters->{cpu}->{$_}->{obj};
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(values => $self->{cpu}->{$id});

            if ($value_check != 0) {
                $long_msg .= $long_msg_append . $obj->output_error();
                $long_msg_append = ', ';
                next;
            }
            my $exit2 = $obj->threshold_check();
            push @exits, $exit2;

            my $output = $obj->output();
            $long_msg .= $long_msg_append . $output;
            $long_msg_append = ', ';
            
            if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                $short_msg .= $short_msg_append . $output;
                $short_msg_append = ', ';
            }
            
            $maps_counters->{cpu}->{$_}->{obj}->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "CPU '" . $self->{cpu}->{$id}->{num} . "' Usage $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "CPU '" . $self->{cpu}->{$id}->{num} . "' Usage $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "CPU '" . $self->{cpu}->{$id}->{num} . "' Usage $long_msg");
        }
    }
     
    $self->{output}->display();
    $self->{output}->exit();
}

my $mapping = {
    extremeCpuMonitorSystemUtilization5secs => { oid => '.1.3.6.1.4.1.1916.1.32.1.4.1.5' },
    extremeCpuMonitorSystemUtilization10secs => { oid => '.1.3.6.1.4.1.1916.1.32.1.4.1.6' },
    extremeCpuMonitorSystemUtilization30secs => { oid => '.1.3.6.1.4.1.1916.1.32.1.4.1.7' },
    extremeCpuMonitorSystemUtilization1min => { oid => '.1.3.6.1.4.1.1916.1.32.1.4.1.8' },
    extremeCpuMonitorSystemUtilization5mins => { oid => '.1.3.6.1.4.1.1916.1.32.1.4.1.9' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_extremeCpuMonitorSystemEntry = '.1.3.6.1.4.1.1916.1.32.1.4.1';
    my $oid_extremeCpuMonitorTotalUtilization = '.1.3.6.1.4.1.1916.1.32.1.2'; # without .0
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_extremeCpuMonitorTotalUtilization },
                                                            { oid => $oid_extremeCpuMonitorSystemEntry },
                                                         ],
                                                         , nothing_quit => 1);
    
    $self->{cpu} = {};
    foreach my $oid (keys %{$self->{results}->{$oid_extremeCpuMonitorSystemEntry}}) {
        next if ($oid !~ /^$mapping->{extremeCpuMonitorSystemUtilization1min}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_extremeCpuMonitorSystemEntry}, instance => $instance);
        
        $self->{cpu}->{$instance} = {num => $instance, %$result};
    }

    $self->{global} = { total => $self->{results}->{$oid_extremeCpuMonitorTotalUtilization}->{$oid_extremeCpuMonitorTotalUtilization . '.0'} };
}

1;

__END__

=head1 MODE

Check CPU usages.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'total', '5sec', '10sec', '30sec, '1min', '5min'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', '5sec', '10sec', '30sec, '1min', '5min'.

=back

=cut
