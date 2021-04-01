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

package network::ruggedcom::mode::memory;

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

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_rcDeviceStsAvailableRam = '.1.3.6.1.4.1.15004.4.2.2.2.0'; # in bytes
    my $oid_rcDeviceInfoTotalRam = '.1.3.6.1.4.1.15004.4.2.3.5.0'; # in bytes

    my $result = $self->{snmp}->get_leef(oids => [$oid_rcDeviceStsAvailableRam, $oid_rcDeviceInfoTotalRam], 
                                         nothing_quit => 1);
    my $used = $result->{$oid_rcDeviceStsAvailableRam};
    my $total_size = $result->{$oid_rcDeviceInfoTotalRam};
    
    my $prct_used = $used * 100 / $total_size;
    my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_size);
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $used);
    
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Ram used %s (%.2f%%), Total: %s",
                                            $used_value . " " . $used_unit, $prct_used,
                                            $total_value . " " . $total_unit));

    $self->{output}->perfdata_add(label => "used", unit => 'B',
                                  value => $used,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $total_size, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $total_size, cast_int => 1),
                                  min => 0, max => $total_size);
                                  
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check memory usage (RUGGEDCOM-SYS-INFO).

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
