#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package snmp_standard::mode::cpu;

use base qw(centreon::plugins::mode);
use List::Util qw[min max];

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
                                  "percore"                 => { name => 'percore', },
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

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
    my $oid_cputable = '.1.3.6.1.2.1.25.3.3.1.2';
    my $result = $self->{snmp}->get_table(oid => $oid_cputable, nothing_quit => 1);
    
    my $exit_code='ok';
    my $cpu = 0;
    my $i = 0;
    my $core_critical = 0;
    my $core_warning = 0;
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /\.([0-9]+)$/;
        my $cpu_num = $1;
        
        $cpu += $result->{$key};

        if (defined($self->{option_results}->{percore})) {
            my $core = $self->{perfdata}->threshold_check(value => $result->{$key},
                                threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
            if($core eq "critical") {
                $core_critical++;
                $exit_code='critical';
            } elsif ($core eq "warning") {
                $core_warning++;
                if ($exit_code eq 'critical') {
                    $exit_code='warning';
                }
            }
        }
        
        $self->{output}->output_add(long_msg => sprintf("CPU $i Usage is %.2f%%", $result->{$key}));
        $self->{output}->perfdata_add(label => 'cpu' . $i, unit => '%',
                                      value => sprintf("%.2f", $result->{$key}),
                                      min => 0, max => 100);
        $i++;
    }

    my $avg_cpu = $cpu / $i;
    my $overall = $self->{perfdata}->threshold_check(value => $avg_cpu, 
                                threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    if($overall eq "critical") {
        $exit_code='critical';
    } elsif ($overall eq "warning" && $exit_code eq 'critical') {
        $exit_code='warning';
    }

    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("%s CPU(s)%s average usage is: %.2f%%", $i, (($core_warning + $core_critical > 0) ? " $core_warning warn $core_critical crit," : ""), $avg_cpu));
    $self->{output}->perfdata_add(label => 'total_cpu_avg', unit => '%',
                                  value => sprintf("%.2f", $avg_cpu),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0, max => 100);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check system CPUs (HOST-RESOURCES-MIB)
(The average, over the last minute, of the percentage 
of time that this processor was not idle)

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=item B<--percore>

Apply thresholds on every core rather than overall.

=back

=cut
