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

package storage::qnap::snmp::mode::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"               => { name => 'warning' },
                                  "critical:s"              => { name => 'critical' },
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

sub convert_bytes {
    my ($self, %options) = @_;
    my $multiple = defined($options{network}) ? 1000 : 1024;
    my %units = (K => 1, M => 2, G => 3, T => 4);
    
    if ($options{value} !~ /^\s*([0-9\.\,]+)\s*(.)/) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    output => "Cannot convert value '" . $options{value} . "'");
        $self->{output}->display();
        $self->{output}->exit();
    }
    my ($bytes, $unit) = ($1, uc($2));
    
    for (my $i = 0; $i < $units{$unit}; $i++) {
        $bytes *= $multiple;
    }

    return $bytes;
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_SystemTotalMem = '.1.3.6.1.4.1.24681.1.2.2.0';
    my $oid_SystemFreeMem = '.1.3.6.1.4.1.24681.1.2.3.0';

    my $result = $self->{snmp}->get_leef(
        oids => [ $oid_SystemTotalMem, $oid_SystemFreeMem ],
        nothing_quit => 1
    );
    
    my $total_size = $self->convert_bytes(value => $result->{$oid_SystemTotalMem});
    my $memory_free = $self->convert_bytes(value => $result->{$oid_SystemFreeMem});    
    my $memory_used = $total_size - $memory_free;

    my $prct_used = $memory_used * 100 / $total_size;
    my $prct_free = 100 - $prct_used;

    my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_size);
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $memory_used);
    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $memory_free);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Memory Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                                        $total_value . " " . $total_unit,
                                        $used_value . " " . $used_unit, $prct_used,
                                        $free_value . " " . $free_unit, $prct_free));

    $self->{output}->perfdata_add(
        label => 'used', unit => 'B',
        nlabel => 'memory.usage.bytes',
        value => int($memory_used),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $total_size, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $total_size, cast_int => 1),
        min => 0, max => int($total_size)
    );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check memory usage (NAS.mib).

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
    
