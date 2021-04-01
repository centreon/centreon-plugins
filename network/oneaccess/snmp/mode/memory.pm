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

package network::oneaccess::snmp::mode::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
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
    $self->{snmp} = $options{snmp};

    my $oid_oacSysMemoryTotal = '.1.3.6.1.4.1.13191.10.3.3.1.1.3.0';
    my $oid_oacSysMemoryUsed = '.1.3.6.1.4.1.13191.10.3.3.1.1.4.0';

    my $result = $self->{snmp}->get_leef(oids => [$oid_oacSysMemoryTotal, $oid_oacSysMemoryUsed], nothing_quit => 1);
    my $total = $result->{$oid_oacSysMemoryTotal};
    my $used = $result->{$oid_oacSysMemoryUsed} * $total / 100;
    my $free = $total - $used; 
    my $prct_used = $result->{$oid_oacSysMemoryUsed};
    my $prct_free = 100 - $prct_used;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $total);
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $used);
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $free);

    my $exit = $self->{perfdata}->threshold_check(value => $prct_used, 
                                                  threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                                    $total_size_value . " " . $total_size_unit,
                                    $total_used_value . " " . $total_used_unit, $prct_used,
                                    $total_free_value . " " . $total_free_unit, $prct_free));
       
    $self->{output}->perfdata_add(label => "used", unit => 'B',
                                  value => sprintf("%d", $used),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $total, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $total, cast_int => 1),
                                  min => 0, max => $total
                                 );
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check memory usage (oneaccess-sys-mib).

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
    
