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

package apps::apache::serverstatus::mode::requests;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s'        => { name => 'hostname' },
        'port:s'            => { name => 'port', },
        'proto:s'           => { name => 'proto' },
        'urlpath:s'         => { name => 'url_path', default => "/server-status/?auto" },
        'credentials'       => { name => 'credentials' },
        'basic'             => { name => 'basic' },
        'username:s'        => { name => 'username' },
        'password:s'        => { name => 'password' },
        'header:s@'         => { name => 'header' },
        'warning:s'         => { name => 'warning' },
        'critical:s'        => { name => 'critical' },
        'warning-bytes:s'   => { name => 'warning_bytes' },
        'critical-bytes:s'  => { name => 'critical_bytes' },
        'warning-access:s'  => { name => 'warning_access' },
        'critical-access:s' => { name => 'critical_access' },
        'timeout:s'         => { name => 'timeout' },
    });
    $self->{http} = centreon::plugins::http->new(%options);
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

    $self->{http}->set_options(%{$self->{option_results}});
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;

    my $webcontent = $self->{http}->request();

    #Total accesses: 7323 - Total Traffic: 243.7 MB - Total Duration: 7175675
    #CPU Usage: u1489.98 s1118.39 cu0 cs0 - .568% CPU load
    #.0159 requests/sec - 555 B/second - 34.1 kB/request - 979.882 ms/request
    my ($rPerSec, $bPerReq, $total_access, $total_bytes, $avg_bPerSec);

    $total_access = $1 if ($webcontent =~ /^Total Accesses:\s+([^\s]+)/mi);

    $total_bytes = $1 * 1024 if ($webcontent =~ /^Total kBytes:\s+([^\s]+)/mi);
    if ($webcontent =~ /Total\s+Traffic:\s+(\S+)\s+(.|)B\s+/mi) {
        $total_bytes = centreon::plugins::misc::convert_bytes(value => $1, unit => $2 . 'B');
    }

    $rPerSec = $1 if ($webcontent =~ /^ReqPerSec:\s+([^\s]+)/mi);
    if ($webcontent =~ /^(\S+)\s+requests\/sec/mi) {
        $rPerSec = $1;
        $rPerSec = '0' . $rPerSec if ($rPerSec =~ /^\./);
    }

    # Need a little time to init
    $bPerReq = $1 if ($webcontent =~ /^BytesPerReq:\s+([^\s]+)/mi);
    if ($webcontent =~ /(\S+)\s+(.|)B\/request/mi) {
        $bPerReq = centreon::plugins::misc::convert_bytes(value => $1, unit => $2 . 'B');
    }

    $avg_bPerSec = $1 if ($webcontent =~ /^BytesPerSec:\s+([^\s]+)/mi);
    if ($webcontent =~ /(\S+)\s+(.|)B\/second/mi) {
        $avg_bPerSec = centreon::plugins::misc::convert_bytes(value => $1, unit => $2 . 'B');
    }

    if (!defined($avg_bPerSec)) {
        $self->{output}->add_option_msg(short_msg => "Apache 'ExtendedStatus' option is off.");
        $self->{output}->option_exit();
    }
    $rPerSec = '0' . $rPerSec if ($rPerSec =~ /^\./);
    $avg_bPerSec = '0' . $avg_bPerSec if ($avg_bPerSec =~ /^\./);
    $bPerReq = '0' . $bPerReq if ($bPerReq =~ /^\./);
    
    $self->{statefile_value}->read(statefile => 'apache_' . $self->{option_results}->{hostname}  . '_' . $self->{http}->get_port() . '_' . $self->{mode});
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

=item B<--proto>

Specify https if needed

=item B<--urlpath>

Set path to get server-status page in auto mode (Default: '/server-status/?auto')

=item B<--credentials>

Specify this option if you access server-status page with authentication

=item B<--username>

Specify username for authentication (Mandatory if --credentials is specified)

=item B<--password>

Specify password for authentication (Mandatory if --credentials is specified)

=item B<--basic>

Specify this option if you access server-status page over basic authentication and don't want a '401 UNAUTHORIZED' error to be logged on your webserver.

Specify this option if you access server-status page over hidden basic authentication or you'll get a '404 NOT FOUND' error.

(Use with --credentials)

=item B<--timeout>

Threshold for HTTP timeout

=item B<--header>

Set HTTP headers (Multiple option)

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
