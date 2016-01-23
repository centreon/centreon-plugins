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

package hardware::ups::standard::rfc1628::snmp::mode::inputlines;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %oids = (
    '.1.3.6.1.2.1.33.1.3.3.1.2' => { counter => 'frequence' }, # in dH upsInputFrequency
    '.1.3.6.1.2.1.33.1.3.3.1.3' => { counter => 'voltage' }, # in Volt upsInputVoltage
    '.1.3.6.1.2.1.33.1.3.3.1.4' => { counter => 'current' }, # in dA upsInputCurrent
    '.1.3.6.1.2.1.33.1.3.3.1.5' => { counter => 'power' }, # in Watt upsInputTruePower
);

my $maps_counters = {
    frequence   => { thresholds => {
                                    warning_frequence  =>  { label => 'warning-frequence', exit_value => 'warning' },
                                    critical_frequence =>  { label => 'critical-frequence', exit_value => 'critical' },
                                   },
                     output_msg => 'Frequence : %.2f Hz',
                     factor => 0.1, unit => 'Hz',
                    },
    voltage => { thresholds => {
                                warning_voltage  =>  { label => 'warning-voltage', exit_value => 'warning' },
                                critical_voltage =>  { label => 'critical-voltage', exit_value => 'critical' },
                                },
                 output_msg => 'Voltage : %.2f V',
                 factor => 1, unit => 'V',
                },
    current => { thresholds => {
                                warning_current    =>  { label => 'warning-current', exit_value => 'warning' },
                                critical_current   =>  { label => 'critical-current', exit_value => 'critical' },
                                },
                 output_msg => 'Current : %.2f A',
                 factor => 0.1, unit => 'A',
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
        if ($options{current} =~ /^$oid\.(.*)/) {
            $instance = $1;
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
        $self->{counters_value}->{$instance}->{$oids{$oid}->{counter}} = defined($options{result}->{$oid . '.' . $instance}) ? $options{result}->{$oid . '.' . $instance} : 0;
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    my $oid_upsInputEntry = '.1.3.6.1.2.1.33.1.3.3.1';
    my $result = $self->{snmp}->get_table(oid => $oid_upsInputEntry, nothing_quit => 1);
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
                if (defined($self->{counters_value}->{$instance}->{$_}) && $self->{counters_value}->{$instance}->{$_} =~ /\d/ && $self->{counters_value}->{$instance}->{$_} != 0) {
                    push @exits, $self->{perfdata}->threshold_check(value => $self->{counters_value}->{$instance}->{$_} * $maps_counters->{$_}->{factor}, threshold => [ { label => $maps_counters->{$_}->{thresholds}->{$name}->{label}, 'exit_litteral' => $maps_counters->{$_}->{thresholds}->{$name}->{exit_value} }]);
                }
            }
        }

        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        my $extra_label = '';
        $extra_label = '_' . $instance_output if ($num > 1);

        my $str_output = "Input Line '$instance_output' ";
        my $str_append = '';
        foreach (keys %{$maps_counters}) {
            next if (!defined($self->{counters_value}->{$instance}->{$_}) || $self->{counters_value}->{$instance}->{$_} !~ /\d/ || $self->{counters_value}->{$instance}->{$_} == 0);
            
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

Check Input lines metrics (frequence, voltage, current and true power).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'frequence', 'voltage', 'current', 'power'.

=item B<--critical-*>

Threshold critical.
Can be: 'frequence', 'voltage', 'current', 'power'.

=back

=cut
