################################################################################
# Copyright 2005-2015 MERETHIS
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
# Authors : Alexandre Friquet <centreon@infopiiaf.fr>
#
####################################################################################

package network::riverbed::steelhead::snmp::mode::bwoptimization;

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

    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
  my ($self, %options) = @_;
  $self->SUPER::init(%options);
  $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object

    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();

    my $oid_bwHCAggInLan = '.1.3.6.1.4.1.17163.1.1.5.6.1.1.0'; # in bytes, 64 bits
    my $oid_bwHCAggInWan = '.1.3.6.1.4.1.17163.1.1.5.6.1.2.0'; # in bytes, 64 bits
    my $oid_bwHCAggOutLan = '.1.3.6.1.4.1.17163.1.1.5.6.1.3.0'; # in bytes, 64 bits
    my $oid_bwHCAggOutWan = '.1.3.6.1.4.1.17163.1.1.5.6.1.4.0'; # in bytes, 64 bits
    my ($result, $bw_in_lan, $bw_out_lan, $bw_in_wan, $bw_out_wan);

    $result = $self->{snmp}->get_leef(oids => [ $oid_bwHCAggInLan, $oid_bwHCAggInWan, $oid_bwHCAggOutLan, $oid_bwHCAggOutWan ], nothing_quit => 1);
    $bw_in_lan = $result->{$oid_bwHCAggInLan};
    $bw_in_wan = $result->{$oid_bwHCAggInWan};
    $bw_out_lan = $result->{$oid_bwHCAggOutLan};
    $bw_out_wan = $result->{$oid_bwHCAggOutWan};

    $self->{statefile_value}->read(statefile => 'steelhead_' . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
    my $old_bwHCAggInLan = $self->{statefile_value}->get(name => 'bwHCAggInLan');
    my $old_bwHCAggInWan = $self->{statefile_value}->get(name => 'bwHCAggInWan');
    my $old_bwHCAggOutLan = $self->{statefile_value}->get(name => 'bwHCAggOutLan');
    my $old_bwHCAggOutWan = $self->{statefile_value}->get(name => 'bwHCAggOutWan');

    my $new_datas = {};
    $new_datas->{last_timestamp} = time();
    $new_datas->{bwHCAggInLan} = $bw_in_lan;
    $new_datas->{bwHCAggInWan} = $bw_in_wan;
    $new_datas->{bwHCAggOutLan} = $bw_out_lan;
    $new_datas->{bwHCAggOutWan} = $bw_out_wan;

    $self->{statefile_value}->write(data => $new_datas);

    if (!defined($old_timestamp) || !defined($old_bwHCAggInLan) || !defined($old_bwHCAggInWan) || !defined($old_bwHCAggOutLan) || !defined($old_bwHCAggOutWan)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{output}->display();
        $self->{output}->exit();
    }

    $old_bwHCAggInLan = 0 if ($old_bwHCAggInLan > $new_datas->{bwHCAggInLan});
    $old_bwHCAggInWan = 0 if ($old_bwHCAggInWan > $new_datas->{bwHCAggInWan});
    $old_bwHCAggOutLan = 0 if ($old_bwHCAggOutLan > $new_datas->{bwHCAggOutLan});
    $old_bwHCAggOutWan = 0 if ($old_bwHCAggOutWan > $new_datas->{bwHCAggOutWan});

    my $delta_time = $new_datas->{last_timestamp} - $old_timestamp;
    $delta_time = 1 if ($delta_time == 0);

    my $bwHCAggInLanPerSec = int(($new_datas->{bwHCAggInLan} - $old_bwHCAggInLan) / $delta_time);
    my $bwHCAggInWanPerSec = int(($new_datas->{bwHCAggInWan} - $old_bwHCAggInWan) / $delta_time);
    my $bwHCAggOutLanPerSec = int(($new_datas->{bwHCAggOutLan} - $old_bwHCAggOutLan) / $delta_time);
    my $bwHCAggOutWanPerSec = int(($new_datas->{bwHCAggOutWan} - $old_bwHCAggOutWan) / $delta_time);

    $self->{output}->perfdata_add(label => 'wan2lan_lan', unit => 'B/s',
                                  value => $bwHCAggInLanPerSec,
                                  min => 0);
    $self->{output}->perfdata_add(label => 'wan2lan_wan', unit => 'B/s',
                                  value => $bwHCAggInWanPerSec,
                                  min => 0);
    $self->{output}->perfdata_add(label => 'lan2wan_lan', unit => 'B/s',
                                  value => $bwHCAggOutLanPerSec,
                                  min => 0);
    $self->{output}->perfdata_add(label => 'lan2wan_wan', unit => 'B/s',
                                  value => $bwHCAggOutWanPerSec,
                                  min => 0);

    my ($bwHCAggInLanPerSec_value, $bwHCAggInLanPerSec_unit) = $self->{perfdata}->change_bytes(value => $bwHCAggInLanPerSec);
    my ($bwHCAggInWanPerSec_value, $bwHCAggInWanPerSec_unit) = $self->{perfdata}->change_bytes(value => $bwHCAggInWanPerSec);
    my ($bwHCAggOutLanPerSec_value, $bwHCAggOutLanPerSec_unit) = $self->{perfdata}->change_bytes(value => $bwHCAggOutLanPerSec);
    my ($bwHCAggOutWanPerSec_value, $bwHCAggOutWanPerSec_unit) = $self->{perfdata}->change_bytes(value => $bwHCAggOutWanPerSec);
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("Optimized: Wan2Lan on Lan %s/s, Wan2Lan on Wan %s/s, Lan2Wan on Lan %s/s, Lan2Wan on Wan %s/s",
                                  $bwHCAggInLanPerSec_value . " " . $bwHCAggInLanPerSec_unit,
                                  $bwHCAggInWanPerSec_value . " " . $bwHCAggInWanPerSec_unit,
                                  $bwHCAggOutLanPerSec_value . " " . $bwHCAggOutLanPerSec_unit,
                                  $bwHCAggOutWanPerSec_value . " " . $bwHCAggOutWanPerSec_unit
                                  ));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Total optimized bytes across all application ports in both directions and on both sides, in bytes per second (STEELHEAD-MIB).

=over 8

=back

=cut
