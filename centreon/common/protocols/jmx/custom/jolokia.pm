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
        $options{options}->add_options(arguments => {
            'url:s@'             => { name => 'url' },
            'timeout:s@'         => { name => 'timeout' },
            'username:s@'        => { name => 'username' },
            'password:s@'        => { name => 'password' },
            'proxy-url:s@'       => { name => 'proxy_url' },
            'proxy-username:s@'  => { name => 'proxy_username' },
            'proxy-password:s@'  => { name => 'proxy_password' },
            'target-url:s@'      => { name => 'target_url' },
            'target-username:s@' => { name => 'target_username' },
            'target-password:s@' => { name => 'target_password' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'JOLOKIA OPTIONS', once => 1);

    $self->{output} = $options{output};

    $self->{jmx4perl} = undef;
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

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
        $self->{connect_params}->{proxy} = { url => $self->{proxy_url} };
        if (defined($self->{proxy_username}) && $self->{proxy_username} ne '') {
            $self->{connect_params}->{proxy}->{'proxy-user'} = $self->{proxy_username};
            $self->{connect_params}->{proxy}->{'proxy-password'} = $self->{proxy_password};
        }
    }
    if (defined($self->{target_url}) && $self->{target_url} ne '') {
        $self->{connect_params}->{target} = { url => $self->{target_url}, user => undef, password => undef };
        if (defined($self->{target_username}) && $self->{target_username} ne '') {
            $self->{connect_params}->{target}->{user} = $self->{target_username};
            $self->{connect_params}->{target}->{password} = $self->{target_password};
        }
    }
    
    if (!defined($self->{url}) ||
        scalar(@{$self->{option_results}->{url}}) == 0) {
        return 0;
    }
    return 1;
}

sub get_connection_info {
    my ($self, %options) = @_;

    my $connection_info = $self->{url};
    $connection_info .= '_' . $self->{proxy_url} if (defined($self->{proxy_url}));
    return $connection_info;
}

sub connect {
    my ($self, %options) = @_;
    
    $self->{jmx4perl} = new JMX::Jmx4Perl($self->{connect_params});
}

sub _add_request {
    my ($self, %options) = @_;
    
    my $request = JMX::Jmx4Perl::Request->new(
        READ, $options{object}, 
        $options{attribute}
    );
    if (!$request->is_mbean_pattern($options{object})) {
        $request->{path} = $options{path};
    }
    
    return $request;
}

sub check_error {
    my ($self, %options) = @_;
    
    # 500-599 an error. 400 is an attribute not present
    my $status = $options{response}->status();
    if ($status >= 500 || 
        $status == 401 ||
        $status == 403 ||
        $status == 408) {
        $self->{output}->add_option_msg(short_msg => "protocol issue: " . $options{response}->error_text());
        $self->{output}->option_exit();
    }
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
                        defined($responses[$pos]) && $j < scalar(@{$options{request}->[$i]->{attributes}}); $j++, $pos++) {
            if ($responses[$pos]->is_error()) {
                $self->check_error(response => $responses[$pos]);
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
            if ($responses[$pos]->is_error()) {
                $self->check_error(response => $responses[$pos]);
            } else {
                my $mbean = $responses[$pos]->{request}->{mbean};
                $response->{$mbean} = {} if (!defined($response->{$mbean}));
                foreach (keys %{$responses[$pos]->{value}}) {
                    $response->{$mbean}->{$_} = $responses[$pos]->{value}->{$_};
                }
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
        my $request = JMX::Jmx4Perl::Request->new(
            READ, $mbean, undef,
            {
                maxDepth => $max_depth,
                maxObjects => $max_objects,
                maxCollectionSize => $max_collection_size,
                ignoreErrors => 1
            }
        );
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
                        my $scal = JMX::Jmx4Perl::Util->dump_scalar($val);
                        if (defined($scal)) {
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

Optional HTTP proxy to use.

=item B<--proxy-username>

Credentials to use for the proxy

=item B<--proxy-password>

Credentials to use for the proxy

=item B<--target-url>

Target to use (if you use jolokia agent as a proxy in --url option).

=item B<--target-username>

Credentials to use for the target

=item B<--target-password>

Credentials to use for the target

=back

=head1 DESCRIPTION

B<custom>.

=cut
