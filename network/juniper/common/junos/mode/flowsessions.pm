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

package network::juniper::common::junos::mode::flowsessions;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
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
    
    my $oid_jnxJsSPUMonitoringSPUIndex = '.1.3.6.1.4.1.2636.3.39.1.12.1.1.1.3';
    my $oid_jnxJsSPUMonitoringCurrentFlowSession = '.1.3.6.1.4.1.2636.3.39.1.12.1.1.1.6';
    my $oid_jnxJsSPUMonitoringMaxFlowSession = '.1.3.6.1.4.1.2636.3.39.1.12.1.1.1.7';
    
    my $result = $self->{snmp}->get_table(oid => $oid_jnxJsSPUMonitoringSPUIndex, nothing_quit => 1);
    $self->{snmp}->load(oids => [$oid_jnxJsSPUMonitoringCurrentFlowSession, $oid_jnxJsSPUMonitoringMaxFlowSession],
                        instances => [keys %$result],
                        instance_regexp => '\.(\d+)$');
    my $result2 = $self->{snmp}->get_leef(nothing_quit => 1);
    
    my $spu_done = 0;
    foreach my $oid (keys %$result) {        
        $oid =~ /\.(\d+)$/;
        my $instance = $1;
        my $flow_total = $result2->{$oid_jnxJsSPUMonitoringMaxFlowSession . '.' . $instance};
        my $flow_used = $result2->{$oid_jnxJsSPUMonitoringCurrentFlowSession . '.' . $instance};
        
        next if ($flow_total == 0);
        my $prct_used = $flow_used * 100 / $flow_total;
    
        $spu_done = 1;
        my $exit_code = $self->{perfdata}->threshold_check(value => $prct_used, 
                                threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        $self->{output}->output_add(severity => $exit_code,
                                    short_msg => sprintf("SPU '%d': %.2f%% of the flow sessions limit reached (%d of max. %d)", 
                                        $instance, $prct_used, $flow_used, $flow_total));
        $self->{output}->perfdata_add(label => 'sessions_' . $instance,
                                      value => $flow_used,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $flow_total),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $flow_total),
                                      min => 0, max => $flow_total);
    }

    if ($spu_done == 0) {
        $self->{output}->add_option_msg(short_msg => "Cannot check flow sessions usage (no total values).");
        $self->{output}->option_exit();
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Packet Forwarding Engine sessions usage.

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
