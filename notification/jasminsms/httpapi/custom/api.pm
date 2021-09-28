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

package notification::jasminsms::httpapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;

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
            'hostname:s@'    => { name => 'hostname' },
            'api-username:s' => { name => 'api_username' },
            'api-password:s' => { name => 'api_password' },
            'port:s'         => { name => 'port' },
            'proto:s'        => { name => 'proto' },
            'timeout:s'      => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);
    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostnames} = [];
    if (defined($self->{option_results}->{hostname})) {
        foreach my $hostname (@{$self->{option_results}->{hostname}}) {
            next if ($hostname eq '');
            push @{$self->{hostnames}}, $hostname;
        }
    }

    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 1401;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'http';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 20;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';

    if (scalar(@{$self->{hostnames}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }
    if ($self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-username option.");
        $self->{output}->option_exit();
    }
    if ($self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-password option.");
        $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{$self->{option_results}});
    return 0;
}

sub send_sms {
    my ($self, %options) = @_;

    my $get_param = [
        'username=' . $self->{api_username},
        'password=' . $self->{api_password},
        'to=' . $options{to},
        'coding=' . $options{coding},
        'hex-content=' . $options{message}
    ];
    if (defined($options{from}) && $options{from} ne '') {
        push @$get_param, 'from=' . $options{from};
    }
    if (defined($options{dlr}) && $options{dlr} eq 'yes') {
        push @$get_param, 'dlr=yes', 'dlr-url=' . $options{dlr_url},
            'dlr-level=' . $options{dlr_level}, 'dlr-method=' . $options{dlr_method};
    }

    my $rv = 'Error sending sms';
    my $num = scalar(@{$self->{hostnames}});
    for (my $i = 0; $i < $num; $i++) {
        my ($response) = $self->{http}->request(
            hostname => $self->{hostnames}->[$i],
            port => $self->{port},
            proto => $self->{proto},
            url_path => '/send',
            timeout => $self->{timeout},
            unknown_status => '',
            warning_status => '',
            critical_status => '',
            get_param => $get_param
        );
        if ($self->{http}->get_code() == 200) {
            if ($response =~ /^Success/) {
                $rv = $response;
                last;
            }
        } else {
            $rv = $response if ($response =~ /^Error/);
        }
    }

    return $rv;
}

1;

__END__

=head1 NAME

Jasmin SMS HTTP-API

=head1 HTTP API OPTIONS

Jasmin SMS HTTP API

=over 8

=item B<--hostname>

Hostname (can be multiple if you want a failover system).

=item B<--port>

Port used (Default: 1401)

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--api-username>

API username.

=item B<--api-password>

API password.

=item B<--timeout>

Set timeout in seconds (Default: 20).

=back

=head1 DESCRIPTION

B<custom>.

=cut
