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
# Authors : Stéphane Duret <sduret@merethis.com>
#
####################################################################################

package hardware::ups::eaton::mode::outlet;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %oids = (
    '.1.3.6.1.4.1.534.6.6.7.6.3.1.2' => { counter => 'voltage', no_present => 0 }, # in mVolt outletVoltage
    '.1.3.6.1.4.1.534.6.6.7.6.4.1.3' => { counter => 'current', no_present => 0 }, # in mA outletCurrent
    '.1.3.6.1.4.1.534.6.6.7.6.5.1.3' => { counter => 'power', no_present => 0 }, # in Watt outletWatts
);

my $oid_outlets = '.1.3.6.1.4.1.534.6.6.7.6';

my $maps_counters = {
    voltage => { thresholds => {
                                warning_voltage  =>  { label => 'warning-voltage', exit_value => 'warning' },
                                critical_voltage =>  { label => 'critical-voltage', exit_value => 'critical' },
                                },
                 output_msg => 'Voltage : %.2f V',
                 factor => 0.001, unit => 'V',
                },
    current => { thresholds => {
                                warning_current    =>  { label => 'warning-current', exit_value => 'warning' },
                                critical_current   =>  { label => 'critical-current', exit_value => 'critical' },
                                },
                 output_msg => 'Current : %.2f A',
                 factor => 0.001, unit => 'A',
               },
    power   => { thresholds => {
                                warning_power  =>  { label => 'warning-power', exit_value => 'warning' },
                                critical_power  =>  { label => 'critical-power', exit_value => 'critical' },
                               },
                 output_msg => 'Power : %.2f W',
                 factor => 1, unit => 'W',
                },
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });
    foreach (keys %{$maps_counters}) {
        foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
            $options{options}->add_options(arguments => {
                                                         $maps_counters->{$_}->{thresholds}->{$name}->{label} . ':s'    => { name => $name },
                                                        });
        }
    }

    $self->{counters_value} = {};
    $self->{instances_done} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    foreach (keys %{$maps_counters}) {
        foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
            if (($self->{perfdata}->threshold_validate(label => $maps_counters->{$_}->{thresholds}->{$name}->{label}, value => $self->{option_results}->{$name})) == 0) {
                $self->{output}->add_option_msg(short_msg => "Wrong " . $maps_counters->{$_}->{thresholds}->{$name}->{label} . " threshold '" . $self->{option_results}->{$name} . "'.");
                $self->{output}->option_exit();
            }
        }
    }
}

sub build_values {
    my ($self, %options) = @_;
    my $counters_value = {};
    my $instance = undef;
    
    foreach my $oid (keys %oids) {
        #if ($options{current} =~ /^$oid_outlets\.(.*)/) {
        if ($options{current} =~ /^$oid\.(.*)/) {
            $instance = $1;
	    #$instance =~ s/1\.1\.3\.//g;
            last;
        }
    }
    
    # Skip already done
    if (!defined($instance) || defined($self->{instances_done}->{$instance})) {
        return 0;
    }
    
    $self->{instances_done}->{$instance} = 1;
    $self->{counters_value}->{$instance} = {};
    foreach my $oid (keys %oids) {
	my $full_oid = $oid . '.' . $instance;
        $self->{counters_value}->{$instance}->{$oids{$oid}->{counter}} = defined($options{result}->{$oid . '.' . $instance}) ? $options{result}->{$oid . '.' . $instance} : 0;
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    #my $oid_outletName = '.1.3.6.1.4.1.534.6.6.7.6.1.1.3';
    #my $result = $self->{snmp}->get_table(oid => $oid_outletName, nothing_quit => 1);
    my $result = $self->{snmp}->get_table(oid => $oid_outlets, nothing_quit => 1);
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $self->build_values(current => $key, result => $result);
    }

    my $num = scalar(keys %{$self->{instances_done}});
    foreach my $instance (keys %{$self->{instances_done}}) {
        my $instance_output = $instance;
        $instance_output =~ s/\./#/g;
        
        my @exits;
        foreach (keys %{$maps_counters}) {
            foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
                if (defined($self->{counters_value}->{$instance}->{$_}) && $self->{counters_value}->{$instance}->{$_} != 0) {
                    push @exits, $self->{perfdata}->threshold_check(value => $self->{counters_value}->{$instance}->{$_}*$maps_counters->{$_}->{factor}, threshold => [ { label => $maps_counters->{$_}->{thresholds}->{$name}->{label}, 'exit_litteral' => $maps_counters->{$_}->{thresholds}->{$name}->{exit_value} }]);
                }
            }
        }

        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        my $extra_label = '';
        $extra_label = '_' . $instance_output if ($num > 1);

        my $str_output = "Outlet '$instance_output' ";
        my $str_append = '';
        foreach (keys %{$maps_counters}) {
            next if (!defined($self->{counters_value}->{$instance}->{$_})) || $self->{counters_value}->{$instance}->{$_} == 0);
            
            $str_output .= $str_append . sprintf($maps_counters->{$_}->{output_msg}, $self->{counters_value}->{$instance}->{$_} * $maps_counters->{$_}->{factor});
            $str_append = ', ';
            my ($warning, $critical);
            foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
                $warning = $self->{perfdata}->get_perfdata_for_output(label => $maps_counters->{$_}->{thresholds}->{$name}->{label}) if ($maps_counters->{$_}->{thresholds}->{$name}->{exit_value} eq 'warning');
                $critical = $self->{perfdata}->get_perfdata_for_output(label => $maps_counters->{$_}->{thresholds}->{$name}->{label}) if ($maps_counters->{$_}->{thresholds}->{$name}->{exit_value} eq 'critical');
            }

            $self->{output}->perfdata_add(label => $_ . $extra_label, unit => $maps_counters->{$_}->{unit},
                                          value => sprintf("%.2f", $self->{counters_value}->{$instance}->{$_} * $maps_counters->{$_}->{factor}),
                                          warning => $warning,
                                          critical => $critical);
        }
        $self->{output}->output_add(severity => $exit,
                                    short_msg => $str_output);
    }
                                  
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Outlet metrics (voltage, current and power).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'voltage', 'current', 'power'.

=item B<--critical-*>

Threshold critical.
Can be: 'voltage', 'current', 'power'.

=back

=cut
