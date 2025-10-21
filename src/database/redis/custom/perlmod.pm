#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package database::redis::custom::perlmod;

use strict;
use warnings;
use Redis;
use Digest::MD5 qw(md5_hex);

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
            'server:s'        => { name => 'server' },
            'port:s'          => { name => 'port' },
            'username:s'      => { name => 'username' },
            'password:s'      => { name => 'password' },
            'sentinel:s@'     => { name => 'sentinel' },
            'sentinel-port:s' => { name => 'sentinel_port' },
            'service:s'       => { name => 'service' },
            'tls'             => { name => 'tls' },
            'cacert:s'        => { name => 'cacert' },
            'cert:s'          => { name => 'cert' },
            'key:s'           => { name => 'key' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REDIS OPTIONS', once => 1);

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

    $self->{server} = $self->{option_results}->{server} // '';
    $self->{port} = defined($self->{option_results}->{port}) && $self->{option_results}->{port} =~ /(\d+)/ ? $1 : 6379;
    $self->{sentinel_port} = defined($self->{option_results}->{sentinel_port}) && $self->{option_results}->{sentinel_port} =~ /(\d+)/ ? $1 : 26379;
    $self->{username} = $self->{option_results}->{username} // '';
    $self->{password} = $self->{option_results}->{password} // '';
    $self->{cacert} = $self->{option_results}->{cacert} // '';
    $self->{cert} = $self->{option_results}->{cert} // '';
    $self->{key} = $self->{option_results}->{key} // '';
    $self->{sentinel} = [];
    if (defined($self->{option_results}->{sentinel})) {
        foreach my $addr (@{$self->{option_results}->{sentinel}}) {
            next if ($addr eq '');

            push @{$self->{sentinel}}, $addr . ($self->{sentinel_port} ne '' ? ':' . $self->{sentinel_port} : '') 
        }
    }
    $self->{service} = defined($self->{option_results}->{service}) && $self->{option_results}->{service} ne '' ? $self->{option_results}->{service} : '';

    if ($self->{server} eq '' && scalar(@{$self->{sentinel}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --server or --sentinel option.');
        $self->{output}->option_exit();
    }
    if (scalar(@{$self->{sentinel}}) > 0 && $self->{service} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --service option.');
        $self->{output}->option_exit();
    }

    foreach (qw/cert key/) {
	      if ($self->{$_} ne '') {
            $self->{output}->add_option_msg(short_msg => "Unsupported --$_ option.");
	          $self->{output}->option_exit();
        }
    }

    return 0;
}

sub get_connection_info {
    my ($self, %options) = @_;

    my $id = '';
    if ($self->{server} ne '') {
        $id = $self->{server} . ':' . $self->{port};
    } else {
        foreach (@{$self->{sentinel}}) {
            $id .= $_ . '-';
        }
    }
    return md5_hex($id);
}

sub get_info {
    my ($self, %options) = @_;

    my $redis;
    if (scalar(@{$self->{sentinel}}) > 0) {
        $redis = Redis->new(sentinels => $self->{sentinel}, service => $self->{service});
    } else {
        $redis = Redis->new(server => $self->{server} . ':' . $self->{port});
    }
    if ($self->{username} ne '' && $self->{password} ne '') {
        $redis->auth($self->{username}, $self->{password});
    } elsif ($self->{password} ne '') {
        # Anonymous connexion
        $redis->auth($self->{password});
    }

    my $response = $redis->info();
    my $items;
    foreach my $attributes (keys %$response) {
        $items->{$attributes} = $response->{$attributes};
    }

    $redis->quit();

    return $items;
}

1;

__END__

=head1 NAME

REDIS Perl mode

=head1 SYNOPSIS

Redis Perl mode

=head1 REDIS OPTIONS

=over 8

=item B<--server>

Redis server.

=item B<--port>

Redis port (default: 6379).

=item B<--username>

Redis username.

=item B<--password>

Redis password.

=item B<--sentinel>

Sentinel server. Alternative of server option. service option is required.

=item B<--sentinel-port>

Sentinel port (default: 26379).

=item B<--service>

Service parameter.

=back

=head1 DESCRIPTION

B<custom>.

=cut
