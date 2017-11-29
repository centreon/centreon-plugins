#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package network::radware::alteon::snmp::mode::sp_cpu;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use List::Util qw(sum);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"               => { name => 'warning', default => '' },
                                  "critical:s"              => { name => 'critical', default => '' },
                                  "detailed"                => { name => 'detailed' }
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    ($self->{warn1s}, $self->{warn4s}, $self->{warn64s}) = split /,/, $self->{option_results}->{warning};
    ($self->{crit1s}, $self->{crit4s}, $self->{crit64s}) = split /,/, $self->{option_results}->{critical};
    
    if (($self->{perfdata}->threshold_validate(label => 'warn1s', value => $self->{warn1s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (1sec) threshold '" . $self->{warn1s} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn4s', value => $self->{warn4s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (4sec) threshold '" . $self->{warn4s} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn64s', value => $self->{warn64s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (64sec) threshold '" . $self->{warn64s} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit1s', value => $self->{crit1s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (1sec) threshold '" . $self->{crit1s} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit4s', value => $self->{crit4s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (4sec) threshold '" . $self->{crit4s} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit64s', value => $self->{crit64s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (64sec) threshold '" . $self->{crit64s} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};


    my $oid_spGAStatsCpuUtilSpIndex = '.1.3.6.1.4.1.1872.2.5.1.2.13.1.1.1';
    my $oid_spGAStatsCpuUtil1Second = '.1.3.6.1.4.1.1872.2.5.1.2.13.1.1.3';
    my $oid_spGAStatsCpuUtil4Second = '.1.3.6.1.4.1.1872.2.5.1.2.13.1.1.4';
    my $oid_spGAStatsCpuUtil64Second = '.1.3.6.1.4.1.1872.2.5.1.2.13.1.1.5';

    my $cpu_indexes = $self->{snmp}->get_table(oid=>$oid_spGAStatsCpuUtilSpIndex);
    $self->{snmp}->load(oids => [ $oid_spGAStatsCpuUtil1Second, $oid_spGAStatsCpuUtil4Second, $oid_spGAStatsCpuUtil64Second ],
                        instances => [ keys %$cpu_indexes ],
                        instance_regexp => '(\d+)$' );
    my $cpu_usage = $self->{snmp}->get_leef(); 

    my @cpu;
    foreach (keys %$cpu_indexes) {
	/(\d+)$/;
	my $i = $1;
	push @cpu, { name => "cpu".$cpu_indexes->{$_}, 
                     1 => $cpu_usage->{"$oid_spGAStatsCpuUtil1Second.$i"}, 
                     4 => $cpu_usage->{"$oid_spGAStatsCpuUtil4Second.$i"}, 
                     64 => $cpu_usage->{"$oid_spGAStatsCpuUtil64Second.$i"} };
    }

    if (! $self->{option_results}->{detailed}) {
	# Do as if we had only one CPU
	my $avg =  { name => 'cpu', 
                   1 => sum(map { $_->{1} } @cpu)/@cpu, 
                   4 => sum(map { $_->{4} } @cpu)/@cpu, 
                   64 => sum(map { $_->{64} } @cpu)/@cpu 
               } ;
	@cpu = ();
	push @cpu, $avg;
    }
    my $exit = 'ok';

    foreach (@cpu) {
        my $exit1 = $self->{perfdata}->threshold_check(value => $_->{1}, 
                           threshold => [ { label => 'crit1s', 'exit_litteral' => 'critical' }, { label => 'warn1s', exit_litteral => 'warning' } ]);
        my $exit4 = $self->{perfdata}->threshold_check(value => $_->{4}, 
                           threshold => [ { label => 'crit4s', 'exit_litteral' => 'critical' }, { label => 'warn1s', exit_litteral => 'warning' } ]);
        my $exit64= $self->{perfdata}->threshold_check(value => $_->{64}, 
                           threshold => [ { label => 'crit64s', 'exit_litteral' => 'critical' }, { label => 'warn1s', exit_litteral => 'warning' } ]);
	$exit = $self->{output}->get_most_critical( status => [ $exit, $exit1, $exit4, $exit64 ] );
   

	my $cpuname=$_->{name};
        $self->{output}->perfdata_add(label => $cpuname."_1s", unit => '%',
                                  value => $_->{1},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1s'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1s'),
                                  min => 0, max => 100);

        $self->{output}->perfdata_add(label => "${cpuname}_4s", unit => '%',
                                  value => $_->{4},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1s'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1s'),
                                  min => 0, max => 100);
        $self->{output}->perfdata_add(label => "${cpuname}_64s", unit => '%',
                                  value => $_->{64},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1s'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1s'),
                                  min => 0, max => 100);
    }

    my $msg = "SP CPU usage: ".join(',',map { sprintf("%.1f%%",$_->{1}) } @cpu)." (1sec),".
                            join(',',map { sprintf("%.1f%%",$_->{4}) } @cpu)." (4sec),".
                            join(',',map { sprintf("%.1f%%",$_->{64}) } @cpu)." (64sec)";
 
    $self->{output}->output_add(severity => $exit,
                                short_msg => $msg);
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check SP cpu usage (ALTEON-CHEETAH-SWITCH-MIB).

=over 8

=item B<--warning>

Threshold warning in percent (1s,4s,64s).

=item B<--critical>

Threshold critical in percent (1s,4s,64s).

=item B<--detailed>

Show SP CPU usage, CPU by CPU.

=back

=cut
    
