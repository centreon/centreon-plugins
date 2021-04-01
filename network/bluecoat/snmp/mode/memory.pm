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

package network::bluecoat::snmp::mode::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"      => { name => 'warning' },
                                  "critical:s"     => { name => 'critical' },
                                  "nocache"        => { name => 'nocache' },
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
    
    if ($self->{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $result = $self->{snmp}->get_table(oid => '.1.3.6.1.4.1.3417.2.11.2.3', nothing_quit => 1);

    my $mem_total = $result->{'.1.3.6.1.4.1.3417.2.11.2.3.1.0'};
    my $mem_cache = $result->{'.1.3.6.1.4.1.3417.2.11.2.3.2.0'};
    my $mem_sys = $result->{'.1.3.6.1.4.1.3417.2.11.2.3.3.0'};
    my $mem_used;
    
    if (defined($self->{option_results}->{nocache})) {
        $mem_used = $mem_sys;
    } else {
        $mem_used = $mem_sys + $mem_cache;
    }
    
    my $prct_used = sprintf("%.2f", $mem_used * 100 / $mem_total);
    my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $mem_used);
    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $mem_total);
    
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Memory used : %s - size : %s - percent : %.2f %%",
                                                     $used_value . ' ' . $used_unit, $total_value . ' ' . $total_unit, 
                                                     $prct_used));
    
    $self->{output}->perfdata_add(label => 'used', unit => 'B',
                                  value => $mem_used,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $mem_total, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $mem_total, cast_int => 1),
                                  min => 0, max => $mem_total);
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check bluecoat memory.

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=item B<--nocache>

Skip cache value.

=back

=cut
