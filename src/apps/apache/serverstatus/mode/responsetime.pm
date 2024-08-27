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

package apps::apache::serverstatus::mode::responsetime;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use centreon::plugins::http;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "hostname:s"   => { name => 'hostname' },
        "port:s"       => { name => 'port', },
        "proto:s"      => { name => 'proto' },
        "urlpath:s"    => { name => 'url_path', default => "/server-status/?auto" },
        "credentials"  => { name => 'credentials' },
        "basic"        => { name => 'basic' },
        "username:s"   => { name => 'username' },
        "password:s"   => { name => 'password' },
        "header:s@"    => { name => 'header' },
        "warning:s"    => { name => 'warning' },
        "critical:s"   => { name => 'critical' },
        "timeout:s"    => { name => 'timeout' },
        "unknown-status:s"     => { name => 'unknown_status', default => '' },
        "warning-status:s"     => { name => 'warning_status' },
        "critical-status:s"    => { name => 'critical_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
    });
    $self->{http} = centreon::plugins::http->new(%options);
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

    $self->{http}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;
    
    my $timing0 = [gettimeofday];
    
    my $webcontent = $self->{http}->request();

    my $timeelapsed = tv_interval ($timing0, [gettimeofday]);
    
    my $exit = $self->{perfdata}->threshold_check(value => $timeelapsed,
                                                  threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Response time %.3fs", $timeelapsed));
    $self->{output}->perfdata_add(label => "time", unit => 's',
                                  value => sprintf('%.3f', $timeelapsed),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Apache WebServer Time Response

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

=item B<--unknown-status>

Warning threshold for http response code

=item B<--warning-status>

Warning threshold for http response code

=item B<--critical-status>

Critical threshold for http response code (default: '%{http_code} < 200 or %{http_code} >= 300')

=item B<--warning>

Warning threshold in seconds (server-status page response time)

=item B<--critical>

Critical threshold in seconds (server-status page response time)

=back

=cut
