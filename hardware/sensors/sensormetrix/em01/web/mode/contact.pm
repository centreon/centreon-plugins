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

package hardware::sensors::sensormetrix::em01::web::mode::contact;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
            "hostname:s"        => { name => 'hostname' },
            "port:s"            => { name => 'port', },
            "proto:s"           => { name => 'proto' },
            "urlpath:s"         => { name => 'url_path', default => "/index.htm?eL" },
            "credentials"       => { name => 'credentials' },
            "basic"             => { name => 'basic' },
            "username:s"        => { name => 'username' },
            "password:s"        => { name => 'password' },
            "warning"           => { name => 'warning' },
            "critical"          => { name => 'critical' },
            "closed"            => { name => 'closed' },
            "timeout:s"         => { name => 'timeout' },
    });
    $self->{status} = { closed => 'ok', opened => 'ok' };
    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    my $label = 'opened';
    $label = 'closed' if (defined($self->{option_results}->{closed}));
    if (defined($self->{option_results}->{critical})) {
        $self->{status}->{$label} = 'critical';
    } elsif (defined($self->{option_results}->{warning})) {
        $self->{status}->{$label} = 'warning';
    }
    
    $self->{http}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;
        
    my $webcontent = $self->{http}->request();
    my $contact;

    if ($webcontent !~ /<body>(.*)<\/body>/msi || $1 !~ /([NW]).*?:/) {
        $self->{output}->add_option_msg(short_msg => "Could not find door contact information.");
        $self->{output}->option_exit();
    }
    $contact = $1;

    if ($contact eq 'N') {
        $self->{output}->output_add(severity => $self->{status}->{opened},
                                short_msg => sprintf("Door is opened."));
    } else {
        $self->{output}->output_add(severity => $self->{status}->{closed},
                                short_msg => sprintf("Door is closed."));
    }

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check sensor contact.

=over 8

=item B<--hostname>

IP Addr/FQDN of the webserver host

=item B<--port>

Port used by Apache

=item B<--proto>

Specify https if needed

=item B<--urlpath>

Set path to get server-status page in auto mode (Default: '/index.htm?eL')

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

=item B<--warning>

Warning if door is opened (can set --close for closed door)

=item B<--critical>

Critical if door is opened (can set --close for closed door)

=item B<--closed>

Threshold is on closed door (default: opened)

=back

=cut
