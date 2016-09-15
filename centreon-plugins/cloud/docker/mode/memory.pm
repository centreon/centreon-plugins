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

package cloud::docker::mode::memory;

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
            "hostname:s"        => { name => 'hostname' },
            "port:s"            => { name => 'port', default => '2376'},
            "proto:s"           => { name => 'proto', default => 'https' },
            "urlpath:s"         => { name => 'url_path', default => '/' },
            "name:s"            => { name => 'name' },
            "id:s"              => { name => 'id' },
            "warning:s"         => { name => 'warning' },
            "critical:s"        => { name => 'critical' },
            "credentials"       => { name => 'credentials' },
            "username:s"        => { name => 'username' },
            "password:s"        => { name => 'password' },
            "ssl:s"             => { name => 'ssl', },
            "cert-file:s"       => { name => 'cert_file' },
            "key-file:s"        => { name => 'key_file' },
            "cacert-file:s"     => { name => 'cacert_file' },
            "timeout:s"         => { name => 'timeout' },
        });

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

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
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

    my $total_size = $webcontent->{memory_stats}->{limit};
    my $memory_used = $webcontent->{memory_stats}->{usage};
    my $memory_free = $webcontent->{memory_stats}->{limit} - $webcontent->{memory_stats}->{usage};
    my $prct_used = $memory_used * 100 / $total_size;
    my $prct_free = 100 - $prct_used;

    my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_size);
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $memory_used);
    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $memory_free);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Memory Total: %s Used: %s (%.2f%%) Free: %s %.2f%%)",
                                                    $total_value . " " . $total_unit,
                                                    $used_value . " " . $used_unit, $prct_used,
                                                    $free_value . " " . $free_unit, $prct_free)
                                );

    $self->{output}->perfdata_add(label => "used",
                                  value => $webcontent->{memory_stats}->{usage},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $total_size, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $total_size, cast_int => 1),
                                  min => 0,
                                  max => $webcontent->{memory_stats}->{limit},
                                 );

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check Container's memory usage

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

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

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
