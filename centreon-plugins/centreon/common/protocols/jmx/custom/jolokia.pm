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

package centreon::common::protocols::jmx::custom::jolokia;

use strict;
use warnings;
use JMX::Jmx4Perl;
use JMX::Jmx4Perl::Alias;
use JMX::Jmx4Perl::Request;
use JMX::Jmx4Perl::Util;

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
                      "url:s@"              => { name => 'url' },
                      "timeout:s@"          => { name => 'timeout' },
                      "username:s@"         => { name => 'username' },
                      "password:s@"         => { name => 'password' },
                      "proxy-url:s@"        => { name => 'proxy_url' },
                      "proxy-username:s@"   => { name => 'proxy_username' },
                      "proxy-password:s@"   => { name => 'proxy_password' },
                      "target-url:s@"       => { name => 'target_url' },
                      "target-username:s@"  => { name => 'target_username' },
                      "target-password:s@"  => { name => 'target_password' },
                    });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'JOLOKIA OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{mode} = $options{mode};

    $self->{jmx4perl} = undef;
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
    # return 1 = ok still url
    # return 0 = no url left

    foreach (('url', 'timeout', 'username', 'password', 'proxy_url', 'proxy_username', 
              'proxy_password', 'target_url', 'target_username', 'target_password')) {
        $self->{$_} = (defined($self->{option_results}->{$_})) ? shift(@{$self->{option_results}->{$_}}) : undef;
    }    
    
    $self->{connect_params} = {};
    if (!defined($self->{url}) || $self->{url} eq '') {
        $self->{output}->add_option_msg(short_msg => "Please set option --url.");
        $self->{output}->option_exit();
    }
    if (defined($self->{timeout}) && $self->{timeout} =~ /^\d+$/ &&
        $self->{timeout} > 0) {
        $self->{timeout} = $self->{timeout};
    } else {
        $self->{timeout} = 30;
    }
    
    $self->{connect_params}->{url} = $self->{url};
    $self->{connect_params}->{timeout} = $self->{timeout};
    if (defined($self->{username}) && $self->{username} ne '') {
        $self->{connect_params}->{user} = $self->{username};
        $self->{connect_params}->{password} = $self->{password};
    }
    if (defined($self->{proxy_url}) && $self->{proxy_url} ne '') {
        $self->{connect_params}->{username}->{proxy} = { http => undef, https => undef };
        if ($self->{proxy_url} =~ /^(.*?):/) {
            $self->{connect_params}->{username}->{proxy}->{$1} = $self->{proxy_url};
            if (defined($self->{proxy_username}) && $self->{proxy_username} ne '') {
                $self->{connect_params}->{proxy_user} = $self->{proxy_username};
                $self->{connect_params}->{proxy_password} = $self->{proxy_password};
            }
        }
    }
    if (defined($self->{target_url}) && $self->{target_url} ne '') {
        $self->{connect_params}->{username}->{target} = { url => $self->{target_url}, user => undef, password => undef };
        if (defined($self->{target_username}) && $self->{target_username} ne '') {
            $self->{connect_params}->{username}->{target}->{user} = $self->{target_username};
            $self->{connect_params}->{username}->{target}->{password} = $self->{target_password};
        }
    }
    
    if (!defined($self->{url}) ||
        scalar(@{$self->{option_results}->{url}}) == 0) {
        return 0;
    }
    return 1;
}

sub connect {
    my ($self, %options) = @_;
    
    $self->{jmx4perl} = new JMX::Jmx4Perl($self->{connect_params});
}

sub _add_request {
    my ($self, %options) = @_;
    
    my $request = JMX::Jmx4Perl::Request->new(READ, $options{object}, 
                                              $options{attribute}
                                              );
    if (!$request->is_mbean_pattern($options{object})) {
        $request->{path} = $options{path};
    }
    
    return $request;
}

