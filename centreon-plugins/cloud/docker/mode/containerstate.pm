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

package cloud::docker::mode::containerstate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON;

my $thresholds = {
    state => [
        ['Running', 'OK'],
        ['Paused', 'WARNING'],
        ['Restarting', 'WARNING'],
        ['OOMKilled', 'CRITICAL'],
        ['Dead', 'CRITICAL'],
        ['Exited', 'CRITICAL'],
    ],
};

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
            "urlpath:s"                 => { name => 'url_path', default => '/' },
            "name:s"                    => { name => 'name' },
            "id:s"                      => { name => 'id' },
            "credentials"               => { name => 'credentials' },
            "username:s"                => { name => 'username' },
            "password:s"                => { name => 'password' },
            "ssl:s"                     => { name => 'ssl', },
            "cert-file:s"               => { name => 'cert_file' },
            "key-file:s"                => { name => 'key_file' },
            "cacert-file:s"             => { name => 'cacert_file' },
            "timeout:s"                 => { name => 'timeout' },
            "threshold-overload:s@"     => { name => 'threshold_overload' },
        });

    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if ((defined($self->{option_results}->{name})) && ($self->{option_results}->{name} eq '')) {
        $self->{output}->add_option_msg(short_msg => "You need to specify the name option");
        $self->{output}->option_exit();
    }

    if ((defined($self->{option_results}->{id})) && ($self->{option_results}->{id} eq '')) {
        $self->{output}->add_option_msg(short_msg => "You need to specify the id option");
        $self->{output}->option_exit();
    }

    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }

    if (defined($self->{option_results}->{id})) {
        $self->{option_results}->{url_path} = "/containers/".$self->{option_results}->{id}."/json";
    } elsif (defined($self->{option_results}->{name})) {
        $self->{option_results}->{url_path} = "/containers/".$self->{option_results}->{name}."/json";
    } else {
        $self->{option_results}->{url_path} = "/containers/json";
        $self->{option_results}->{get_param} = [];
        push @{$self->{option_results}->{get_param}}, "all=true";
    }
    $self->{http}->set_options(%{$self->{option_results}});

}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default

    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    return $status;
}

sub run {
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

    my ($result,$containername,$containertime);
    my $exit = 'OK';

    if (defined($self->{option_results}->{id}) || defined($self->{option_results}->{name})) {
        while ( my ($keys,$values) = each(%{$webcontent->{State}})) {
            # Why not set a variable that contains the state?
            if ($values eq 'true') {
                $result = $keys;
                $containername = $webcontent->{Name};
                $containername =~ s/^\///;
                my ( $y, $m, $d, $h, $mi, $s ) = $webcontent->{State}->{StartedAt} =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/;
                $containertime = $y."-".$m."-".$d." ".$h.":".$mi.":".$s;
                last;
            }
        }

        $exit = $self->get_severity(section => 'state', value => $result);
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Container %s is %s (started since %s)", $containername, $result, $containertime));
    } else {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf("All containers are in Running state"));

        my ($nbrunning,$nbpaused,$nbexited) = '0';

        foreach my $val (@$webcontent) {
            $containername = $val->{Names}->[0];
            $containername =~ s/^\///;

            # Thanks to Docker API for the paused state...
            if (($val->{Status} =~ m/^Up/) && ($val->{Status} =~ m/^(?:(?!Paused).)*$/)) {
                $result = 'Running';
                $nbrunning++;
            } elsif ($val->{Status} =~ m/^Exited/) {
                $result = 'Exited';
                $nbexited++;
            } elsif ($val->{Status} =~ m/\(Paused\)$/) {
                $result = 'Paused';
                $nbpaused++;
            }

            my $tmp_exit = $self->get_severity(section => 'state', value => $result);
            $exit = $self->{output}->get_most_critical(status => [ $tmp_exit, $exit ]);
            if (!$self->{output}->is_status(value => $tmp_exit, compare => 'OK', litteral => 1)) {
                $self->{output}->output_add(long_msg => sprintf("Containers %s is in %s state",
                                                                    $containername, $result));
            }
        }

        if (!$self->{output}->is_status(value => $exit, compare => 'OK', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Some containers are in wrong state"));
        }
        $self->{output}->perfdata_add(label => "running",
                                        value => $nbrunning,
                                        min => 0,
                                     );
        $self->{output}->perfdata_add(label => "paused",
                                        value => $nbpaused,
                                        min => 0,
                                     );
        $self->{output}->perfdata_add(label => "exited",
                                        value => $nbexited,
                                        min => 0,
                                     );
    }

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check Container's state

=over 8

=item B<--hostname>

IP Addr/FQDN of Docker's API

=item B<--port>

Port used by Docker's API (Default: '2576')

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--urlpath>

Set path to get Docker's container information (Default: '/')

=item B<--id>

Specify one container's id

=item B<--name>

Specify one container's name

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

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='state,CRITICAL,^(?!(Paused)$)'

=back

=cut
