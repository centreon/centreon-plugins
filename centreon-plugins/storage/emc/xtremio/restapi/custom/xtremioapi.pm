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

package storage::emc::xtremio::restapi::custom::xtremioapi;

use strict;
use warnings;
use centreon::plugins::http;
use JSON;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;
    # $options{options} = options object
    # $options{output} = output object
    # $options{exit_value} = integer
    # $options{noptions} = integer

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => 
                    {
                      "hostname:s@"          => { name => 'hostname', },
                      "xtremio-username:s@"  => { name => 'xtremio_username', },
                      "xtremio-password:s@"  => { name => 'xtremio_password', },
                      "proxyurl:s@"          => { name => 'proxyurl', },
                      "timeout:s@"           => { name => 'timeout', },
                    });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{mode} = $options{mode};    
    $self->{http} = centreon::plugins::http->new(output => $self->{output});

    return $self;

}

# Method to manage multiples
sub set_options {
    my ($self, %options) = @_;
    # options{options_result}

    $self->{option_results} = $options{option_results};
}

# Method to manage multiples
sub set_defaults {
    my ($self, %options) = @_;
    # options{default}
    
    # Manage default value
    foreach (keys %{$options{default}}) {
        if ($_ eq $self->{mode}) {
            for (my $i = 0; $i < scalar(@{$options{default}->{$_}}); $i++) {
                foreach my $opt (keys %{$options{default}->{$_}[$i]}) {
                    if (!defined($self->{option_results}->{$opt}[$i])) {
                        $self->{option_results}->{$opt}[$i] = $options{default}->{$_}[$i]->{$opt};
                    }
                }
            }
        }
    }
}

sub check_options {
    my ($self, %options) = @_;
#    # return 1 = ok still hostname
#    # return 0 = no hostname left

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? shift(@{$self->{option_results}->{hostname}}) : undef;
    $self->{xtremio_username} = (defined($self->{option_results}->{xtremio_username})) ? shift(@{$self->{option_results}->{xtremio_username}}) : '';
    $self->{xtremio_password} = (defined($self->{option_results}->{xtremio_password})) ? shift(@{$self->{option_results}->{xtremio_password}}) : '';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : 10;
    $self->{proxyurl} = (defined($self->{option_results}->{proxyurl})) ? shift(@{$self->{option_results}->{proxyurl}}) : undef;
 
    if (!defined($self->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{xtremio_username}) || !defined($self->{xtremio_password})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --xtremio-username and --xtremio-password options.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{hostname}) ||
        scalar(@{$self->{option_results}->{hostname}}) == 0) {
        return 0;
    }
    return 1;
}


sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{xtremio_username}.':'.$self->{xtremio_password}.'@'.$self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = 443;
    $self->{option_results}->{proto} = 'https';
    $self->{option_results}->{proxyurl} = $self->{proxyurl};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_items {
    my ($self, %options) = @_;

    $self->settings();

    if (defined($options{obj}) && $options{obj} ne '') {
        $options{url} .= $options{obj} . '/';
    }

    my $response = $self->{http}->request(url_path => $options{url});
    my $decoded;
    eval {
        $decoded = decode_json($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }
   
    my @items;
    foreach my $context (@{$decoded->{$options{obj}}}) {
        push @items,$context->{name};       
    }

    return @items;
}

sub get_details {
    my ($self, %options) = @_;

    $self->settings();
    
    if ((defined($options{obj}) && $options{obj} ne '') && (defined($options{name}) && $options{name} ne '')) {
        $options{url} .= $options{obj} . '/?name=' . $options{name} ;
    } 

    my $response = $self->{http}->request(url_path => $options{url});
    my $decoded;
    eval {
        $decoded = decode_json($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }
     
    return $decoded->{content};

}

1;

__END__

=head1 NAME

XREMIO REST API

=head1 SYNOPSIS

Xtremio Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Xtremio hostname.

=item B<--xtremio-username>

Xtremio username.

=item B<--xtremio-password>

Xtremio password.

=item B<--proxyurl>

Proxy URL if any

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
