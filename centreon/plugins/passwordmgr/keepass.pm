#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package centreon::plugins::passwordmgr::keepass;

use strict;
use warnings;
use JSON::Path;
use Data::Dumper;
use File::KeePass;

use vars qw($keepass_connections);

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
        "keepass-endpoint:s"        => { name => 'keepass_endpoint' },
        "keepass-endpoint-file:s"   => { name => 'keepass_endpoint_file' },
        "keepass-file:s"            => { name => 'keepass_file' },
        "keepass-password:s"        => { name => 'keepass_password' },
        "keepass-search-value:s@"   => { name => 'keepass_search_value' },
        "keepass-map-option:s@"     => { name => 'keepass_map_option' },
    });
    $options{options}->add_help(package => __PACKAGE__, sections => 'KEEPASS OPTIONS');

    $self->{output} = $options{output};    
    $JSON::Path::Safe = 0;
    
    return $self;
}

sub build_api_args {
    my ($self, %options) = @_;
    
    $self->{connection_info} = { file => undef, password => undef };
    if (defined($options{option_results}->{keepass_endpoint_file}) && $options{option_results}->{keepass_endpoint_file} ne '') {
        if (! -f $options{option_results}->{keepass_endpoint_file} or ! -r $options{option_results}->{keepass_endpoint_file}) {
            $self->{output}->add_option_msg(short_msg => "Cannot read keepass endpoint file: $!");
            $self->{output}->option_exit();
        }
        
        require $options{option_results}->{keepass_endpoint_file};
        if (defined($keepass_connections) && defined($options{option_results}->{keepass_endpoint}) && $options{option_results}->{keepass_endpoint} ne '') {
            if (!defined($keepass_connections->{$options{option_results}->{keepass_endpoint}})) {
                $self->{output}->add_option_msg(short_msg => "Endpoint $options{option_results}->{keepass_endpoint} doesn't exist in keepass endpoint file");
                $self->{output}->option_exit();
            }
            
            $self->{connection_info} = $keepass_connections->{$options{option_results}->{keepass_endpoint}};
        }
    }
    
    foreach (['keepass_file', 'file'], ['keepass_password', 'password']) {
        if (defined($options{option_results}->{$_->[0]}) && $options{option_results}->{$_->[0]} ne '') {
            $self->{connection_info}->{$_->[1]} = $options{option_results}->{$_->[0]};
        }
    }
    
    if (defined($self->{connection_info}->{file}) && $self->{connection_info}->{file} ne '') {
        if (!defined($self->{connection_info}->{password}) || $self->{connection_info}->{password} eq '') {
            $self->{output}->add_option_msg(short_msg => "Please set keepass-password option");
            $self->{output}->option_exit();
        }
    }
}

sub do_lookup {
    my ($self, %options) = @_;
    
    $self->{lookup_values} = {};
    return if (!defined($options{option_results}->{keepass_search_value}));
    
    foreach (@{$options{option_results}->{keepass_search_value}}) {
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
    
    return if (!defined($options{option_results}->{keepass_map_option}));
    foreach (@{$options{option_results}->{keepass_map_option}}) {
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
    return if (!defined($self->{connection_info}->{file}));
    
    my $keepassfile;
    eval {
        $keepassfile = File::KeePass->new();
        $keepassfile->load_db($self->{connection_info}->{file}, $self->{connection_info}->{password});
        $keepassfile->unlock;
        $self->{output}->output_add(long_msg => Data::Dumper::Dumper($keepassfile->groups), debug => 1) if ($self->{output}->is_debug());
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot read keepass file: $@");
        $self->{output}->option_exit();
    }
    
    $self->do_lookup(%options, json => $keepassfile->groups);
    $self->do_map(%options);
}

1;

__END__

=head1 NAME

Keepass global

=head1 SYNOPSIS

keepass class

=head1 KEEPASS OPTIONS

=over 8

=item B<--keepass-endpoint>

Connection information to be used in keepass file.

=item B<--keepass-endpoint-file>

File with keepass connection informations.

=item B<--keepass-file>

Keepass file.

=item B<--keepass-password>

Keepass master password.

=item B<--keepass-search-value>

Looking for a value in the JSON keepass. Can use JSON Path and other option values.
Example: 
--keepass-search-value='password=$..entries.[?($_->{title} =~ /serveurx/i)].password'
--keepass-search-value='username=$..entries.[?($_->{title} =~ /serveurx/i)].username'
--keepass-search-value='password=$..entries.[?($_->{title} =~ /%{hostname}/i)].password'

=item B<--keepass-map-option>

Overload plugin option.
Example:
--keepass-map-option="password=%{password}"
--keepass-map-option="username=%{username}"

=back

=head1 DESCRIPTION

B<keepass>.

=cut
