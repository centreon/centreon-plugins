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

package cloud::docker::mode::listcontainers;

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
            "hostname:s"            => { name => 'hostname' },
            "port:s"                => { name => 'port', default => '2376'},
            "proto:s"               => { name => 'proto', default => 'https' },
            "urlpath:s"             => { name => 'url_path', default => '/' },
            "credentials"           => { name => 'credentials' },
            "username:s"            => { name => 'username' },
            "password:s"            => { name => 'password' },
            "ssl:s"                 => { name => 'ssl', },
            "cert-file:s"           => { name => 'cert_file' },
            "key-file:s"            => { name => 'key_file' },
            "cacert-file:s"         => { name => 'cacert_file' },
            "exclude:s"             => { name => 'exclude' },
            "timeout:s"             => { name => 'timeout' },
        });

    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    $self->{container_infos} = ();
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{option_results}->{url_path} = $self->{option_results}->{url_path}."containers/json";
    $self->{option_results}->{get_param} = [];
    push @{$self->{option_results}->{get_param}}, "all=true";

    $self->{http}->set_options(%{$self->{option_results}})
}

sub check_exclude {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)${options{status}}(\s|,|$)/) {
        $self->{output}->output_add(long_msg => sprintf("Skipping ${options{status}} container."));
        return 1;
    }
return 0;
}

sub api_request {
    my ($self, %options) = @_;

    my $jsoncontent = $self->{http}->request();

    my $json = JSON->new;

    my $webcontent;

    eval {
        $webcontent = $json->decode($jsoncontent);
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    foreach my $val (@$webcontent) {
        my $containerstate;
        if (($val->{Status} =~ m/^Up/) && ($val->{Status} =~ m/^(?:(?!Paused).)*$/)) {
            return if ($self->check_exclude(status => 'Running'));
            $containerstate = 'Running';
        } elsif ($val->{Status} =~ m/^Exited/) {
            return if ($self->check_exclude(status => 'Exited'));
            $containerstate = 'Exited';
        } elsif ($val->{Status} =~ m/\(Paused\)$/) {
            return if ($self->check_exclude(status => 'Paused'));
            $containerstate = 'Paused';
        }
        my $containername = $val->{Names}->[0];
        $containername =~ s/^\///;
        $self->{container_infos}->{$containername}->{id} = $val->{Id};
        $self->{container_infos}->{$containername}->{image} = $val->{Image};
        $self->{container_infos}->{$containername}->{state} = $containerstate;
    }
}

sub disco_format {
    my ($self, %options) = @_;

    my $names = ['name', 'id', 'image', 'state'];
    $self->{output}->add_disco_format(elements => $names);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->api_request();

    foreach my $containername (keys %{$self->{container_infos}}) {
        $self->{output}->add_disco_entry(name => $containername,
                                         id => $self->{container_infos}->{$containername}->{id},
                                         image => $self->{container_infos}->{$containername}->{image},
                                         state => $self->{container_infos}->{$containername}->{state},
                                        );
    }
}

sub run {
    my ($self, %options) = @_;

    $self->api_request();

    foreach my $containername (keys %{$self->{container_infos}}) {
        $self->{output}->output_add(long_msg => sprintf("%s [id = %s , image = %s, state = %s]",
                                                        $containername,
                                                        $self->{container_infos}->{$containername}->{id},
                                                        $self->{container_infos}->{$containername}->{image},
                                                        $self->{container_infos}->{$containername}->{state}));
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List containers:');

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

List Docker containers

=over 8

=item B<--hostname>

IP Addr/FQDN of Docker's API

=item B<--port>

Port used by Docker's API (Default: '2576')

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--urlpath>

Set path to get Docker containers (Default: '/')

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

=item B<--exlude>

Exclude specific container's state (comma seperated list) (Example: --exclude=Paused,Running)

=item B<--timeout>

Threshold for HTTP timeout (Default: 3)

=back

=cut
