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

package network::stonesoft::snmp::mode::rejectedpackets;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
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

        my $rejected = $new_datas->{rejected_packets} - $old_datas->{old_rejected_packets};
        my $rejected_per_sec = $rejected / $time_delta;

        my $exit = $self->{perfdata}->threshold_check(value => $rejected_per_sec, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Packets Rejected : %.2f /s [%i packets]", 
                                                $rejected_per_sec, $rejected));

        $self->{output}->perfdata_add(label => 'rejected_packets_per_sec',
                                    value => sprintf("%.2f", $rejected_per_sec),
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
    
