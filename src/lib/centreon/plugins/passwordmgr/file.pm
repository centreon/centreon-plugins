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

package centreon::plugins::passwordmgr::file;

use strict;
use warnings;
use centreon::plugins::misc;
use JSON::Path;
use JSON::XS;
use Data::Dumper;

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
        'secret-file:s'          => { name => 'secret_file' },
        'secret-search-value:s@' => { name => 'secret_search_value' },
        'secret-map-option:s@'   => { name => 'secret_map_option' }
    });
    $options{options}->add_help(package => __PACKAGE__, sections => 'SECRET FILE OPTIONS');

    $self->{output} = $options{output};    
    $JSON::Path::Safe = 0;

    return $self;
}

sub load {
    my ($self, %options) = @_;

    if (defined($options{option_results}->{secret_file}) && $options{option_results}->{secret_file} ne '') {
        if (! -f $options{option_results}->{secret_file} or ! -r $options{option_results}->{secret_file}) {
            $self->{output}->add_option_msg(short_msg => "Cannot read secret file '$options{option_results}->{secret_file}': $!");
            $self->{output}->option_exit();
        }

        my $content = centreon::plugins::misc::slurp_file(output => $self->{output}, file => $options{option_results}->{secret_file});

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode secret file");
            $self->{output}->option_exit();
        }

        return $decoded;
    }
}

sub do_lookup {
    my ($self, %options) = @_;
    
    $self->{lookup_values} = {};
    return if (!defined($options{option_results}->{secret_search_value}));
    
    foreach (@{$options{option_results}->{secret_search_value}}) {
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
    
    return if (!defined($options{option_results}->{secret_map_option}));
    foreach (@{$options{option_results}->{secret_map_option}}) {
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
    
    my $secrets = $self->load(%options);
    return if (!defined($secrets));

    $self->do_lookup(%options, json => $secrets);
    $self->do_map(%options);
}

1;


=head1 NAME

Secret file global

=head1 SYNOPSIS

secret file class

=head1 SECRET FILE OPTIONS

=over 8

=item B<--secret-file>

Secret file.

=item B<--secret-search-value>

Looking for a value in the JSON. Can use JSON Path and other option values.
Example: 
--secret-search-value='password=$..entries.[?($_->{title} =~ /server/i)].password'
--secret-search-value='username=$..entries.[?($_->{title} =~ /server/i)].username'
--secret-search-value='password=$..entries.[?($_->{title} =~ /%{hostname}/i)].password'

=item B<--secret-map-option>

Overload plugin option.
Example:
--secret-map-option="password=%{password}"
--secret-map-option="username=%{username}"

=back

=head1 DESCRIPTION

B<secret file>.

=cut
