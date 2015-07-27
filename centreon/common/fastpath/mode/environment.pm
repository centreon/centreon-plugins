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

package centreon::common::fastpath::mode::environment;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_boxServicesFansEntry = '.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.43.1.6.1';
my $oid_boxServicesFanItemState = '.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.43.1.6.1.3';
my $oid_boxServicesFanSpeed = '.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.43.1.6.1.4';
my $oid_boxServicesPowSuppliesEntry = '.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.43.1.7.1';
my $oid_boxServicesPowSupplyItemState = '.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.43.1.7.1.3';
my $oid_boxServicesTempSensorsEntry = '.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.43.1.8.1';
my $oid_boxServicesTempSensorTemperature1 = '.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.43.1.8.1.4'; # oid for 6200 series
my $oid_boxServicesTempSensorTemperature2 = '.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.43.1.8.1.5';

my $thresholds = {
    psu => [
        ['notpresent', 'OK'],
        ['operational', 'OK'],
        ['failed', 'CRITICAL'],
        ['powering', 'WARNING'],
        ['nopower', 'CRITICAL'],
        ['notpowering', 'CRITICAL'],
		['incompatible', 'CRITICAL'],
    ],
    fan => [
		['notpresent', 'OK'],
        ['operational', 'OK'],
        ['failed', 'CRITICAL'],
        ['powering', 'WARNING'],
        ['nopower', 'CRITICAL'],
        ['notpowering', 'CRITICAL'],
        ['incompatible', 'CRITICAL'],
    ],
};

my %map_states = (
    1 => 'notpresent',
    2 => 'operational',
    3 => 'failed',
    4 => 'powering',
    5 => 'nopower',
    6 => 'notpowering',
	7 => 'incompatible',
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
								  "warning-temperature:s"   => { name => 'warning_temperature' },
								  "critical-temperature:s"  => { name => 'critical_temperature' },
                                });

    $self->{components} = {};
    $self->{no_components} = undef;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning_temperature', value => $self->{option_results}->{warning_temperature})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning temperature threshold '" . $self->{option_results}->{warning_temperature} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical_temperature', value => $self->{option_results}->{critical_temperature})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical temperature threshold '" . $self->{option_results}->{critical_temperature} . "'.");
       $self->{output}->option_exit();
    }

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
    
    # There is a bug with get_leef and snmpv1.
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                { oid => $oid_boxServicesFansEntry },
                                                { oid => $oid_boxServicesPowSuppliesEntry },
												{ oid => $oid_boxServicesTempSensorsEntry },
                                               ]);

    if ($self->{option_results}->{component} eq 'all') {    
        $self->check_fan();
        $self->check_psu();
		$self->check_temperature();
    } elsif ($self->{option_results}->{component} eq 'fan') {
        $self->check_fan();
    } elsif ($self->{option_results}->{component} eq 'psu') {
        $self->check_psu();
	} elsif ($self->{option_results}->{component} eq 'temperature') {
        $self->check_temperature();
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

sub check_fan {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_boxServicesFansEntry}})) {
        next if ($oid !~ /^$oid_boxServicesFanItemState\.(.*)/);
        my $instance = $1;
        my $fan_state = $self->{results}->{$oid_boxServicesFansEntry}->{$oid_boxServicesFanItemState . '.' . $instance};
		my $fan_speed = $self->{results}->{$oid_boxServicesFansEntry}->{$oid_boxServicesFanSpeed . '.' . $instance};

        next if ($self->check_exclude(section => 'fan', instance => $instance));
        next if ($map_states{$fan_state} eq 'notPresent' && 
                 $self->absent_problem(section => 'fan', instance => $instance));
        
        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' state is %s.",
                                    $instance, $map_states{$fan_state}));
        my $exit = $self->get_severity(section => 'fan', value => $map_states{$fan_state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s' state is %s.", $instance, $map_states{$fan_state}));
        }
		
		$self->{output}->perfdata_add(label => "Fan_$instance",
									  unit => 'rpm',
                                      value => $fan_speed,
                                      min => 0);
    }
}

sub check_psu {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_boxServicesPowSuppliesEntry}})) {
        next if ($oid !~ /^$oid_boxServicesPowSupplyItemState\.(.*)/);
        my $instance = $1;
        my $psu_state = $self->{results}->{$oid_boxServicesPowSuppliesEntry}->{$oid_boxServicesPowSupplyItemState . '.' . $instance};

        next if ($self->check_exclude(section => 'psu', instance => $instance));
        next if ($map_states{$psu_state} eq 'notPresent' && 
                 $self->absent_problem(section => 'psu', instance => $instance));
        
        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Power supply '%s' state is %s.",
                                    $instance, $map_states{$psu_state}));
        my $exit = $self->get_severity(section => 'psu', value => $map_states{$psu_state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power supply '%s' state is %s.", $instance, $map_states{$psu_state}));
        }
    }
}

sub check_temperature {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperature sensors");
    $self->{components}->{temperature} = {name => 'temperature sensors', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_boxServicesTempSensorsEntry}})) {
		my $instance;
        if ($oid =~ /^$oid_boxServicesTempSensorTemperature1\.(.*)/) {
			$instance = $1;
 		} elsif ($oid =~ /^$oid_boxServicesTempSensorTemperature2\.(.*)\.(.*)/) {
			$instance = $1 . '.' . $2;
		} else {
			next;
		}
        my $temperature;

		if (defined($self->{results}->{$oid_boxServicesTempSensorsEntry}->{$oid_boxServicesTempSensorTemperature1 . '.' . $instance})) {
			$temperature = $self->{results}->{$oid_boxServicesTempSensorsEntry}->{$oid_boxServicesTempSensorTemperature1 . '.' . $instance};
		} else {
			$temperature = $self->{results}->{$oid_boxServicesTempSensorsEntry}->{$oid_boxServicesTempSensorTemperature2 . '.' . $instance};
		}

        next if ($self->check_exclude(section => 'temperature', instance => $instance));

		$instance =~ s/(\d+)\.//;

        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Temperature sensor '%s' : %sc.",
                                    $instance, $temperature));
        my $exit = $self->{perfdata}->threshold_check(value => $temperature, threshold => [ { label => 'critical_temperature', 'exit_litteral' => 'critical' }, { label => 'warning_temperature', exit_litteral => 'warning' } ]);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature sensor '%s' : %sc.", $instance, $temperature));
        }

        $self->{output}->perfdata_add(label => "Temperature_$instance",
                                      unit => 'c',
                                      value => $temperature);
    }
}

1;

__END__

=head1 MODE

Check environment (FASTPATH-BOXSERVICES-MIB) (Fans, Power Supplies, Temperature).

=over 8

=item B<--component>

Which component to check (Default: 'all').
Can be: 'psu', 'fan', 'temperature'.

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=psu)
Can also exclude specific instance: --exclude='fan#fan2_unit1#'

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=psu

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='psu,CRITICAL,^(?!(normal)$)'

=item B<--warning-temperature>

Warning threshold for temperature in celsius.

=item B<--critical-temperature>

Critical threshold for temperature in celsius.

=back

=cut
