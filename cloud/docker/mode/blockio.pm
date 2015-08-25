#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package cloud::docker::mode::blockio;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
        {
            "hostname:s"        => { name => 'hostname' },
            "port:s"            => { name => 'port', default => '2376'},
            "proto:s"           => { name => 'proto', default => 'https' },
            "urlpath:s"         => { name => 'url_path', default => '/' },
            "name:s"            => { name => 'name' },
            "id:s"              => { name => 'id' },
            "warning-read:s"    => { name => 'warning-read' },
            "critical-read:s"   => { name => 'critical-read' },
            "warning-write:s"   => { name => 'warning-write' },
            "critical-write:s"  => { name => 'critical-write' },
            "credentials"       => { name => 'credentials' },
            "username:s"        => { name => 'username' },
            "password:s"        => { name => 'password' },
            "ssl:s"             => { name => 'ssl', },
            "cert-file:s"       => { name => 'cert_file' },
            "key-file:s"        => { name => 'key_file' },
            "cacert-file:s"     => { name => 'cacert_file' },
            "timeout:s"         => { name => 'timeout' },
        });

    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
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
    if (($self->{perfdata}->threshold_validate(label => 'warning-read', value => $self->{option_results}->{warning_read})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning 'read' threshold '" . $self->{option_results}->{warning_read} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-read', value => $self->{option_results}->{critical_read})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical 'read' threshold '" . $self->{option_results}->{critical_read} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-write', value => $self->{option_results}->{warning_write})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning 'write' threshold '" . $self->{option_results}->{warning_write} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-write', value => $self->{option_results}->{critical_write})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical 'write' threshold '" . $self->{option_results}->{critical_write} . "'.");
        $self->{output}->option_exit();
    }

    $self->{option_results}->{get_param} = [];
    push @{$self->{option_results}->{get_param}}, "stream=false";
    if (defined($self->{option_results}->{id})) {
        $self->{option_results}->{url_path} = "/containers/".$self->{option_results}->{id}."/stats";
    } elsif (defined($self->{option_results}->{name})) {
        $self->{option_results}->{url_path} = "/containers/".$self->{option_results}->{name}."/stats";
    }

    $self->{http}->set_options(%{$self->{option_results}});
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;

    my $new_datas = {};

    if (defined($self->{option_results}->{id})) {
        $self->{statefile_value}->read(statefile => 'docker_' . $self->{option_results}->{id}  . '_' . $self->{http}->get_port() . '_' . $self->{mode});
    } elsif (defined($self->{option_results}->{name})) {
        $self->{statefile_value}->read(statefile => 'docker_' . $self->{option_results}->{name}  . '_' . $self->{http}->get_port() . '_' . $self->{mode});
    }

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

    my $read_bytes = $webcontent->{blkio_stats}->{io_service_bytes_recursive}->[0]->{value};
    my $write_bytes = $webcontent->{blkio_stats}->{io_service_bytes_recursive}->[1]->{value};
    $new_datas->{read_bytes} = $read_bytes;
    $new_datas->{write_bytes} = $write_bytes;
    $new_datas->{last_timestamp} = time();
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');

    # First execution
    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{statefile_value}->write(data => $new_datas);
        $self->{output}->display();
        $self->{output}->exit();
    }

    my $time_delta = $new_datas->{last_timestamp} - $old_timestamp;
        if ($time_delta <= 0) {
            # At least one second. two fast calls ;)
            $time_delta = 1;
    }

    my $old_read_bytes = $self->{statefile_value}->get(name => 'read_bytes');
    my $old_write_bytes = $self->{statefile_value}->get(name => 'write_bytes');

    if ($new_datas->{read_bytes} < $old_read_bytes) {
        # We set 0. Has reboot.
        $old_read_bytes = 0;
    }
    if ($new_datas->{write_bytes} < $old_write_bytes) {
        # We set 0. Has reboot.
        $old_write_bytes = 0;
    }

    my $delta_read_bytes = $read_bytes - $old_read_bytes;
    my $delta_write_bytes = $write_bytes - $old_write_bytes;
    my $read_absolute_per_sec = $delta_read_bytes / $time_delta;
    my $write_absolute_per_sec = $delta_write_bytes / $time_delta;

    my $exit1 = $self->{perfdata}->threshold_check(value => $read_absolute_per_sec, threshold => [ { label => 'critical-read', 'exit_litteral' => 'critical' }, { label => 'warning-read', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $write_absolute_per_sec, threshold => [ { label => 'critical-write', 'exit_litteral' => 'critical' }, { label => 'warning-write', exit_litteral => 'warning' } ]);

    my ($read_value, $read_unit) = $self->{perfdata}->change_bytes(value => $read_absolute_per_sec, network => 1);
    my ($write_value, $write_unit) = $self->{perfdata}->change_bytes(value => $write_absolute_per_sec, network => 1);
    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Read I/O : %s/s, Write I/O : %s/s",
                                    $read_value . $read_unit,
                                    $write_value . $write_unit));

    $self->{output}->perfdata_add(label => 'read_io', unit => 'B/s',
                                    value => sprintf("%.2f", $read_absolute_per_sec),
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-read'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-read'),
                                    min => 0);
    $self->{output}->perfdata_add(label => 'write_io', unit => 'B/s',
                                    value => sprintf("%.2f", $write_absolute_per_sec),
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-write'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-write'),
                                    min => 0);

    $self->{statefile_value}->write(data => $new_datas);

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check Container's Block I/O usage

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

=item B<--warning-read>

Threshold warning in B/s for Read I/O.

=item B<--critical-read>

Threshold critical in B/s for Read I/O.

=item B<--warning-write>

Threshold warning in B/s for Write I/O.

=item B<--critical-write>

Threshold critical in B/s for Write I/O.

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
