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

package os::windows::snmp::mode::swap;

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
        'real-swap'  => { name => 'real_swap' },
    });

    $self->{swap_memory_id} = undef;
    $self->{physical_memory_id} = undef;

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

    my $oid_hrStorageDescr = '.1.3.6.1.2.1.25.2.3.1.3';

    my $result = $self->{snmp}->get_table(oid => $oid_hrStorageDescr);

    foreach my $key (keys %$result) {
        next if ($key !~ /\.([0-9]+)$/);
        my $oid = $1;
        if ($result->{$key} =~ /^Virtual memory$/i) {
            $self->{swap_memory_id} = $oid;
        }
        if ($result->{$key} =~ /^Physical (memory|RAM)$/i) {
            $self->{physical_memory_id} = $oid;
        }
    }

    if (!defined($self->{swap_memory_id})) {
        $self->{output}->add_option_msg(short_msg => "Cannot find virtual memory informations.");
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{real_swap}) && !defined($self->{physical_memory_id})) {
        $self->{output}->add_option_msg(short_msg => "Cannot find physical memory informations.");
        $self->{output}->option_exit();
    }

    my $oid_hrStorageAllocationUnits = '.1.3.6.1.2.1.25.2.3.1.4';
    my $oid_hrStorageSize = '.1.3.6.1.2.1.25.2.3.1.5';
    my $oid_hrStorageUsed = '.1.3.6.1.2.1.25.2.3.1.6';

    my ($physicalSize, $physicalUsed, $physicalUnits) = (0, 0, 0);
    if (defined($self->{option_results}->{real_swap})) {
        $self->{snmp}->load(oids => [$oid_hrStorageAllocationUnits, $oid_hrStorageSize, $oid_hrStorageUsed],
                            instances => [$self->{physical_memory_id}]);
        $result = $self->{snmp}->get_leef();
        $physicalSize = $result->{$oid_hrStorageSize . "." . $self->{physical_memory_id}};
        $physicalUsed = $result->{$oid_hrStorageUsed . "." . $self->{physical_memory_id}};
        $physicalUnits = $result->{$oid_hrStorageAllocationUnits . "." . $self->{physical_memory_id}};
    }

    $self->{snmp}->load(oids => [$oid_hrStorageAllocationUnits, $oid_hrStorageSize, $oid_hrStorageUsed],
                        instances => [$self->{swap_memory_id}]);
    $result = $self->{snmp}->get_leef();

    my $swap_used = ($result->{$oid_hrStorageUsed . "." . $self->{swap_memory_id}} * $result->{$oid_hrStorageAllocationUnits . "." . $self->{swap_memory_id}})
        - ($physicalUsed * $physicalUnits);
    my $total_size = ($result->{$oid_hrStorageSize . "." . $self->{swap_memory_id}} * $result->{$oid_hrStorageAllocationUnits . "." . $self->{swap_memory_id}})
        - ($physicalSize * $physicalUnits);

    my $prct_used = $swap_used * 100 / $total_size;
    my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    my ($swap_used_value, $swap_used_unit) = $self->{perfdata}->change_bytes(value => $swap_used);
    my ($swap_free_value, $swap_free_unit) = $self->{perfdata}->change_bytes(value => $total_size - $swap_used);
    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_size);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Swap Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                                            $total_value . " " . $total_unit,
                                            $swap_used_value . " " . $swap_used_unit, $prct_used,
                                            $swap_free_value . " " . $swap_free_unit, 100 - $prct_used));

    $self->{output}->perfdata_add(label => "used", unit => 'B',
                                  nlabel => 'swap.usage.bytes',
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

Check Windows swap memory.

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=item B<--real-swap>

Use this option to remove physical memory from Windows SNMP swap values.
Using that option can give wrong values (incoherent or negative).

=back

=cut
