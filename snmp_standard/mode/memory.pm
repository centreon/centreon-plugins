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

package snmp_standard::mode::memory;

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
                                  "swap"                    => { name => 'check_swap' },
                                  "warning-swap:s"          => { name => 'warning_swap' },
                                  "critical-swap:s"         => { name => 'critical_swap' },
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
    if (defined($self->{option_results}->{check_swap})) {
        if (($self->{perfdata}->threshold_validate(label => 'warning-swap', value => $self->{option_results}->{warning_swap})) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong warning-swap threshold '" . $self->{option_results}->{warning_swap} . "'.");
            $self->{output}->option_exit();
        }
        if (($self->{perfdata}->threshold_validate(label => 'critical-swap', value => $self->{option_results}->{critical_swap})) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong critical-swap threshold '" . $self->{option_results}->{critical_swap} . "'.");
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
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_memTotalReal = '.1.3.6.1.4.1.2021.4.5.0';
    my $oid_memAvailReal = '.1.3.6.1.4.1.2021.4.6.0';
    my $oid_memShared = '.1.3.6.1.4.1.2021.4.13.0';
    my $oid_memBuffer = '.1.3.6.1.4.1.2021.4.14.0';
    my $oid_memCached = '.1.3.6.1.4.1.2021.4.15.0';
    my $oid_memTotalSwap = '.1.3.6.1.4.1.2021.4.3.0'; # KB
    my $oid_memAvailSwap = '.1.3.6.1.4.1.2021.4.4.0'; # KB
    
    my $oids = [$oid_memTotalReal, $oid_memAvailReal,
                $oid_memShared, $oid_memBuffer, $oid_memCached];
    if (defined($self->{option_results}->{check_swap})) {
        push @$oids, ($oid_memTotalSwap, $oid_memAvailSwap);
    }
    my $result = $self->{snmp}->get_leef(oids => $oids, 
                                         nothing_quit => 1);

    my $shared_used = defined($result->{$oid_memShared}) ? $result->{$oid_memShared} * 1024 : 0;
    my $cached_used = $result->{$oid_memCached} * 1024;
    my $buffer_used = $result->{$oid_memBuffer} * 1024;
    my $physical_used = ($result->{$oid_memTotalReal} * 1024) - ($result->{$oid_memAvailReal} * 1024);
    my $nobuf_used = $physical_used - $buffer_used - $cached_used;
    
    my $total_size = $result->{$oid_memTotalReal} * 1024;
    
    my $prct_used = $nobuf_used * 100 / $total_size;
    my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_size);
    my ($nobuf_value, $nobuf_unit) = $self->{perfdata}->change_bytes(value => $nobuf_used);
    my ($buffer_value, $buffer_unit) = $self->{perfdata}->change_bytes(value => $buffer_used);
    my ($cached_value, $cached_unit) = $self->{perfdata}->change_bytes(value => $cached_used);
    my ($shared_value, $shared_unit) = $self->{perfdata}->change_bytes(value => $shared_used);
    
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Ram Total: %s, Used (-buffers/cache): %s (%.2f%%), Buffer: %s, Cached: %s, Shared: %s",
                                            $total_value . " " . $total_unit,
                                            $nobuf_value . " " . $nobuf_unit, $prct_used,
                                            $buffer_value . " " . $buffer_unit,
                                            $cached_value . " " . $cached_unit,
                                            $shared_value . " " . $shared_unit));
    
    $self->{output}->perfdata_add(label => "cached", unit => 'B',
                                  value => $cached_used,
                                  min => 0);
    $self->{output}->perfdata_add(label => "buffer", unit => 'B',
                                  value => $buffer_used,
                                  min => 0);
    $self->{output}->perfdata_add(label => "used", unit => 'B',
                                  value => $nobuf_used,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $total_size, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $total_size, cast_int => 1),
                                  min => 0, max => $total_size);

    if (defined($self->{option_results}->{check_swap})) {
        if ($result->{$oid_memTotalSwap} == 0) {
            $self->{output}->output_add(severity => $self->{no_swap},
                                        short_msg => 'No active swap.');
            $self->{output}->display();
            $self->{output}->exit();
        }
    
        $total_size = $result->{$oid_memTotalSwap} * 1024;
        my $swap_used = ($result->{$oid_memTotalSwap} - $result->{$oid_memAvailSwap}) * 1024;
    
        $prct_used = $swap_used * 100 / $total_size;
        $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical-swap', 'exit_litteral' => 'critical' }, { label => 'warning-swap', exit_litteral => 'warning' } ]);

        my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_size);
        my ($swap_used_value, $swap_used_unit) = $self->{perfdata}->change_bytes(value => $swap_used);
        my ($swap_free_value, $swap_free_unit) = $self->{perfdata}->change_bytes(value => ($total_size - $swap_used));
    
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Swap Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                                            $total_value . " " . $total_unit,
                                            $swap_used_value . " " . $swap_used_unit, $prct_used,
                                            $swap_free_value . " " . $swap_free_unit, (100 - $prct_used)));
    
        $self->{output}->perfdata_add(label => "swap", unit => 'B',
                                      value => $swap_used,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-swap', total => $total_size, cast_int => 1),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-swap', total => $total_size, cast_int => 1),
                                      min => 0, max => $total_size);
    }
                                  
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check physical memory (UCD-SNMP-MIB).

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=item B<--swap>

Check swap also.

=item B<--warning-swap>

Threshold warning in percent.

=item B<--critical-swap>

Threshold critical in percent.

=item B<--no-swap>

Threshold if no active swap (default: 'critical').

=back

=cut
