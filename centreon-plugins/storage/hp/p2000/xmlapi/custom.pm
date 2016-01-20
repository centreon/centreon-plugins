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

package storage::hp::p2000::xmlapi::custom;

use strict;
use warnings;
use centreon::plugins::http;
use XML::XPath;
use Digest::MD5 qw(md5_hex);

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
                      "port:s@"          => { name => 'port', },
                      "proto:s@"         => { name => 'proto', },
                      "urlpath:s@"       => { name => 'url_path', },
                      "proxyurl:s@"      => { name => 'proxyurl', },
                      "username:s@"      => { name => 'username', },
                      "password:s@"      => { name => 'password', },
                      "timeout:s@"       => { name => 'timeout', },
                    });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'P2000 OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{mode} = $options{mode};
    
    $self->{session_id} = '';
    $self->{logon} = 0;
    
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
    # return 1 = ok still hostname
    # return 0 = no hostname left

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? shift(@{$self->{option_results}->{hostname}}) : undef;
    $self->{username} = (defined($self->{option_results}->{username})) ? shift(@{$self->{option_results}->{username}}) : undef;
    $self->{password} = (defined($self->{option_results}->{password})) ? shift(@{$self->{option_results}->{password}}) : undef;
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : 45;
    $self->{port} = (defined($self->{option_results}->{port})) ? shift(@{$self->{option_results}->{port}}) : undef;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? shift(@{$self->{option_results}->{proto}}) : 'http';
    $self->{url_path} = (defined($self->{option_results}->{url_path})) ? shift(@{$self->{option_results}->{url_path}}) : '/api/';
    $self->{proxyurl} = (defined($self->{option_results}->{proxyurl})) ? shift(@{$self->{option_results}->{proxyurl}}) : undef;
        
    if (!defined($self->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{username}) || !defined($self->{password})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify username or/and password option.');
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
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{url_path} = $self->{url_path};
    $self->{option_results}->{proxyurl} = $self->{proxyurl};
}

sub check_login {
    my ($self, %options) = @_;
    my ($xpath, $nodeset);
    
    eval {
        $xpath = XML::XPath->new(xml => $options{content});
        $nodeset = $xpath->find("//OBJECT[\@basetype='status']//PROPERTY[\@name='return-code']");
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot parse login response: $@");
        $self->{output}->option_exit();
    }
    
    if (scalar($nodeset->get_nodelist) == 0) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'Cannot find login response.');
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    foreach my $node ($nodeset->get_nodelist()) {
        if ($node->string_value != 1) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'Login authentification failed (return-code: ' . $node->string_value . ').');     
            $self->{output}->display();
            $self->{output}->exit();
        }
    }
    
    $nodeset = $xpath->find("//OBJECT[\@basetype='status']//PROPERTY[\@name='response']");
    my @nodes = $nodeset->get_nodelist();
    my $node = shift(@nodes);
    
    $self->{session_id} = $node->string_value;
    $self->{logon} = 1;
}

sub DESTROY {
    my $self = shift;
    
    if ($self->{logon} == 1) {
        $self->{http}->request(url_path => $self->{url_path} . 'exit',
                               header => ['dataType: api', 'sessionKey: ' . $self->{session_id}]);
    }
}

sub get_infos {
    my ($self, %options) = @_;
    my ($xpath, $nodeset);
    
    my $cmd = $options{cmd};
    $cmd =~ s/ /\//g;
    my $response =$self->{http}->request(url_path => $self->{url_path} . $cmd, 
                                         header => ['dataType: api', 'sessionKey: '. $self->{session_id}]);
    
    eval {
        $xpath = XML::XPath->new(xml => $response);
        $nodeset = $xpath->find("//OBJECT[\@basetype='" . $options{base_type} . "']");
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot parse 'cmd' response: $@");
        $self->{output}->option_exit();
    }
    
    my $results = {};
    foreach my $node ($nodeset->get_nodelist()) {
        my $properties = {};

        foreach my $prop_node ($node->getChildNodes()) {
            my $prop_name = $prop_node->getAttribute('name');
        
            if (defined($prop_name) && ($prop_name eq $options{key} || 
                $prop_name =~ /$options{properties_name}/)) {
                $properties->{$prop_name} = $prop_node->string_value;
            }
        }
        
        if (defined($properties->{$options{key}})) {
            $results->{$properties->{$options{key}}} = $properties;
        }
    }
    
    return $results;
}

##############
# Specific methods
##############
sub login {
    my ($self, %options) = @_;
    
    $self->build_options_for_httplib();
    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    $self->{http}->set_options(%{$self->{option_results}});
    
    # Login First
    my $md5_hash = md5_hex($self->{username} . '_' . $self->{password});
    my $response = $self->{http}->request(url_path => $self->{url_path} . 'login/' . $md5_hash);
    $self->check_login(content => $response);
}

1;

__END__

=head1 NAME

MSA p2000

=head1 SYNOPSIS

my p2000 xml api manage

=head1 P2000 OPTIONS

=over 8

=item B<--hostname>

HP p2000 Hostname.

=item B<--port>

Port used

=item B<--proxyurl>

Proxy URL if any

=item B<--proto>

Specify https if needed

=item B<--urlpath>

Set path to xml api (Default: '/api/')

=item B<--username>

Username to connect.

=item B<--password>

Password to connect.

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut