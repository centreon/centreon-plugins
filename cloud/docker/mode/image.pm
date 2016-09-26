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

package cloud::docker::mode::image;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.1';
    $options{options}->add_options(arguments =>
        {
            "port:s"                => { name => 'port' },
            "name:s"                => { name => 'name' },
            "id:s"                  => { name => 'id' },
            "image:s"               => { name => 'image' },
            "registry-hostname:s"   => { name => 'registry_hostname' },
            "registry-proto:s"      => { name => 'registry_proto', default => 'https' },
            "registry-port:s"       => { name => 'registry_port' },
            "credentials"           => { name => 'credentials' },
            "username:s"            => { name => 'username' },
            "password:s"            => { name => 'password' },
            "ssl:s"                 => { name => 'ssl', },
            "cert-file:s"           => { name => 'cert_file' },
            "key-file:s"            => { name => 'key_file' },
            "cacert-file:s"         => { name => 'cacert_file' },
            "timeout:s"             => { name => 'timeout' },
        });

    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if ((defined($self->{option_results}->{name})) && (defined($self->{option_results}->{id}))) {
        $self->{output}->add_option_msg(short_msg => "Please set the name or id option");
        $self->{output}->option_exit();
    }

    if ((!defined($self->{option_results}->{name})) && (!defined($self->{option_results}->{id}))) {
        $self->{output}->add_option_msg(short_msg => "Please set the name or id option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{image})) {
        $self->{output}->add_option_msg(short_msg => "Please set the image option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{registry_hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the registry-hostname option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{registry_proto})) {
        $self->{output}->add_option_msg(short_msg => "Please set the registry-proto option");
        $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;

    my ($jsoncontent, $webcontent, $webcontent2);

    my $urlpath;
    if (defined($self->{option_results}->{id})) {
        $urlpath = "/containers/".$self->{option_results}->{id}."/stats";
    } elsif (defined($self->{option_results}->{name})) {
        $urlpath = "/containers/".$self->{option_results}->{name}."/stats";
    }
    my $port = $self->{option_results}->{port};
    my $containerapi = $options{custom};

    $webcontent = $containerapi->api_request(urlpath => $urlpath,
                                            port => $port);

    my $container_id = $webcontent->{Image};

    $self->{option_results}->{url_path} = "/v1/repositories/".$self->{option_results}->{image}."/tags";
    $self->{option_results}->{port} = $self->{option_results}->{registry_port};
    $self->{option_results}->{proto} = $self->{option_results}->{registry_proto};
    $self->{option_results}->{hostname} = $self->{option_results}->{registry_hostname};
    $self->{http}->set_options(%{$self->{option_results}});

    $jsoncontent = $self->{http}->request();

    my $json2 = JSON->new;

    eval {
        $webcontent2 = $json2->decode($jsoncontent);
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    my $result;

    foreach (@{$webcontent2}) {
        if (($container_id =~ /^$_->{layer}\w+$/)) {
            $result="1";
            last;
        }
    }

    if ($result eq "1") {
        $self->{output}->output_add(severity => "OK",
                                    short_msg => sprintf("Container's image and Registry image are identical"));
    } else {
        $self->{output}->output_add(severity => "CRITICAL",
                                    short_msg => sprintf("Container's image and Registry image are different"));
    }

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check Container's image viability with a registry

=head2 DOCKER OPTIONS

=item B<--port>

Port used by Docker

=item B<--id>

Specify the container's id

=item B<--name>

Specify the container's name

=head2 MODE OPTIONS

=item B<--image>

Specify the image's name

=item B<--registry-hostname>

IP Addr/FQDN of Docker's Registry

=item B<--registry-port>

Port used by Docker's Registry

=item B<--registry-proto>

Specify https if needed (Default: 'https')

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
