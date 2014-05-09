###############################################################################
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
# permission to link this program with independent modules to produce an timeelapsedutable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting timeelapsedutable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Author : Simon BOMM <sbomm@merethis.com>
#
# Based on De Bodt Lieven plugin
####################################################################################

package apps::apache::serverstatus::mode::requests;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::httplib;
use centreon::plugins::statefile;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
            {
            "hostname:s"        => { name => 'hostname' },
            "port:s"            => { name => 'port', },
            "proto:s"           => { name => 'proto', default => "http" },
            "urlpath:s"         => { name => 'url_path', default => "/server-status/?auto" },
            "credentials"       => { name => 'credentials' },
            "username:s"        => { name => 'username' },
            "password:s"        => { name => 'password' },
            "proxyurl:s"        => { name => 'proxyurl' },
            "warning:s"         => { name => 'warning' },
            "critical:s"        => { name => 'critical' },
            "warning-bytes:s"   => { name => 'warning_bytes' },
            "critical-bytes:s"  => { name => 'critical_bytes' },
            "warning-access:s"  => { name => 'warning_access' },
            "critical-access:s" => { name => 'critical_access' },
            "timeout:s"         => { name => 'timeout', default => '3' },
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
    if (($self->{perfdata}->threshold_validate(label => 'warning-bytes', value => $self->{option_results}->{warning_bytes})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-bytes threshold '" . $self->{option_results}->{warning_bytes} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-bytes', value => $self->{option_results}->{critical_bytes})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-bytes threshold '" . $self->{option_results}->{critical_bytes} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-access', value => $self->{option_results}->{warning_access})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-access threshold '" . $self->{option_results}->{warning_access} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-access', value => $self->{option_results}->{critical_access})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-access threshold '" . $self->{option_results}->{critical_access} . "'.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the hostname option");
        $self->{output}->option_exit();
    }
    if ((defined($self->{option_results}->{credentials})) && (!defined($self->{option_results}->{username}) || !defined($self->{option_results}->{password}))) {
        $self->{output}->add_option_msg(short_msg => "You need to set --username= and --password= options when --credentials is used");
        $self->{output}->option_exit();
    }
    
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;

    my $webcontent = centreon::plugins::httplib::connect($self);
    my ($rPerSec, $bPerReq, $total_access, $total_bytes, $avg_bPerSec);

    $total_access = $1 if ($webcontent =~ /^Total Accesses:\s+([^\s]+)/mi);
    $total_bytes = $1 * 1024 if ($webcontent =~ /^Total kBytes:\s+([^\s]+)/mi);
    
    $rPerSec = $1 if ($webcontent =~ /^ReqPerSec:\s+([^\s]+)/mi);
    $bPerReq = $1 if ($webcontent =~ /^BytesPerReq:\s+([^\s]+)/mi);
    $avg_bPerSec = $1 if ($webcontent =~ /^BytesPerSec:\s+([^\s]+)/mi);
    
    if (!defined($bPerReq)) {
        $self->{output}->add_option_msg(short_msg => "Apache 'ExtendedStatus' option is off.");
        $self->{output}->option_exit();
    }
    $rPerSec = '0' . $rPerSec if ($rPerSec =~ /^\./);
    
    $self->{statefile_value}->read(statefile => 'apache_' . $self->{option_results}->{hostname}  . '_' . centreon::plugins::httplib::get_port($self) . '_' . $self->{mode});
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
    my $old_total_access = $self->{statefile_value}->get(name => 'total_access');
    my $old_total_bytes = $self->{statefile_value}->get(name => 'total_bytes');

    my $new_datas = {};
    $new_datas->{last_timestamp} = time();
    $new_datas->{total_bytes} = $total_bytes;
    $new_datas->{total_access} = $total_access;
    
    $self->{statefile_value}->write(data => $new_datas); 
    if (!defined($old_timestamp) || !defined($old_total_access)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{output}->display();
        $self->{output}->exit();
    }
    $old_total_access = 0 if ($old_total_access > $new_datas->{total_access}); 
    $old_total_bytes = 0 if ($old_total_bytes > $new_datas->{total_bytes});
    my $delta_time = $new_datas->{last_timestamp} - $old_timestamp;
    $delta_time = 1 if ($delta_time == 0); # One seconds ;)
    
    my $bPerSec = ($new_datas->{total_bytes} - $old_total_bytes) / $delta_time;
    my $aPerSec = ($new_datas->{total_access} - $old_total_access) / $delta_time;
    
    my $exit1 = $self->{perfdata}->threshold_check(value => $rPerSec, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $bPerSec, threshold => [ { label => 'critical-bytes', 'exit_litteral' => 'critical' }, { label => 'warning-bytes', exit_litteral => 'warning' } ]);
    my $exit3 = $self->{perfdata}->threshold_check(value => $aPerSec, threshold => [ { label => 'critical-access', 'exit_litteral' => 'critical' }, { label => 'warning-access', exit_litteral => 'warning' } ]);
    
    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2, $exit3 ]);
    
    my ($bPerSec_value, $bPerSec_unit) = $self->{perfdata}->change_bytes(value => $bPerSec);
    my ($bPerReq_value, $bPerReq_unit) = $self->{perfdata}->change_bytes(value => $bPerReq);
    
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("BytesPerSec: %s AccessPerSec: %.2f RequestPerSec: %.2f BytesPerRequest: %s ", 
                                                     $bPerSec_value . ' ' . $bPerSec_unit,
                                                     $aPerSec,
                                                     $rPerSec,
                                                     $bPerReq_value . ' ' . $bPerReq_unit
                                                     ));
    $self->{output}->perfdata_add(label => "avg_RequestPerSec",
                                  value => sprintf("%.2f", $rPerSec),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0
                                  );
    $self->{output}->perfdata_add(label => "bytesPerSec", unit => 'B',
                                  value => sprintf("%.2f", $bPerSec),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-bytes'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-bytes'),
                                  min => 0);
    $self->{output}->perfdata_add(label => "avg_bytesPerRequest", unit => 'B',
                                  value => $bPerReq,
                                  min => 0
                                  );
    $self->{output}->perfdata_add(label => "avg_bytesPerSec", unit => 'B',
                                  value => $avg_bPerSec,
                                  min => 0
                                  );
    $self->{output}->perfdata_add(label => "accessPerSec",
                                  value => sprintf("%.2f", $aPerSec),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-access'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-access'),
                                  min => 0);

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check Apache WebServer Request statistics

=over 8

=item B<--hostname>

IP Addr/FQDN of the webserver host

=item B<--port>

Port used by Apache

=item B<--proxyurl>

Proxy URL if any

=item B<--proto>

Specify https if needed

=item B<--urlpath>

Set path to get server-status page in auto mode (Default: '/server-status/?auto')

=item B<--credentials>

Specify this option if you access server-status page over basic authentification

=item B<--username>

Specify username for basic authentification (Mandatory if --credentials is specidied)

=item B<--password>

Specify password for basic authentification (Mandatory if --credentials is specidied)

=item B<--timeout>

Threshold for HTTP timeout

=item B<--warning>

Warning Threshold for Request per seconds

=item B<--critical>

Critical Threshold for Request per seconds

=item B<--warning-bytes>

Warning Threshold for Bytes per seconds

=item B<--critical-bytes>

Critical Threshold for Bytes per seconds

=item B<--warning-access>

Warning Threshold for Access per seconds

=item B<--critical-access>

Critical Threshold for Access per seconds

=back

=cut
