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

package centreon::common::dell::fastpath::snmp::mode::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'warning:s'  => { name => 'warning' },
        'critical:s' => { name => 'critical' },
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

    my $oid_agentSwitchCpuProcessMemFree = '.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.1.1.4.1.0'; # in KB
    my $oid_agentSwitchCpuProcessMemAvailable = '.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.1.1.4.2.0'; # in KB

    my $result = $self->{snmp}->get_leef(oids => [$oid_agentSwitchCpuProcessMemFree,
                                                  $oid_agentSwitchCpuProcessMemAvailable],
                                         nothing_quit => 1);
   
    my $memory_free = $result->{$oid_agentSwitchCpuProcessMemFree} * 1024;
    my $memory_available = $result->{$oid_agentSwitchCpuProcessMemAvailable} * 1024;
    my $memory_used = $memory_available - $memory_free;
    my $prct_used = ($memory_used / $memory_available) * 100;
    my $prct_free = ($memory_free / $memory_available) * 100;

    my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    my ($memory_used_value, $memory_used_unit) = $self->{perfdata}->change_bytes(value => $memory_used);
    my ($memory_available_value, $memory_available_unit) = $self->{perfdata}->change_bytes(value => $memory_available);
    my ($memory_free_value, $memory_free_unit) = $self->{perfdata}->change_bytes(value => $memory_free);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Memory used: %s (%.2f%%), Size: %s, Free: %s (%.2f%%)",
                                            $memory_used_value . " " . $memory_used_unit, $prct_used,
                                            $memory_available_value . " " . $memory_available_unit,
                                            $memory_free_value . " " . $memory_free_unit, $prct_free));
    
    $self->{output}->perfdata_add(label => "used", unit => 'B',
                                  value => $memory_used,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $memory_available, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $memory_available, cast_int => 1),
                                  min => 0, max => $memory_available);

    $self->{output}->display();
    $self->{output}->exit();
    
}

1;

__END__

=head1 MODE

Check memory usage (FASTPATH-SWITCHING-MIB).

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
    
