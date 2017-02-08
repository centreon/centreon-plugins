#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package network::riverbed::steelhead::snmp::mode::bwpassthrough;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use POSIX;
use centreon::plugins::statefile;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';

    $options{options}->add_options(arguments =>
                              {
                                "warning-in:s"          => { name => 'warning_in', },
                                "critical-in:s"         => { name => 'critical_in', },
                                "warning-out:s"          => { name => 'warning_out', },
                                "critical-out:s"         => { name => 'critical_out', },
                              });

    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning_in', value => $self->{option_results}->{warning_in})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold for Wan2Lan'" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical_in', value => $self->{option_results}->{critical_in})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold for Wan2Lan'" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning_out', value => $self->{option_results}->{warning_in})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold for Wan2Lan'" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical_in', value => $self->{option_results}->{critical_in})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold for Wan2Lan'" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();

    my $oid_bwPassThroughIn = '.1.3.6.1.4.1.17163.1.1.5.3.3.1.0';
    my $oid_bwPassThroughOut = '.1.3.6.1.4.1.17163.1.1.5.3.3.2.0';
    my ($result, $bw_inn, $bw_out);

    $result = $self->{snmp}->get_leef(oids => [ $oid_bwPassThroughIn, $oid_bwPassThroughOut ], nothing_quit => 1);
    $bw_inn = $result->{$oid_bwPassThroughIn};
    $bw_out = $result->{$oid_bwPassThroughOut};

    $self->{statefile_value}->read(statefile => 'steelhead_' . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
    my $old_bwPassThroughIn = $self->{statefile_value}->get(name => 'bwPassThroughIn');
    my $old_bwPassThroughOut = $self->{statefile_value}->get(name => 'bwPassThroughOut');

    my $new_datas = {};
    $new_datas->{last_timestamp} = time();
    $new_datas->{bwPassThroughIn} = $bw_inn;
    $new_datas->{bwPassThroughOut} = $bw_out;

    $self->{statefile_value}->write(data => $new_datas);

    if (!defined($old_timestamp) || !defined($old_bwPassThroughIn) || !defined($old_bwPassThroughOut)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{output}->display();
        $self->{output}->exit();
    }

    $old_bwPassThroughIn = 0 if ($old_bwPassThroughIn > $new_datas->{bwPassThroughIn});
    $old_bwPassThroughOut = 0 if ($old_bwPassThroughOut > $new_datas->{bwPassThroughOut});

    my $delta_time = $new_datas->{last_timestamp} - $old_timestamp;
    $delta_time = 1 if ($delta_time == 0);

    my $bwPassThroughInPerSec = int(($new_datas->{bwPassThroughIn} - $old_bwPassThroughIn) / $delta_time);
    my $bwPassThroughOutPerSec = int(($new_datas->{bwPassThroughOut} - $old_bwPassThroughOut) / $delta_time);

    my $exit1 = $self->{perfdata}->threshold_check(value => $bwPassThroughInPerSec,
                                                     threshold => [ { label => 'critical_in', exit_litteral => 'critical' }, { label => 'warning_in', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $bwPassThroughOutPerSec,
                                                   threshold => [ { label => 'critical_out', exit_litteral => 'critical' }, { label => 'warning_out', exit_litteral => 'warning' } ]);
    my $exit_code = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);

    $self->{output}->perfdata_add(label => 'Traffic_In', unit => 'B/s',
                                  value => $bwPassThroughInPerSec,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_in'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_in'),
                                  min => 0);
    $self->{output}->perfdata_add(label => 'Traffic_Out', unit => 'B/s',
                                  value => $bwPassThroughOutPerSec,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_out'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_out'),
                                  min => 0);

    my ($bwPassThroughInPerSec_value, $bwPassThroughInPerSec_unit) = $self->{perfdata}->change_bytes(value => $bwPassThroughInPerSec);
    my ($bwPassThroughOutPerSec_value, $bwPassThroughOutPerSec_unit) = $self->{perfdata}->change_bytes(value => $bwPassThroughOutPerSec);
    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("Passthrough: Wan2Lan %s/s, Lan2Wan %s/s",
                                  $bwPassThroughInPerSec_value . " " . $bwPassThroughInPerSec_unit, 
                                  $bwPassThroughOutPerSec_value . " " . $bwPassThroughOutPerSec_unit));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check passthrough bandwidth in both directions (STEELHEAD-MIB).

=over 8

=item B<--warning-in>

Threshold warning for Wan2Lan passthrough in bytes per second.

=item B<--critical-in>

Threshold critical for Wan2Lan passthrough in bytes per second.

=item B<--warning-out>

Threshold warning for Lan2Wan passthrough in bytes per second.

=item B<--critical-out>

Threshold critical for Lan2Wan passthrough in bytes per second.

=back

=cut
