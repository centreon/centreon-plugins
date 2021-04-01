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

package centreon::plugins::passwordmgr::teampass;

use strict;
use warnings;
use JSON::Path;
use JSON::XS;
use Data::Dumper;
use centreon::plugins::http;

use vars qw($teampass_connections);

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class PasswordMgr: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class PasswordMgr: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    $options{options}->add_options(arguments => {
        "teampass-endpoint:s"       => { name => 'teampass_endpoint' },
        "teampass-endpoint-file:s"  => { name => 'teampass_endpoint_file' },
        "teampass-api-key:s"        => { name => 'teampass_api_key' },
        "teampass-api-address:s"    => { name => 'teampass_api_address' },
        "teampass-api-request:s"    => { name => 'teampass_api_request' },
        "teampass-search-value:s@"  => { name => 'teampass_search_value' },
        "teampass-map-option:s@"    => { name => 'teampass_map_option' },
        "teampass-timeout:s"        => { name => 'teampass_timeout' },
    });
    $options{options}->add_help(package => __PACKAGE__, sections => 'TEAMPASS OPTIONS');

    $self->{output} = $options{output};    
    $self->{http} = centreon::plugins::http->new(%options, noptions => 1);
    $JSON::Path::Safe = 0;
    
    return $self;
}

sub build_api_args {
    my ($self, %options) = @_;
    
    $self->{connection_info} = { address => undef, key => undef, request => undef };
    if (defined($options{option_results}->{teampass_endpoint_file}) && $options{option_results}->{teampass_endpoint_file} ne '') {
        if (! -f $options{option_results}->{teampass_endpoint_file} or ! -r $options{option_results}->{teampass_endpoint_file}) {
            $self->{output}->add_option_msg(short_msg => "Cannot read teampass file: $!");
            $self->{output}->option_exit();
        }
        
        require $options{option_results}->{teampass_endpoint_file};
        if (defined($teampass_connections) && defined($options{option_results}->{teampass_endpoint}) && $options{option_results}->{teampass_endpoint} ne '') {
            if (!defined($teampass_connections->{$options{option_results}->{teampass_endpoint}})) {
                $self->{output}->add_option_msg(short_msg => "Endpoint $options{option_results}->{teampass_endpoint} doesn't exist in teampass file");
                $self->{output}->option_exit();
            }
            
            $self->{connection_info} = $teampass_connections->{$options{option_results}->{teampass_endpoint}};
        }
    }
    
    foreach (['teampass_api_address', 'address'], ['teampass_api_key', 'key'], ['teampass_api_request', 'request']) {
        if (defined($options{option_results}->{$_->[0]}) && $options{option_results}->{$_->[0]} ne '') {
            $self->{connection_info}->{$_->[1]} = $options{option_results}->{$_->[0]};
        }
    }
    
    if (defined($self->{connection_info}->{address}) && $self->{connection_info}->{address} ne '') {
        foreach ('key', 'request') {
            if (!defined($self->{connection_info}->{$_}) || $self->{connection_info}->{$_} eq '') {
                $self->{output}->add_option_msg(short_msg => "Please set teampass-api-$_ option");
                $self->{output}->option_exit();
            }
        }
    }
}

sub do_lookup {
    my ($self, %options) = @_;
    
    $self->{lookup_values} = {};
    return if (!defined($options{option_results}->{teampass_search_value}));
    
    foreach (@{$options{option_results}->{teampass_search_value}}) {
        next if (! /^(.+?)=(.+)$/);
        my ($map, $lookup) = ($1, $2);
                
        # Change %{xxx} options usage
        while ($lookup =~ /\%\{(.*?)\}/g) {
            my $sub = '';
            $sub = $options{option_results}->{$1} if (defined($options{option_results}->{$1}));
            $lookup =~ s/\%\{$1\}/$sub/g
        }
        
        my $jpath = JSON::Path->new($lookup);
        my $result = $jpath->value($options{json});
        $self->{output}->output_add(long_msg => 'lookup = ' . $lookup. ' - response = ' . Data::Dumper::Dumper($result), debug => 1);
        $self->{lookup_values}->{$map} = $result;
    }
}

sub do_map {
    my ($self, %options) = @_;
    
    return if (!defined($options{option_results}->{teampass_map_option}));
    foreach (@{$options{option_results}->{teampass_map_option}}) {
        next if (! /^(.+?)=(.+)$/);
        my ($option, $map) = ($1, $2);
        
        # Change %{xxx} options usage
        while ($map =~ /\%\{(.*?)\}/g) {
            my $sub = '';
            $sub = $self->{lookup_values}->{$1} if (defined($self->{lookup_values}->{$1}));
            $map =~ s/\%\{$1\}/$sub/g
        }

        $option =~ s/-/_/g;
        $options{option_results}->{$option} = $map;
    }
}

sub manage_options {
    my ($self, %options) = @_;
    
    $self->build_api_args(%options);
    return if (!defined($self->{connection_info}->{address}));
    
    $self->{http}->set_options(
        timeout => $options{option_results}->{teampass_timeout},
        unknown_status => '%{http_code} < 200 or %{http_code} >= 300',
    );
    my $response = $self->{http}->request(method => 'GET', 
        full_url => $self->{connection_info}->{address} . $self->{connection_info}->{request}, 
        hostname => '',
        get_param => ['apikey=' . $self->{connection_info}->{key}],
    );
    $self->{output}->output_add(long_msg => $response, debug => 1);
    
    my $json;
    eval {
        $json = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode teampass json response: $@");
        $self->{output}->option_exit();
    }
    
    $self->do_lookup(%options, json => $json);
    $self->do_map(%options);
}

1;

__END__

=head1 NAME

Teampass global

=head1 SYNOPSIS

teampass class

=head1 TEAMPASS OPTIONS

=over 8

=item B<--teampass-endpoint>

Connection information to be used in teampass file.

=item B<--teampass-endpoint-file>

File with teampass connection informations.

=item B<--teampass-timeout>

Set HTTP Rest API timeout (Default: 5).

=item B<--teampass-api-key>

Teampass API Key.

=item B<--teampass-api-address>

Teampass URL (example: http://10.0.0.1/teampass).

=item B<--teampass-api-request>

Teampass request (example: /api/index.php/folder/3).

=item B<--teampass-search-value>

Looking for a value in the JSON teampass response. Can use JSON Path and other option values.
Example: 
--teampass-search-value='password=$.[?($_->{label} =~ /serveur1/i)].pw'
--teampass-search-value='login=$.[?($_->{label} =~ /serveur1/i)].login'
--teampass-search-value='password=$.[?($_->{label} =~ /%{hostname}/i)].pw'

=item B<--teampass-map-option>

Overload plugin option.
Example:
--teampass-map-option="password=%{password}"
--teampass-map-option="username=%{login}"

=back

=head1 DESCRIPTION

B<teampass>.

=cut
