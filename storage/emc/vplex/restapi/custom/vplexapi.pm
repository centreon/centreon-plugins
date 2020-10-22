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

package storage::emc::vplex::restapi::custom::vplexapi;

use strict;
use warnings;
use centreon::plugins::http;
use JSON;

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
            'hostname:s@'       => { name => 'hostname' },
            'vplex-username:s@' => { name => 'vplex_username' },
            'vplex-password:s@' => { name => 'vplex_password' },
            'timeout:s@'        => { name => 'timeout' },
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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? shift(@{$self->{option_results}->{hostname}}) : undef;
    $self->{vplex_username} = (defined($self->{option_results}->{vplex_username})) ? shift(@{$self->{option_results}->{vplex_username}}) : '';
    $self->{vplex_password} = (defined($self->{option_results}->{vplex_password})) ? shift(@{$self->{option_results}->{vplex_password}}) : '';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : 30;
 
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
        if (defined($options{parent_filter}) && $options{parent_filter} ne '') {
            if ($options{parent_filter} =~ /^[0-9\-]+$/) {
                $options{url} .= $options{parent_filter_prefix} . $options{parent_filter} . '/';
            } else {
                $options{url} .= $options{parent_filter} . '/';
            }
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
            $context->{parent} =~ /$options{parent_select}/;
            $engine_name = $1;
            $items->{$engine_name} = {} if (!defined($items->{$engine_name}));
        }

        my $attributes = {};
        foreach my $attribute (@{$context->{attributes}}) {
            $attributes->{ $attribute->{name} } = $attribute->{value};
        }
        
        if (defined($engine_name)) {
            $items->{$engine_name}->{ $attributes->{name} } = $attributes;
        } else {
            $items->{ $attributes->{name} } = $attributes;
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

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