sub get_attributes {
    my ($self, %options) = @_;
    my $nothing_quit = defined($options{nothing_quit}) && $options{nothing_quit} == 1 ? 1 : 0;
    #$options{request} = [
    #     { mbean => 'java.lang:name=*,type=MemoryPool', attributes => [ { name => 'CollectionUsage', path => 'committed' }, { name => 'Name', path => undef },
    #     { name => 'NonHeapMemoryUsagePlop', path => undef } ] },
    #     { mbean => 'java.lang:type=Memory', attributes => [ { name => 'NonHeapMemoryUsage' } ] },
    #     { mbean => 'java.lang:type=Memory', attributes => [ { name => 'HeapMemoryUsage', path => 'committed' } ] },
    #     { mbean => 'java.lang:type=Memory', attributes => [] },
    #];
    
    if (!defined($self->{jmx4perl})) {
        $self->connect();
    }

    my @requests = ();
    for (my $i = 0; defined($options{request}) && $i < scalar(@{$options{request}}); $i++) {
        my $object = $options{request}->[$i]->{mbean};
        for (my $j = 0; defined($options{request}->[$i]->{attributes}) && 
                          $j < scalar(@{$options{request}->[$i]->{attributes}}) ; $j++) {            
            push @requests, $self->_add_request(object => $object, attribute => $options{request}->[$i]->{attributes}->[$j]->{name},
                                                path => $options{request}->[$i]->{attributes}->[$j]->{path});
        }
        if (!defined($options{request}->[$i]->{attributes}) || scalar(@{$options{request}->[$i]->{attributes}}) == 0) {
            push @requests, $self->_add_request(object => $object, path => $options{request}->[$i]->{path});
        }
    }

    my $response = {};
    my @responses = $self->{jmx4perl}->request(@requests);
    for (my $i = 0, my $pos = 0; defined($options{request}) && $i < scalar(@{$options{request}}); $i++) {
        for (my $j = 0; defined($options{request}->[$i]->{attributes}) && 
                          $j < scalar(@{$options{request}->[$i]->{attributes}}); $j++, $pos++) {
            if ($responses[$pos]->is_error()) {
                # 500-599 an error. 400 is an attribute not present
                if ($responses[$pos]->status() >= 500 || $responses[$pos]->status() == 401) {
                    $self->{output}->add_option_msg(short_msg => "protocol issue: " . $responses[$pos]->error_text());
                    $self->{output}->option_exit();
                }
                next;
            }
            
            my $mbean = $responses[$pos]->{request}->{mbean};
            my $attribute = $responses[$pos]->{request}->{attribute};
            my $value = $responses[$pos]->{value};
            if ($requests[$pos]->is_mbean_pattern()) {
                foreach (keys %{$responses[$pos]->{value}}) {
                    $response->{$_} = {} if (!defined($response->{$_}));
                    $response->{$_}->{$attribute} = $responses[$pos]->{value}->{$_}->{$attribute};
                }
            } else {
                $response->{$mbean} = {} if (!defined($response->{$mbean}));
                $response->{$mbean}->{$attribute} = $value;
            }
        }

        if (!defined($options{request}->[$i]->{attributes}) || scalar(@{$options{request}->[$i]->{attributes}}) == 0) {
            my $mbean = $responses[$pos]->{request}->{mbean};
            $response->{$mbean} = {} if (!defined($response->{$mbean}));
            foreach (keys %{$responses[$pos]->{value}}) {
                $response->{$mbean}->{$_} = $responses[$pos]->{value}->{$_};
            }
            $pos++;
        }
    }

    if ($nothing_quit == 1 && scalar(keys %{$response}) == 0) {
        $self->{output}->add_option_msg(short_msg => "JMX Request: Cant get a single value.");
        $self->{output}->option_exit();
    }
    return $response;
}

sub list_attributes {
    my ($self, %options) = @_;
    my $max_depth = defined($options{max_depth}) ? $options{max_depth} : 5;
    my $max_objects = defined($options{max_objects}) ? $options{max_objects} : 100;
    my $max_collection_size = defined($options{max_collection_size}) ? $options{max_collection_size} : 50;
    my $pattern = defined($options{mbean_pattern}) ? $options{mbean_pattern} : '*:*';
    my $color = 1;
    
    eval {
        local $SIG{__DIE__} = 'IGNORE';
        require Term::ANSIColor;
    };
    if ($@) {
        $color = 0;
    }
    
    if (!defined($self->{jmx4perl})) {
        $self->connect();
    }
    
    my $mbeans = $self->{jmx4perl}->search($pattern);
    print "List attributes:\n";
    for my $mbean (@$mbeans) {
        my $request = JMX::Jmx4Perl::Request->new(READ, $mbean, undef, {maxDepth => $max_depth,
                                                                        maxObjects => $max_objects,
                                                                        maxCollectionSize => $max_collection_size,
                                                                        ignoreErrors => 1});
        my $response = $self->{jmx4perl}->request($request);
        if ($response->is_error) {
            print "ERROR: " . $response->error_text . "\n";
            print JMX::Jmx4Perl::Util->dump_value($response, { format => 'DATA' });
        } else {
            my $values = $response->value;
            if (keys %$values) {
                for my $a (keys %$values) {
                    print Term::ANSIColor::color('red on_yellow') if ($color == 1);
                    print "$mbean -- $a";
                    print Term::ANSIColor::color('reset') if ($color == 1);
                    my $val = $values->{$a};
                    if (JMX::Jmx4Perl::Util->is_object_to_dump($val)) {
                        my $v = JMX::Jmx4Perl::Util->dump_value($val, { format => 'DATA' });
                        $v =~ s/^\s*//;
                        print " = " . $v;
                    } else {
                        if (my $scal = JMX::Jmx4Perl::Util->dump_scalar($val)) {
                            print " = " . $scal . "\n";
                        } else {
                            print " = undef\n";
                        }
                    }
                }
            }
        }
    }
}

1;

__END__

=head1 NAME

JOlokia connector library

=head1 SYNOPSIS

my jolokia connector

=head1 JOLOKIA OPTIONS

=over 8

=item B<--url>

Url where the jolokia agent is deployed (required).
Example: http://localhost:8080/jolokia

=item B<--timeout>  

Timeout in seconds for HTTP requests (Defaults: 30 seconds)

=item B<--username>

Credentials to use for the HTTP request

=item B<--password>

Credentials to use for the HTTP request

=item B<--proxy-url>

Optional proxy to use.

=item B<--proxy-username>

Credentials to use for the proxy

=item B<--proxy-password>

Credentials to use for the proxy

=item B<--target-url>

Target to use (if you use jolokia agent as a proxy)

=item B<--target-username>

Credentials to use for the target

=item B<--target-password>

Credentials to use for the target

=back

=head1 DESCRIPTION

B<custom>.

=cut