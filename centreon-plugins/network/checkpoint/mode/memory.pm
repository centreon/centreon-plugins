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

package network::checkpoint::mode::memory;

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
                                  "warning:s"   => { name => 'warning', },
                                  "critical:s"  => { name => 'critical', },
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
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_memTotalReal64 = '.1.3.6.1.4.1.2620.1.6.7.4.3.0';
    my $oid_memActiveReal64 = '.1.3.6.1.4.1.2620.1.6.7.4.4.0';

    my $result = $self->{snmp}->get_leef(oids => [$oid_memTotalReal64, $oid_memActiveReal64], nothing_quit => 1);
    my ($memActiveReal64_value, $memActiveReal64_unit) = $self->{perfdata}->change_bytes(value => $result->{$oid_memActiveReal64});

    my $memPrctUsage = $result->{$oid_memActiveReal64} / $result->{$oid_memTotalReal64} * 100;

    my $exit = $self->{perfdata}->threshold_check(value => $memPrctUsage, 
                                                  threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Memory Usage: %.2f %s used (%.2f%%)", $memActiveReal64_value, $memActiveReal64_unit, $memPrctUsage));
    $self->{output}->perfdata_add(label => "used", unit => 'B',
                                  value => $result->{$oid_memActiveReal64},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $result->{$oid_memTotalReal64}, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $result->{$oid_memTotalReal64}, cast_int => 1),
                                  min => 0, max => $result->{$oid_memTotalReal64}
                                 );
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check firewall real memory usage (chkpnt.mib).

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
    
