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

package centreon::common::fortinet::fortigate::mode::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_fgHaSystemMode = '.1.3.6.1.4.1.12356.101.13.1.1'; # '.0' to have the mode
my $oid_fgHaStatsMemUsage = '.1.3.6.1.4.1.12356.101.13.2.1.1.4';
my $oid_fgHaStatsMasterSerial = '.1.3.6.1.4.1.12356.101.13.2.1.1.16';

my %maps_ha_mode = (
    1 => 'standalone',
    2 => 'activeActive',
    3 => 'activePassive',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
                                  "cluster"                 => { name => 'cluster', },
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

sub memory_ha {
    my ($self, %options) = @_;

    if ($options{ha_mode} == 2) {
        # We don't care. we use index
        foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$self->{result}->{$oid_fgHaStatsMemUsage}})) {
            next if ($key !~ /^$oid_fgHaStatsMemUsage\.([0-9]+)$/);
            my $num = $1;
        
            $self->{output}->output_add(long_msg => sprintf("Memory master $num Usage is %.2f%%", $self->{result}->{$oid_fgHaStatsMemUsage}->{$key}));
            $self->{output}->perfdata_add(label => 'used_master' . $num, unit => '%',
                                          value => sprintf("%.2f", $self->{result}->{$oid_fgHaStatsMemUsage}->{$key}),
                                          min => 0, max => 100);
        }
    } elsif ($options{ha_mode} == 3) {
        if (scalar(keys %{$self->{result}->{$oid_fgHaStatsMasterSerial}}) == 0) {
            $self->{output}->output_add(long_msg => 'Skip memory cluster: Cannot find master node.');
        }

        foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$self->{result}->{$oid_fgHaStatsMemUsage}})) {
            next if ($key !~ /^$oid_fgHaStatsMemUsage\.([0-9]+)$/);

            my $label = $self->{result}->{$oid_fgHaStatsMasterSerial}->{$oid_fgHaStatsMasterSerial . '.' . $1} eq '' ? 
                            'master' : 'slave';
            
            $self->{output}->output_add(long_msg => sprintf("Memory %s Usage is %.2f%%", $label, $self->{result}->{$oid_fgHaStatsMemUsage}->{$key}));
            $self->{output}->perfdata_add(label => 'used_' . $label, unit => '%',
                                          value => sprintf("%.2f", $self->{result}->{$oid_fgHaStatsMemUsage}->{$key}),
                                          min => 0, max => 100);
        }
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_fgSystemInfo = '.1.3.6.1.4.1.12356.101.4.1';
    my $oid_fgSysMemUsage = '.1.3.6.1.4.1.12356.101.4.1.4';
    my $oid_fgSysMemCapacity = '.1.3.6.1.4.1.12356.101.4.1.5';

    my $table_oids = [ { oid => $oid_fgSystemInfo, start => $oid_fgSysMemUsage, end => $oid_fgSysMemCapacity } ];
    if (defined($self->{option_results}->{cluster})) {
        push @$table_oids, { oid => $oid_fgHaSystemMode },
                           { oid => $oid_fgHaStatsMemUsage },
                           { oid => $oid_fgHaStatsMasterSerial };
    }

    $self->{result} = $self->{snmp}->get_multiple_table(oids => $table_oids, 
                                                        nothing_quit => 1);
    
    my $fgSysMemUsage = $self->{result}->{$oid_fgSystemInfo}->{$oid_fgSysMemUsage . '.0'};
    my $fgSysMemCapacity = $self->{result}->{$oid_fgSystemInfo}->{$oid_fgSysMemCapacity . '.0'};
    
    my $exit = $self->{perfdata}->threshold_check(value => $fgSysMemUsage, 
                                                  threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    my ($size_value, $size_unit) = $self->{perfdata}->change_bytes(value => $fgSysMemCapacity * 1024);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Memory Usage: %.2f%% used [Total: %s]", 
                                                     $fgSysMemUsage, $size_value . " " . $size_unit));
    $self->{output}->perfdata_add(label => "used", unit => 'B',
                                  value => int(($fgSysMemCapacity * 1024 * $fgSysMemUsage) / 100),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $fgSysMemCapacity * 1024, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $fgSysMemCapacity * 1024, cast_int => 1),
                                  min => 0, max => $fgSysMemCapacity * 1024);
    
    if (defined($self->{option_results}->{cluster})) {
        # Check if mode cluster
        my $ha_mode = $self->{result}->{$oid_fgHaSystemMode}->{$oid_fgHaSystemMode . '.0'};
        my $ha_output = defined($maps_ha_mode{$ha_mode}) ? $maps_ha_mode{$ha_mode} : 'unknown';
        $self->{output}->output_add(long_msg => 'High availabily mode is ' . $ha_output . '.');
        if (defined($ha_mode) && $ha_mode != 1) {
            $self->memory_ha(ha_mode => $ha_mode);
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check system memory usage (FORTINET-FORTIGATE).

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=item B<--cluster>

Add cluster memory informations.

=back

=cut