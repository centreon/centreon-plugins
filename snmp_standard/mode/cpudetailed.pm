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

package snmp_standard::mode::cpudetailed;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;

my $oids = {
    '.1.3.6.1.4.1.2021.11.50' => { counter => 'user', output => 'User %.2f %%' }, # ssCpuRawUser
    '.1.3.6.1.4.1.2021.11.51' => { counter => 'nice', output => 'Nice %.2f %%' }, # ssCpuRawNice
    '.1.3.6.1.4.1.2021.11.52' => { counter => 'system', output => 'System %.2f %%' }, # ssCpuRawSystem
    '.1.3.6.1.4.1.2021.11.53' => { counter => 'idle', output => 'Idle %.2f %%' }, # ssCpuRawIdle
    '.1.3.6.1.4.1.2021.11.54' => { counter => 'wait', output => 'Wait %.2f %%' }, # ssCpuRawWait
    '.1.3.6.1.4.1.2021.11.55' => { counter => 'kernel', output => 'Kernel %.2f %%' }, # ssCpuRawKernel
    '.1.3.6.1.4.1.2021.11.56' => { counter => 'interrupt', output => 'Interrupt %.2f %%' }, # ssCpuRawInterrupt
    '.1.3.6.1.4.1.2021.11.61' => { counter => 'softirq', output => 'Soft Irq %.2f %%' }, # ssCpuRawSoftIRQ
    '.1.3.6.1.4.1.2021.11.64' => { counter => 'steal', output => 'Steal %.2f %%' }, # ssCpuRawSteal
    '.1.3.6.1.4.1.2021.11.65' => { counter => 'guest', output => 'Guest %.2f %%' }, # ssCpuRawGuest
    '.1.3.6.1.4.1.2021.11.66' => { counter => 'guestnice', output => 'Guest Nice %.2f %%' }, # ssCpuRawGuestNice
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                });
    foreach (keys %{$oids}) {
        $options{options}->add_options(arguments => {
                                                    'warning-' . $oids->{$_}->{counter} . ':s'    => { name => 'warning_' . $oids->{$_}->{counter} },
                                                    'critical-' . $oids->{$_}->{counter} . ':s'    => { name => 'critical_' . $oids->{$_}->{counter} },
                                                    });
    }
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    foreach (keys %{$oids}) {
        if (($self->{perfdata}->threshold_validate(label => 'warning-' . $oids->{$_}->{counter}, value => $self->{option_results}->{'warning_' . $oids->{$_}->{counter}})) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong warning-" . $oids->{$_}->{counter} . " threshold '" . $self->{option_results}->{'warning_' . $oids->{$_}->{counter}} . "'.");
            $self->{output}->option_exit();
        }
        if (($self->{perfdata}->threshold_validate(label => 'critical-' . $oids->{$_}->{counter}, value => $self->{option_results}->{'critical_' . $oids->{$_}->{counter}})) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong critical-" . $oids->{$_}->{counter} . " threshold '" . $self->{option_results}->{'critical_' . $oids->{$_}->{counter}} . "'.");
            $self->{output}->option_exit();
        }
    }
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();
    
    my $result = $self->{snmp}->get_table(oid => '.1.3.6.1.4.1.2021.11',
                                          start => '.1.3.6.1.4.1.2021.11.50',
                                          nothing_quit => 1);
    
    # construct values
    my $info_indexes = {};
    my $new_datas = {};
    my $old_datas = {};
    $new_datas->{last_timestamp} = time();
    $self->{statefile_value}->read(statefile => "snmpstandard_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    
    foreach my $oid (keys %{$result}) {
        $oid =~ /(.*)\.(\d+)$/;
        my ($oid_base, $index) = ($1, $2);
        # If not, we skip oid
        next if (!defined($oids->{$oid_base}));
        
        $new_datas->{$oids->{$oid_base}->{counter} . '_' . $index} = $result->{$oid};
        $old_datas->{$oids->{$oid_base}->{counter} . '_' . $index} = $self->{statefile_value}->get(name => $oids->{$oid_base}->{counter} . '_' . $index);
        $info_indexes->{$index} = { total => 0, old_total => 0, buffer_creation => 0 } if (!defined($info_indexes->{$index}));
        if (!defined($old_datas->{$oids->{$oid_base}->{counter} . '_' . $index})) {
            $info_indexes->{$index}->{buffer_creation} = 1;
            next;
        }
        if ($new_datas->{$oids->{$oid_base}->{counter} . '_' . $index} < $old_datas->{$oids->{$oid_base}->{counter} . '_' . $index}) {
            $info_indexes->{$index}->{buffer_creation} = 1;
            next;
        }
        $info_indexes->{$index}->{total} += $new_datas->{$oids->{$oid_base}->{counter} . '_' . $index};
        $info_indexes->{$index}->{old_total} += $old_datas->{$oids->{$oid_base}->{counter} . '_' . $index};
    }
    $self->{statefile_value}->write(data => $new_datas);
    
    my $multiple = 0;
    if (scalar(keys %$info_indexes) > 1) {
        $multiple = 1;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                   short_msg => "All CPU usage are ok.");
    }
    
    # Manage output
    foreach my $index (keys %$info_indexes) {
        if ($info_indexes->{$index}->{buffer_creation} == 1) {
            if ($multiple == 0) {
                $self->{output}->output_add(severity => 'OK',
                                            short_msg => "Buffer creation...");
            } else {
                $self->{output}->output_add(long_msg => "CPU '$index': Buffer creation...");
            }
            next;
        }
        if ($info_indexes->{$index}->{total} - $info_indexes->{$index}->{old_total} == 0) {
            if ($multiple == 0) {
                $self->{output}->output_add(severity => 'OK',
                                            short_msg => "Counter not moved. Have to wait.");
            } else {
                $self->{output}->output_add(long_msg => "CPU '$index': Counter not moved. Have to wait.");
            }
            next;
        }
        
        my @exits = ();
        foreach my $oid (keys %{$result}) {
            $oid =~ /(.*)\.(\d+)$/;
            my ($oid_base, $index2) = ($1, $2);
            # If not, we skip oid
            next if ($index2 != $index || !defined($oids->{$oid_base}));
            my $value = (($new_datas->{$oids->{$oid_base}->{counter} . '_' . $index} - $old_datas->{$oids->{$oid_base}->{counter} . '_' . $index}) * 100) / ($info_indexes->{$index}->{total} - $info_indexes->{$index}->{old_total});
            push @exits, $self->{perfdata}->threshold_check(value => $value, threshold => [ { label => 'critical-' . $oids->{$oid_base}->{counter}, 'exit_litteral' => 'critical' }, { label => 'warning-' . $oids->{$oid_base}->{counter}, 'exit_litteral' => 'warning' }]);
        }

        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        my $str_output = "CPU Usage: ";
        $str_output = "CPU '$index' Usage: " if ($multiple == 1);
        my $str_append = '';
        foreach my $oid (keys %{$result}) {
            $oid =~ /(.*)\.(\d+)$/;
            my ($oid_base, $index2) = ($1, $2);
            # If not, we skip oid
            next if ($index2 != $index || !defined($oids->{$oid_base}));
            
            my $value = (($new_datas->{$oids->{$oid_base}->{counter} . '_' . $index} - $old_datas->{$oids->{$oid_base}->{counter} . '_' . $index}) * 100) / ($info_indexes->{$index}->{total} - $info_indexes->{$index}->{old_total});
            $str_output .= $str_append . sprintf($oids->{$oid_base}->{output}, $value);
            $str_append = ', ';
            my $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $oids->{$oid_base}->{counter});
            my $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $oids->{$oid_base}->{counter});

            my $extra_perf_label = '';
            $extra_perf_label = $index if ($multiple == 1);
            $self->{output}->perfdata_add(label => $oids->{$oid_base}->{counter} . $extra_perf_label, unit => '%',
                                          value => sprintf("%.2f", $value),
                                          warning => $warning,
                                          critical => $critical,
                                          min => 0, max => 100);
        }
        if ($multiple == 0) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => $str_output);
        }
        $self->{output}->output_add(long_msg => $str_output);
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check system CPUs (UCD-SNMP-MIB) (User, Nice, System, Idle, Wait, Kernel, Interrupt, SoftIRQ, Steal, Guest, GuestNice)
An average of all CPUs.

=over 8

=item B<--warning-*>

Threshold warning in percent.
Can be: 'user', 'nice', 'system', 'idle', 'wait', 'kernel', 'interrupt', 'softirq', 'steal', 'guest', 'guestnice'.

=item B<--critical-*>

Threshold critical in percent.
Can be: 'user', 'nice', 'system', 'idle', 'wait', 'kernel', 'interrupt', 'softirq', 'steal', 'guest', 'guestnice'.

=back

=cut
