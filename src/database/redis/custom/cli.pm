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

package database::redis::custom::cli;

use strict;
use warnings;
use centreon::plugins::ssh;
use centreon::plugins::misc;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self = {};
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
            'ssh-hostname:s'  => { name => 'ssh_hostname' },                
            'server:s'        => { name => 'server' },
            'port:s'          => { name => 'port' },
            'username:s'      => { name => 'username' },
            'password:s'      => { name => 'password' },
            'sentinel:s@'     => { name => 'sentinel' },
            'sentinel-port:s' => { name => 'sentinel_port' },
            'service:s'       => { name => 'service' },
            'tls'             => { name => 'tls' },
            'cacert:s'        => { name => 'cacert' },
            'insecure'        => { name => 'insecure' },
            'timeout:s'       => { name => 'timeout' }
        });
    }

    $options{options}->add_help(package => __PACKAGE__, sections => 'REDIS OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{ssh} = centreon::plugins::ssh->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{ssh_hostname} = defined($self->{option_results}->{ssh_hostname}) && $self->{option_results}->{ssh_hostname} ne '' ? $self->{option_results}->{ssh_hostname} : '';
    $self->{server} = defined($self->{option_results}->{server}) && $self->{option_results}->{server} ne '' ? $self->{option_results}->{server} : '';
    $self->{port} = defined($self->{option_results}->{port}) && $self->{option_results}->{port} ne '' ? $self->{option_results}->{port} : 6379;
    $self->{sentinel_port} = defined($self->{option_results}->{sentinel_port}) && $self->{option_results}->{sentinel_port} =~ /(\d+)/ ? $1 : 26379;
    $self->{username} = defined($self->{option_results}->{password}) && $self->{option_results}->{username} ne '' ? $self->{option_results}->{username} : '';
    $self->{password} = defined($self->{option_results}->{password}) && $self->{option_results}->{password} ne '' ? $self->{option_results}->{password} : '';
    $self->{timeout} = defined($self->{option_results}->{timeout}) && $self->{option_results}->{timeout} =~ /(\d+)/ ? $1 : 10;
    $self->{tls} = defined($self->{option_results}->{tls}) ? 1 : 0;
    $self->{insecure} = defined($self->{option_results}->{insecure}) ? 1 : 0;
    $self->{cacert} = defined($self->{option_results}->{cacert}) && $self->{option_results}->{cacert} ne '' ? $self->{option_results}->{cacert} : '';
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
    if ($self->{ssh_hostname} ne '') {
        $self->{option_results}->{hostname} = $self->{ssh_hostname};
        $self->{ssh}->check_options(option_results => $self->{option_results});
    }
    if ($self->{username} ne '' && $self->{option_results}->{password} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --password option.');
        $self->{output}->option_exit();
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

sub execute_command {
    my ($self, %options) = @_;

    my $timeout = $self->{timeout};
    if (!defined($timeout)) {
        $timeout = defined($options{timeout}) ? $options{timeout} : 10;
    }

    my ($stdout, $exit_code);
    if ($self->{ssh_hostname} ne '') {
        ($stdout, $exit_code) = $self->{ssh}->execute(
            hostname => $self->{ssh_hostname},
            sudo => $self->{option_results}->{sudo},
            command => $options{command},
            command_path => $options{command_path},
            command_options => $options{command_options},
            timeout => $timeout,
            no_quit => $options{no_quit}
        );
    } else {
        ($stdout, $exit_code) = centreon::plugins::misc::execute(
            output => $self->{output},
            sudo => $self->{option_results}->{sudo},
            options => { timeout => $timeout },
            command => $options{command},
            command_path => $options{command_path},
            command_options =>  $options{command_options},
            no_quit => $options{no_quit}
        );
    }

    $self->{output}->output_add(long_msg => "command response: $stdout", debug => 1);

    return ($stdout, $exit_code);
}

sub get_extra_options {
    my ($self, %options) = @_;

    my $options = '';
    $options .= ' --tls' if ($self->{tls} == 1);
    $options .= " --cacert '" . $self->{cacert} . "'" if ($self->{cacert} ne '');
    $options .= ' --insecure' if ($self->{insecure} == 1);
    $options .= " --user '" . $self->{username} . "'" if ($self->{username} ne '');
    $options .= " -a '" . $self->{password} . "'" if ($self->{password} ne '');
    return $options;
}

sub sentinels_get_master {
    my ($self, %options) = @_;

    my ($host, $port);
    foreach my $addr (@{$self->{sentinel}}) {
        my ($sentinel_host, $sentinel_port) = split(/:/, $addr);
        my $command_options = "-h '" . $sentinel_host . "' -p " . (defined($sentinel_port) ? $sentinel_port : 26379);
        $command_options .= ' --no-raw';
        $command_options .= ' sentinel get-master-addr-by-name ' . $self->{service};
        my ($stdout, $exit_code) = $self->execute_command(
            command => 'redis-cli',
            command_options => $command_options,
            no_quit => 1
        );
        next if ($exit_code != 0);
        $host = $1 if ($stdout =~ /1\) "(.*?)"/m);
        $port = $1 if ($stdout =~ /2\) "(\d+)"/m);
        last if (defined($port));
    }

    if (!defined($port)) {
        $self->{output}->add_option_msg(short_msg => 'Cannot find redis master (sentinels)');
        $self->{output}->option_exit();
    }
    return ($host, $port);
}

sub get_info {
    my ($self, %options) = @_;

    my $command_options;
    if (scalar(@{$self->{sentinel}}) > 0) {
        my ($host, $port) = $self->sentinels_get_master();
        $command_options = "-h '" . $host . "' -p " . $port;
    } else {
        $command_options = "-h '" . $self->{server} . "' -p " . $self->{port};
    }

    $command_options .= $self->get_extra_options();
    $command_options .= ' info';
    my ($stdout) = $self->execute_command(
        command => 'redis-cli',
        command_options => $command_options
    );

    if ($stdout =~ /^NOPERM/m) {
        $self->{output}->add_option_msg(short_msg => 'Permissions issue');
        $self->{output}->option_exit();
    }

    my $items = {};
    foreach my $line (split /\n/, $stdout) {
        if ($line =~ /^(.*?):(.*)$/) {
            $items->{$1} = $2;
        }
    }
    return $items;
}

1;

__END__

=head1 NAME

redis-cli.

=head1 SYNOPSIS

redis-cli.

=head1 REDIS OPTIONS

=over 8

=item B<--server>

Redis server.

=item B<--port>

Redis port (default: 6379).

=item B<--tls>

Establish a secure TLS connection (redis-cli >= 6.x mandatory).

=item B<--cacert>

CA Certificate file to verify with (redis-cli >= 6.x mandatory).

=item B<--insecure>

Allow insecure TLS connection by skipping cert validation (since redis-cli 6.2.0).

=item B<--username>

Redis username (redis-cli >= 6.x mandatory).

=item B<--password>

Redis password.

=item B<--sentinel>

Sentinel server. Alternative of server option. service option is required.

=item B<--sentinel-port>

Sentinel port (default: 26379).

=item B<--service>

Service parameter.

=item B<--ssh-hostname>

Remote ssh redis-cli execution.

=item B<--timeout>

Timeout in seconds for the command (default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
