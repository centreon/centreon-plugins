#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package cloud::docker::mode::info;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
        {
            "hostname:s"                => { name => 'hostname' },
            "port:s"                    => { name => 'port', default => '2376'},
            "proto:s"                   => { name => 'proto', default => 'https' },
            "urlpath:s"                 => { name => 'url_path', default => '/info' },
            "credentials"               => { name => 'credentials' },
            "username:s"                => { name => 'username' },
            "password:s"                => { name => 'password' },
            "ssl:s"                     => { name => 'ssl', },
            "cert-file:s"               => { name => 'cert_file' },
            "key-file:s"                => { name => 'key_file' },
            "cacert-file:s"             => { name => 'cacert_file' },
            "timeout:s"                 => { name => 'timeout' },
        });

    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{http}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;


    my $jsoncontent = $self->{http}->request();;

    my $json = JSON->new;

    my $webcontent;

    eval {
        $webcontent = $json->decode($jsoncontent);
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }


    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("Docker is running"));

    $self->{output}->perfdata_add(label => "containers",
                                  value => $webcontent->{Containers},
                                  min => 0,
                                 );

    $self->{output}->perfdata_add(label => "events_listener",
                                  value => $webcontent->{NEventsListener},
                                  min => 0,
                                 );

    $self->{output}->perfdata_add(label => "file_descriptor",
                                  value => $webcontent->{NFd},
                                  min => 0,
                                 );

    $self->{output}->perfdata_add(label => "go_routines",
                                  value => $webcontent->{NGoroutines},
                                  min => 0,
                                 );

    $self->{output}->perfdata_add(label => "images",
                                  value => $webcontent->{Images},
                                  min => 0,
                                 );


    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check Docker information

=over 8

=item B<--hostname>

IP Addr/FQDN of Docker's API

=item B<--port>

Port used by Docker's API (Default: '2576')

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--urlpath>

Set path to get Docker information (Default: '/')

=item B<--credentials>

Specify this option if you access webpage over basic authentification

=item B<--username>

Specify username

=item B<--password>

Specify password

=item B<--ssl>

Specify SSL version (example : 'sslv3', 'tlsv1'...)

=item B<--cert-file>

Specify certificate to send to the webserver

=item B<--key-file>

Specify key to send to the webserver

=item B<--cacert-file>

Specify root certificate to send to the webserver

=item B<--timeout>

Threshold for HTTP timeout (Default: 3)

=back

=cut
