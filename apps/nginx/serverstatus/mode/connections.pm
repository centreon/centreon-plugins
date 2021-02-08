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

package apps::nginx::serverstatus::mode::connections;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;

my $maps = [
    { counter => 'active', output => 'Active connections %d', match => 'Active connections:\s*(\d+)' },
    { counter => 'reading', output => 'Reading connections %d', match => 'Reading:\s*(\d+)' }, 
    { counter => 'writing', output => 'Writing connections %d', match => 'Writing:\s*(\d+)' },
    { counter => 'waiting', output => 'Waiting connections %d', match => 'Waiting:\s*(\d+)' },
];

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "hostname:s"    => { name => 'hostname' },
        "port:s"        => { name => 'port', },
        "proto:s"       => { name => 'proto' },
        "urlpath:s"     => { name => 'url_path', default => "/nginx_status" },
        "credentials"   => { name => 'credentials' },
        "basic"         => { name => 'basic' },
        "username:s"    => { name => 'username' },
        "password:s"    => { name => 'password' },
        "timeout:s"     => { name => 'timeout' },
    });
    foreach (@{$maps}) {
        $options{options}->add_options(arguments => {
                                                    'warning-' . $_->{counter} . ':s'    => { name => 'warning_' . $_->{counter} },
                                                    'critical-' . $_->{counter} . ':s'    => { name => 'critical_' . $_->{counter} },
                                                    });
    }
    
    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    foreach (@{$maps}) {
        if (($self->{perfdata}->threshold_validate(label => 'warning-' . $_->{counter}, value => $self->{option_results}->{'warning_' . $_->{counter}})) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong warning-" . $_->{counter} . " threshold '" . $self->{option_results}->{'warning_' . $_->{counter}} . "'.");
            $self->{output}->option_exit();
        }
        if (($self->{perfdata}->threshold_validate(label => 'critical-' . $_->{counter}, value => $self->{option_results}->{'critical_' . $_->{counter}})) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong critical-" . $_->{counter} . " threshold '" . $self->{option_results}->{'critical_' . $_->{counter}} . "'.");
            $self->{output}->option_exit();
        }
    }

    $self->{http}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;
        
    my $webcontent = $self->{http}->request();
    foreach (@{$maps}) {
        if ($webcontent !~ /$_->{match}/msi) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => "Cannot find " . $_->{counter} . " connections.");
            next;
        }
        my $value = $1;
        my $exit = $self->{perfdata}->threshold_check(value => $value, threshold => [ { label => 'critical-' . $_->{counter}, 'exit_litteral' => 'critical' }, { label => 'warning-' . $_->{counter}, 'exit_litteral' => 'warning' }]);
 
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf($_->{output}, $value));

        $self->{output}->perfdata_add(label => $_->{counter},
                                      value => $value,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $_->{counter}),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $_->{counter}),
                                      min => 0);
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check current connections: active, reading, writing, waiting.

=over 8

=item B<--hostname>

IP Addr/FQDN of the webserver host

=item B<--port>

Port used by Apache

=item B<--proto>

Protocol to use http or https, http is default

=item B<--urlpath>

Set path to get server-status page in auto mode (Default: '/nginx_status')

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

=item B<--warning-*>

Warning Threshold. Can be: 'active', 'waiting', 'writing', 'reading'.

=item B<--critical-*>

Critical Threshold. Can be: 'active', 'waiting', 'writing', 'reading'.

=back

=cut
