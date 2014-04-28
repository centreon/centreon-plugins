################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package snmp_standard::mode::cpudetailed;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;

my $oids = {
    '.1.3.6.1.4.1.2021.11.50.0' => { counter => 'user', output => 'User %.2f %%' }, # ssCpuRawUser
    '.1.3.6.1.4.1.2021.11.51.0' => { counter => 'nice', output => 'Nice %.2f %%' }, # ssCpuRawNice
    '.1.3.6.1.4.1.2021.11.52.0' => { counter => 'system', output => 'System %.2f %%' }, # ssCpuRawSystem
    '.1.3.6.1.4.1.2021.11.53.0' => { counter => 'idle', output => 'Idle %.2f %%' }, # ssCpuRawIdle
    '.1.3.6.1.4.1.2021.11.54.0' => { counter => 'wait', output => 'Wait %.2f %%' }, # ssCpuRawWait
    '.1.3.6.1.4.1.2021.11.55.0' => { counter => 'kernel', output => 'Kernel %.2f %%' }, # ssCpuRawKernel
    '.1.3.6.1.4.1.2021.11.56.0' => { counter => 'interrupt', output => 'Interrupt %.2f %%' }, # ssCpuRawInterrupt
    '.1.3.6.1.4.1.2021.11.61.0' => { counter => 'softirq', output => 'Soft Irq %.2f %%' }, # ssCpuRawSoftIRQ
    '.1.3.6.1.4.1.2021.11.64.0' => { counter => 'steal', output => 'Steal %.2f %%' }, # ssCpuRawSteal
    '.1.3.6.1.4.1.2021.11.65.0' => { counter => 'guest', output => 'Guest %.2f %%' }, # ssCpuRawGuest
    '.1.3.6.1.4.1.2021.11.66.0' => { counter => 'guestnice', output => 'Guest Nice %.2f %%' }, # ssCpuRawGuestNice
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
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();
    
    my $result = $self->{snmp}->get_leef(oids => [keys %$oids], nothing_quit => 1);
    
    # Manage values
    my ($total, $old_total, $buffer_creation) = (0, 0, 0);
    my $new_datas = {};
    my $old_datas = {};
    $new_datas->{last_timestamp} = time();
    $self->{statefile_value}->read(statefile => "snmpstandard_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    foreach (keys %{$oids}) {
        next if (!defined($result->{$_}));
        $new_datas->{$oids->{$_}->{counter}} = $result->{$_};
        $old_datas->{$oids->{$_}->{counter}} = $self->{statefile_value}->get(name => $oids->{$_}->{counter});
        if (!defined($old_datas->{$oids->{$_}->{counter}})) {
            $buffer_creation = 1;
            next;
        }
        if ($new_datas->{$oids->{$_}->{counter}} < $old_datas->{$oids->{$_}->{counter}}) {
            $buffer_creation = 1;
            next;
        }
        $total += $new_datas->{$oids->{$_}->{counter}};
        $old_total += $old_datas->{$oids->{$_}->{counter}};
    }

    $self->{statefile_value}->write(data => $new_datas);
    if ($buffer_creation == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{output}->display();
        $self->{output}->exit();
    }
    if ($total - $old_total == 0) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Counter not moved. Have to wait.");
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    my @exits;
    foreach (keys %{$oids}) {
        next if (!defined($result->{$_}));
        my $value = (($new_datas->{$oids->{$_}->{counter}} - $old_datas->{$oids->{$_}->{counter}}) * 100) / ($total - $old_total);
        push @exits, $self->{perfdata}->threshold_check(value => $value, threshold => [ { label => 'critical-' . $oids->{$_}->{counter}, 'exit_litteral' => 'critical' }, { label => 'warning-' . $oids->{$_}->{counter}, 'exit_litteral' => 'warning' }]);
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    my $str_output = "CPU Usage: ";
    my $str_append = '';
    foreach (keys %{$oids}) {
        next if (!defined($result->{$_}));
        
        my $value = (($new_datas->{$oids->{$_}->{counter}} - $old_datas->{$oids->{$_}->{counter}}) * 100) / ($total - $old_total);
        $str_output .= $str_append . sprintf($oids->{$_}->{output}, $value);
        $str_append = ', ';
        my $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $oids->{$_}->{counter});
        my $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $oids->{$_}->{counter});

        $self->{output}->perfdata_add(label => $oids->{$_}->{counter}, unit => '%',
                                      value => sprintf("%.2f", $value),
                                      warning => $warning,
                                      critical => $critical,
                                      min => 0, max => 100);
    }
    $self->{output}->output_add(severity => $exit,
                                short_msg => $str_output);
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
