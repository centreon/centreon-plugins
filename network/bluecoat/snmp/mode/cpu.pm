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

package network::bluecoat::snmp::mode::cpu;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"      => { name => 'warning' },
                                  "critical:s"     => { name => 'critical' },
                                });
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
                                
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
    
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();
    
    if ($self->{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $new_datas = {};
    my $old_timestamp = undef;
    
    $self->{statefile_value}->read(statefile => 'bluecoat_' . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    
    my $result = $self->{snmp}->get_table(oid => '.1.3.6.1.4.1.3417.2.11.2.4.1', nothing_quit => 1);
    $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
    $new_datas->{last_timestamp} = time();
    
    my $oid_sgProxyCpuCoreBusyTime = '.1.3.6.1.4.1.3417.2.11.2.4.1.3';
    my $oid_sgProxyCpuCoreIdleTime = '.1.3.6.1.4.1.3417.2.11.2.4.1.4';
    my $i = 0;
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$result})) {
        next if ($oid !~ /^$oid_sgProxyCpuCoreBusyTime\.(\d+)/);
        my $instance = $1;
        
        $i++;
        $new_datas->{'cpu_' . $i . '_busy'} = $result->{$oid};
        $new_datas->{'cpu_' . $i . '_idle'} = $result->{$oid_sgProxyCpuCoreIdleTime . '.' . $instance};
        
        next if (!defined($old_timestamp));
        
        my $old_cpu_busy = $self->{statefile_value}->get(name => 'cpu_' . $i . '_busy');
        my $old_cpu_idle = $self->{statefile_value}->get(name => 'cpu_' . $i . '_idle');
        if (!defined($old_cpu_busy) || !defined($old_cpu_idle)) {
            next;
        }
        
        if ($new_datas->{'cpu_' . $i . '_busy'} < $old_cpu_busy) {
            # We set 0. Has reboot.
            $old_cpu_busy = 0;
            $old_cpu_idle = 0;
        }
        
        my $total_elapsed = (($new_datas->{'cpu_' . $i . '_busy'} - $old_cpu_busy) + ($new_datas->{'cpu_' . $i . '_idle'} - $old_cpu_idle));
        my $prct_usage =  (($new_datas->{'cpu_' . $i . '_busy'} - $old_cpu_busy) * 100 / ($total_elapsed));
        my $exit = $self->{perfdata}->threshold_check(value => $prct_usage, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("CPU $i Usage is %.2f%%", $prct_usage));
        $self->{output}->perfdata_add(label => 'cpu_' . $i, unit => '%',
                                      value => sprintf("%.2f", $prct_usage),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0, max => 100);
    }
    
    $self->{statefile_value}->write(data => $new_datas);
    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check CPU Usage

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
