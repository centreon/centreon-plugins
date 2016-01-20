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

package storage::emc::vplex::restapi::custom::vplexapi;

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
                      "hostname:s@"         => { name => 'hostname', },
                      "vplex-username:s@"   => { name => 'vplex_username', },
                      "vplex-password:s@"   => { name => 'vplex_password', },
                      "proxyurl:s@"         => { name => 'proxyurl', },
                      "timeout:s@"          => { name => 'timeout', },
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
    $self->{vplex_username} = (defined($self->{option_results}->{vplex_username})) ? shift(@{$self->{option_results}->{vplex_username}}) : '';
    $self->{vplex_password} = (defined($self->{option_results}->{vplex_password})) ? shift(@{$self->{option_results}->{vplex_password}}) : '';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : 10;
    $self->{proxyurl} = (defined($self->{option_results}->{proxyurl})) ? shift(@{$self->{option_results}->{proxyurl}}) : undef;
 
    if (!defined($self->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
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

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = 443;
    $self->{option_results}->{proto} = 'https';
    $self->{option_results}->{proxyurl} = $self->{proxyurl};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Username', value => $self->{vplex_username});
    $self->{http}->add_header(key => 'Password', value => $self->{vplex_password});
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_items {
    my ($self, %options) = @_;

    $self->settings();

    if (defined($options{parent})) {
        if (defined($options{$options{parent}}) && $options{$options{parent}} ne '') {
            $options{url} .= $options{parent} . '-' . $options{engine} . '/';
        } else {
            $options{url} .= '*' . '/';
        }
    }
    if (defined($options{obj}) && $options{obj} ne '') {
        $options{url} .= $options{obj} . '/';
    }
    $options{url} .= '*';
    
    my $response = $self->{http}->request(url_path => $options{url});
    my $decoded;
    eval {
        $decoded = decode_json($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }
        
    my $items = {};
    foreach my $context (@{$decoded->{response}->{context}}) {
        my $engine_name;
        
        if (defined($options{parent})) {
            $context->{parent} =~ /\/$options{parent}-(.*?)\//;
            $engine_name = $options{parent} . '-' . $1;
            $items->{$engine_name} = {} if (!defined($items->{$engine_name}));
        }
        
        my $attributes = {};
        foreach my $attribute (@{$context->{attributes}}) {
            $attributes->{$attribute->{name}} = $attribute->{value};
        }
        
        if (defined($engine_name)) {
            $items->{$engine_name}->{$attributes->{name}} = $attributes;
        } else {
            $items->{$attributes->{name}} = $attributes;
        }
    }

    return $items;
}

1;

__END__

=head1 NAME

VPLEX REST API

=head1 SYNOPSIS

Vplex Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Vplex hostname.

=item B<--vplex-username>

Vplex username.

=item B<--vplex-password>

Vplex password.

=item B<--proxyurl>

Proxy URL if any

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
