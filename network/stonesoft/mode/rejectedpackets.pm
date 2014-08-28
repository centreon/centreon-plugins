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

package network::stonesoft::mode::rejectedpackets;

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
                                 "warning:s"               => { name => 'warning' },
                                 "critical:s"              => { name => 'critical' },
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
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();

    if ($self->{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Can't check SNMP 64 bits counters with SNMPv1.");
        $self->{output}->option_exit();
    }

    my $new_datas = {};
    $self->{statefile_value}->read(statefile => "stonesoft_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});

    my $oid_fwRejected = '.1.3.6.1.4.1.1369.5.2.1.9.0';
    my $result = $self->{snmp}->get_leef(oids => [$oid_fwRejected], nothing_quit => 1);

    my $rejected_packets = $result->{$oid_fwRejected};
    $new_datas->{rejected_packets} = $rejected_packets;
    $new_datas->{last_timestamp} = time();

    my $old_datas = {};
    $old_datas->{old_timestamp} = $self->{statefile_value}->get(name => 'last_timestamp');
    $old_datas->{old_rejected_packets} = $self->{statefile_value}->get(name => 'rejected_packets');
    if (!defined($old_datas->{old_rejected_packets}) || $new_datas->{rejected_packets} < $old_datas->{old_rejected_packets}) {
        # We set 0. Has reboot.
        $old_datas->{old_rejected_packets} = 0;
    }

    if (defined($old_datas->{old_timestamp})) {
        my $time_delta = $new_datas->{last_timestamp} - $old_datas->{old_timestamp};
        if ($time_delta <= 0) {
            $time_delta = 1;
        }

        my $rejected_absolute = $new_datas->{rejected_packets} - $old_datas->{old_rejected_packets};
        my $rejected_absolute_per_sec = $rejected_absolute / $time_delta;

        my $exit = $self->{perfdata}->threshold_check(value => $rejected_absolute_per_sec, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Packets Rejected : %.2f /s [%i packets]", 
                                                $rejected_absolute_per_sec, $rejected_absolute));

        $self->{output}->perfdata_add(label => 'rejected_packets_per_sec',
                                    value => sprintf("%.2f", $rejected_absolute_per_sec),
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                    min => 0);

    } else {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
    }

    $self->{statefile_value}->write(data => $new_datas);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check rejected packets per second by firewall.

=over 8

=item B<--warning>

Threshold warning for blocked packets per second.

=item B<--critical>

Threshold critical for blocked packets per second.

=back

=cut
    
