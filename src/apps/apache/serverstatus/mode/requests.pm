#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
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
        'warning:s'         => { name => 'warning', redirect => 'warning-apache-request-average-persecond' },
        'critical:s'        => { name => 'critical', redirect => 'critical-apache-request-average-persecond' },
        'warning-bytes:s'   => { name => 'warning_bytes', redirect => 'warning-apache-bytes-persecond' },
        'critical-bytes:s'  => { name => 'critical_bytes', redirect => 'critical-apache-bytes-persecond' },
        'warning-access:s'  => { name => 'warning_access', redirect => 'warning-apache-access-persecond' },
        'critical-access:s' => { name => 'critical_access', redirect => 'critical-apache-access-persecond' },
        'timeout:s'         => { name => 'timeout' },
    });
    $self->{http} = centreon::plugins::http->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

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
}

sub custom_bytes_persecond_calc {
    my ($self, %options) = @_;

    unless (defined $options{old_datas}->{global_total_bytes}) {
        $self->{error_msg} = "Buffer creation";
        return -1;
    }

    my $delta_time = $options{delta_time} || 1;

    my $old_total_bytes = $options{old_datas}->{global_total_bytes} || 0;
    $old_total_bytes = 0 if $old_total_bytes > $options{new_datas}->{global_total_bytes};

    $self->{result_values}->{bPerSec} = ($options{new_datas}->{global_total_bytes} - $old_total_bytes) / $delta_time;

    return 0;
}

sub custom_access_persecond_calc {
    my ($self, %options) = @_;

    unless (defined $options{old_datas}->{global_total_access}) {
        $self->{error_msg} = "Buffer creation";
        return -1;
    }
    my $delta_time = $options{delta_time} || 1;

    my $old_total_access = $options{old_datas}->{global_total_access} || 0;
    $old_total_access = 0 if $old_total_access > $options{new_datas}->{global_total_access};

    $self->{result_values}->{aPerSec} = ($options{new_datas}->{global_total_access} - $old_total_access) / $delta_time;

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', askipped_code => { -2 => 1 } }
    ];

    $self->{maps_counters}->{global} =  [
        {   label => 'bytesPerSec', nlabel => 'apache.bytes.persecond',
            set => {
                key_values => [ { name => 'bPerSec' }, { name => 'total_bytes' } ],
                output_template => 'BytesPerSec: %.2f %s',
                output_change_bytes => 1,
                closure_custom_calc => $self->can('custom_bytes_persecond_calc'),
                perfdatas => [ { template => '%.2f', min => 0, unit => 'B' } ]
           }
        },
        {   label => 'accessPerSec', nlabel => 'apache.access.persecond',
            set => {
                key_values => [ { name => 'aPerSec' }, { name => 'total_access' } ],
                closure_custom_calc => $self->can('custom_access_persecond_calc'),
                output_template => 'AccessPerSec: %.2f',
                perfdatas => [ { template => '%.2f', min => 0, } ]
            }
        },
        { label => 'avg_RequestPerSec', nlabel => 'apache.request.average.persecond',
            set => {
                key_values => [ { name => 'rPerSec' } ],
                output_template => 'RequestPerSec: %.2f',
                perfdatas => [ { template => '%.2f', min => 0, } ]
            }
        },
        { label => 'avg_bytesPerRequest', nlabel => 'apache.bytes.average.perrequest',
            set => {
                key_values => [ { name => 'bPerReq' } ],
                output_change_bytes => 1,
                output_template => 'BytesPerRequest: %.2f %s',
                perfdatas => [ { template => '%.2f', min => 0, unit => 'B', } ]
            }
        },
        { label => 'avg_bytesPerSec', nlabel => 'apache.bytes.average.persecond',
           display_ok => 0,
           set => {
               key_values => [ { name => 'avg_bPerSec' } ],
               perfdatas => [ { min => 0, unit => 'B' } ]
           }
        },
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($webcontent) = $self->{http}->request();

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

    $self->{global} = {
        rPerSec => $rPerSec,
        bPerReq => $bPerReq,
        avg_bPerSec => $avg_bPerSec,
        total_bytes => $total_bytes,
        total_access => $total_access,
        bPerSec => 0, # Will be calculated in custom_bytes_persecond_calc
        aPerSec => 0, # Will be calculated in custom_access_persecond_calc

    };

    $self->{cache_name} = 'apache_' . $self->{option_results}->{hostname}  . '_' . $self->{http}->get_port() . '_' . $self->{mode};
}

1;

__END__

=head1 MODE

Check Apache WebServer Request statistics

=over 8

=item B<--hostname>

IP Addr/FQDN of the web server host

=item B<--port>

Port used by Apache

=item B<--proto>

Specify https if needed

=item B<--urlpath>

Set path to get server-status page in auto mode (default: '/server-status/?auto')

=item B<--credentials>

Specify this option if you access server-status page with authentication

=item B<--username>

Specify the username for authentication (mandatory if --credentials is specified)

=item B<--password>

Specify the password for authentication (mandatory if --credentials is specified)

=item B<--basic>

Specify this option if you access server-status page over basic authentication and don't want a '401 UNAUTHORIZED' error to be logged on your web server.

Specify this option if you access server-status page over hidden basic authentication or you'll get a '404 NOT FOUND' error.

(use with --credentials)

=item B<--timeout>

Threshold for HTTP timeout

=item B<--header>

Set HTTP headers (multiple option)

=item B<--filter-counters>

Only display some counters (regexp can be used).
Can be : C<bytesPerSec>, C<accessPerSec>, C<avg_RequestPerSec>, C<avg_bytesPerRequest>, C<avg_bytesPerSec>
Example : --filter-counters='^accessPerSec$'

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
