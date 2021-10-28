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

package apps::redis::cli::custom::rediscli;

use strict;
use warnings;
use Redis;

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
            'password:s' => { name => 'password' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REDIS CLI OPTIONS', once => 1);

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

    $self->{hostname} = $self->{option_results}->{hostname};
    $self->{port} = $self->{option_results}->{port};
    $self->{password} = $self->{option_results}->{password};

    if (!defined($self->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname argument.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{port})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify port argument.");
        $self->{output}->option_exit();
    }

    return 0;
}

sub get_connection_info {
    my ($self, %options) = @_;
    
    return $self->{hostname} . ":" . $self->{port};
}

sub get_info {
    my ($self, %options) = @_;

    $self->{redis} = Redis->new(server => $self->{hostname} . ":" . $self->{port});
    if (defined($self->{password})) {
        $self->{redis}->auth($self->{password});
    }
    
    my $response = $self->{redis}->info;
    my $items;
    foreach my $attributes (keys %{$response}) {
        $items->{$attributes} = $response->{$attributes};
    }

    $self->{redis}->quit();

    return $items;
}

1;

__END__

=head1 NAME

REDIS CLI

=head1 SYNOPSIS

Redis Cli custom mode

=head1 REDIS CLI OPTIONS

=over 8

=item B<--hostname>

Redis hostname.

=item B<--port>

Redis port.

=item B<--password>

Redis password

=back

=head1 DESCRIPTION

B<custom>.

=cut
