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

package snmp_standard::mode::swap;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning' },
                                  "critical:s"              => { name => 'critical' },
                                  "no-swap:s"               => { name => 'no_swap' },
                                });
    $self->{no_swap} = 'critical';
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
    if (defined($self->{option_results}->{no_swap}) && $self->{option_results}->{no_swap} ne '') {
        if ($self->{output}->is_litteral_status(status => $self->{option_results}->{no_swap}) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong --no-swap status '" . $self->{option_results}->{no_swap} . "'.");
            $self->{output}->option_exit();
        }
         $self->{no_swap} = $self->{option_results}->{no_swap};
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    my $oid_memTotalSwap = '.1.3.6.1.4.1.2021.4.3.0'; # KB
    my $oid_memAvailSwap = '.1.3.6.1.4.1.2021.4.4.0'; # KB
    my $result = $self->{snmp}->get_leef(oids => [$oid_memTotalSwap, $oid_memAvailSwap], nothing_quit => 1);

    if ($result->{$oid_memTotalSwap} == 0) {
        $self->{output}->output_add(severity => $self->{no_swap},
                                    short_msg => 'No active swap.');
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    my $total_size = $result->{$oid_memTotalSwap} * 1024;
    my $swap_used = ($result->{$oid_memTotalSwap} - $result->{$oid_memAvailSwap}) * 1024;
    
    my $prct_used = $swap_used * 100 / $total_size;
    my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_size);
    my ($swap_used_value, $swap_used_unit) = $self->{perfdata}->change_bytes(value => $swap_used);
    my ($swap_free_value, $swap_free_unit) = $self->{perfdata}->change_bytes(value => ($total_size - $swap_used));
    
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Swap Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                                            $total_value . " " . $total_unit,
                                            $swap_used_value . " " . $swap_used_unit, $prct_used,
                                            $swap_free_value . " " . $swap_free_unit, (100 - $prct_used)));
    
    $self->{output}->perfdata_add(label => "used", unit => 'B',
                                  value => $swap_used,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $total_size, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $total_size, cast_int => 1),
                                  min => 0, max => $total_size);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check swap memory (UCD-SNMP-MIB).

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=item B<--no-swap>

Threshold if no active swap (default: 'critical').

=back

=cut
