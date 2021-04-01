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

package apps::hddtemp::custom::tcp;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use IO::Socket;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'hostname:s' => { name => 'hostname' },
            'port:s'     => { name => 'port' },
            'timeout:s'  => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'CUSTOM TCP OPTIONS', once => 1);

    $self->{output} = $options{output};

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port}     = (defined($self->{option_results}->{port})) && $self->{option_results}->{port} =~ /(\d+)/ ? $1 : 7634;
    $self->{timeout}  = (defined($self->{option_results}->{timeout})) && $self->{option_results}->{timeout} =~ /(\d+)/ ? $1 : 30;

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }

    return 0;
}

sub get_hddtemp_drives {
    my ($self, %options) = @_;

    my $socket = new IO::Socket::INET(
        Proto      => 'tcp', 
        PeerAddr   => $self->{hostname},
        PeerPort   => $self->{port},
        Timeout    => $self->{timeout}
    );
    
    if (!defined($socket)) {
        $self->{output}->add_option_msg(short_msg => "could not connect: $@");
        $self->{output}->option_exit();
    }

    my $line;
    eval {
        local $SIG{ALRM} = sub { die 'Timeout'; };
        alarm($self->{timeout});
        $line = <$socket>;
        alarm(0);
    };
    $socket->shutdown(2);
    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'cannot get informations: ' . $@);
        $self->{output}->option_exit();
    }

    return $line;
}

sub list_drives {
    my ($self, %options) = @_;

    my $line = $self->get_hddtemp_drives();
    my $drives = {};
    while ($line =~ /\|(.*?)\|(.*?)\|(.*?)\|(.*?)\|/msg) {
        $drives->{$1} = {};
    }

    return $drives;
}

sub get_drives_information {
    my ($self, %options) = @_;

    my $line = $self->get_hddtemp_drives();

    #|/dev/sda|SanDisk ....|33|C|
    #|/dev/sda|Scan ....   |NA|*|
    my $mapping_errors = {
        NA => 'notApplicable',
        UNK => 'unknown',
        NOS => 'noSensor',
        SLP => 'driveSleep',
        ERR => 'error'
    };

    my $drives = {};
    while ($line =~ /\|(.*?)\|(.*?)\|(.*?)\|(.*?)\|/msg) {
        my ($name, $value, $unit) = ($1, $3, $4);
        if ($value =~ /\d+/) {
            $drives->{$name} = { temperature => $value, temperature_unit => $unit, status => 'ok' };
        } else {
            $drives->{$name} = { status => $mapping_errors->{$value} };
        }
    }

    return $drives;
}

1;

__END__

=head1 NAME

Hddtemp

=head1 CUSTOM TCP OPTIONS

Hddtemp tcp

=over 8

=item B<--hostname>

Hostname or IP address.

=item B<--port>

Port used (Default: 7634)

=item B<--timeout>

Set timeout in seconds (Default: 30).

=back

=head1 DESCRIPTION

B<custom>.

=cut
