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
                      "hostname:s@"      => { name => 'hostname', },
                      "proxyurl:s@"      => { name => 'proxyurl', },
                      "timeout:s@"       => { name => 'timeout', },
                      "header:s@"        => { name => 'header', },
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
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : 10;
    $self->{port} = (defined($self->{option_results}->{port})) ? shift(@{$self->{option_results}->{port}}) : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? shift(@{$self->{option_results}->{proto}}) : 'https';
    $self->{proxyurl} = (defined($self->{option_results}->{proxyurl})) ? shift(@{$self->{option_results}->{proxyurl}}) : undef;
 
    if (!defined($self->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
        $self->{output}->option_exit();
    }

    if (defined($self->{option_results}->{header})) {
        $self->{headers} = {};
        foreach (@{$self->{option_results}->{header}}) {
            if (/^(.*?):(.*)/) {
                $self->{headers}->{$1} = $2;
            }
       }
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
    $self->{option_results}->{url_path} = $self->{url_path};
   
}

sub connect {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->set_options(%{$self->{option_results}});

}

sub get_items {
    my ($self, %options) = @_;

    my $url = $options{url};
    my $obj = $options{obj};
    my $engine = $options{engine};

    my @items;
    if ($engine) {
        $url .= $engine.'/'.$obj.'/';
    } elsif (defined $obj) {
        $url .= '/'.$obj;
    };

    my $response = $self->{http}->request(url_path => $url);
    my $decoded = decode_json($response);

    foreach my $child (@{ $decoded->{response}->{context}->[0]->{children} } ) {
        push @items, $child->{name};
    }

    return @items;
}

sub get_param {
    my ($self, %options) = @_;

    my $url = $options{url};
    my $obj = $options{obj};
    my $engine = $options{engine};
    my $item = $options{item};
    my $param = $options{param};

    if ( (defined $engine) && (defined $obj) ) {
        $url .= $engine.'/'.$obj.'/'.$item.'?'.$param;
    } elsif (defined $engine) {
        $url .= $engine.'/'.$item.'?'.$param;
    } else {
        $url .= '/'.$item.'?'.$param;
    }

    my $response = $self->{http}->request(url_path => $url);
    my $decoded = decode_json($response);

    return $decoded->{response};
    
}

sub get_infos {
    my ($self, %options) = @_;
    
    my $url = $options{url};
    my $obj = $options{obj};
    my $engine = $options{engine};
    my $item = $options{item};
    
    if (defined $engine) {
        $url .= $engine.'/'.$obj.'/'.$item;
    } elsif (defined $obj) {
        $url .= '/'.$obj;
    } else {
        $url .= '/'.$item;
    }

    my $response = $self->{http}->request(url_path => $url);
    my $decoded = decode_json($response);

    return $decoded->{response};

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

Vplex Hostname.

=item B<--proxyurl>

Proxy URL if any

=item B<--timeout>

Set HTTP timeout

=item B<--header>

Set HTTPS Headers (specify multiple time e.g )

=back

=head1 DESCRIPTION

B<custom>.

=cut
