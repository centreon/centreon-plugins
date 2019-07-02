#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package network::hirschmann::standard::snmp::mode::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
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

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_hmMemoryFree = '.1.3.6.1.4.1.248.14.2.15.3.2.0'; # in KBytes
    my $oid_hmMemoryAllocated = '.1.3.6.1.4.1.248.14.2.15.3.1.0'; # in KBytes

    my $result = $self->{snmp}->get_leef(oids => [$oid_hmMemoryFree, $oid_hmMemoryAllocated],
                                         nothing_quit => 1);
    my $mem_free = $result->{$oid_hmMemoryFree} * 1024;
    my $mem_allocated = $result->{$oid_hmMemoryAllocated} * 1024;

    my $mem_total = $mem_allocated + $mem_free;

    my $mem_percent_used = ($mem_total != 0) ? $mem_allocated / $mem_total * 100 : '0';

    my $exit = $self->{perfdata}->threshold_check(value => $mem_percent_used, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    my ($mem_allocated_value, $mem_allocated_unit) = $self->{perfdata}->change_bytes(value => $mem_allocated);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Memory used %s (%.2f%%)", 
                                    $mem_allocated_value . " " . $mem_allocated_unit, $mem_percent_used));

    $self->{output}->perfdata_add(label => "used", unit => 'B',
                                  value => $mem_allocated,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $mem_total, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $mem_total, cast_int => 1),
                                  min => 0, max => $mem_total,
                                  );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Memory usage.
hmEnableMeasurement must be activated (value = 1).

=over 8

=item B<--warning>

Threshold warning in %.

=item B<--critical>

Threshold critical in %.

=back

=cut
