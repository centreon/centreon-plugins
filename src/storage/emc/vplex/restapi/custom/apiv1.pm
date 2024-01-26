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

package storage::emc::vplex::restapi::custom::apiv1;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;

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
            'hostname:s'       => { name => 'hostname' },
            'port:s'           => { name => 'port' },
            'proto:s'          => { name => 'proto' },
            'vplex-username:s' => { name => 'vplex_username' },
            'vplex-password:s' => { name => 'vplex_password' },
            'timeout:s'        => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API V1 OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = defined($self->{option_results}->{hostname}) ? $self->{option_results}->{hostname} : '';
    $self->{port} = defined($self->{option_results}->{port}) ? $self->{option_results}->{port} : 443;
    $self->{proto} = defined($self->{option_results}->{proto}) ? $self->{option_results}->{proto} : 'https';
    $self->{vplex_username} = defined($self->{option_results}->{vplex_username}) ? $self->{option_results}->{vplex_username} : '';
    $self->{vplex_password} = defined($self->{option_results}->{vplex_password}) ? $self->{option_results}->{vplex_password} : '';
    $self->{timeout} = defined($self->{option_results}->{timeout}) ? $self->{option_results}->{timeout} : 30;

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }
    if ($self->{vplex_username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --vplex-username option.");
        $self->{output}->option_exit();
    }
    if ($self->{vplex_password} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --vplex-password option.");
        $self->{output}->option_exit();
    }

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Username', value => $self->{vplex_username});
    $self->{http}->add_header(key => 'Password', value => $self->{vplex_password});
    $self->{http}->set_options(%{$self->{option_results}});
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();

    my $content = $self->{http}->request(url_path => $options{endpoint});

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub get_cluster_communication {
    my ($self, %options) = @_;

    my $items = $self->request_api(endpoint => '/vplex/cluster-witness/components/*');

    my $results = [];
    foreach my $context (@{$items->{response}->{context}}) {
        my $entry = {};
        foreach my $attribute (@{$context->{attributes}}) {
            $attribute->{name} =~ s/-/_/g;
            $entry->{ $attribute->{name} } = $attribute->{value};
        }

        push @$results, $entry;
    }

    return $results;
}

sub get_distributed_devices {
    my ($self, %options) = @_;

    my $items = $self->request_api(endpoint => '/vplex/distributed-storage/distributed-devices/*');

    my $results = [];
    foreach my $context (@{$items->{response}->{context}}) {
        my $entry = {};
        foreach my $attribute (@{$context->{attributes}}) {
            $attribute->{name} =~ s/-/_/g;
            $entry->{ $attribute->{name} } = $attribute->{value};
        }

        push @$results, $entry;
    }

    return $results;
}

sub get_storage_volumes {
    my ($self, %options) = @_;

    my $items = $self->request_api(endpoint => '/vplex/clusters/*/storage-elements/storage-volumes/*');

    my $results = [];
    foreach my $context (@{$items->{response}->{context}}) {
        my $entry = {};
        foreach my $attribute (@{$context->{attributes}}) {
            $attribute->{name} =~ s/-/_/g;
            $entry->{ $attribute->{name} } = $attribute->{value};
        }
        my $cluster_name = 'unknown';
        $cluster_name = $1 if ($context->{parent} =~ /^\/clusters\/(.*?)\//);
        $entry->{cluster_name} = $cluster_name;

        push @$results, $entry;
    }

    return $results;
}

sub get_devices {
    my ($self, %options) = @_;

    my $items = $self->request_api(endpoint => '/vplex/clusters/*/devices/*');

    my $results = [];
    foreach my $context (@{$items->{response}->{context}}) {
        my $entry = {};
        foreach my $attribute (@{$context->{attributes}}) {
            $attribute->{name} =~ s/-/_/g;
            $entry->{ $attribute->{name} } = $attribute->{value};
        }
        my $cluster_name = 'unknown';
        $cluster_name = $1 if ($context->{parent} =~ /^\/clusters\/(.*?)\//);
        $entry->{cluster_name} = $cluster_name;

        push @$results, $entry;
    }

    return $results;
}

sub get_fans {
    my ($self, %options) = @_;

    my $items = $self->request_api(endpoint => '/vplex/engines/*/fans/*');

    my $results = [];
    foreach my $context (@{$items->{response}->{context}}) {
        my $entry = {};
        foreach my $attribute (@{$context->{attributes}}) {
            $attribute->{name} =~ s/-/_/g;
            $entry->{ $attribute->{name} } = $attribute->{value};
        }
        my $engine_name = 'unknown';
        $engine_name = $1 if ($context->{parent} =~ /^\/engines\/engine-(.*?)\//);
        $entry->{engine_id} = $engine_name;

        push @$results, $entry;
    }

    return $results;
}

sub get_psus {
    my ($self, %options) = @_;

    my $items = $self->request_api(endpoint => '/vplex/engines/*/power-supplies/*');

    my $results = [];
    foreach my $context (@{$items->{response}->{context}}) {
        my $entry = {};
        foreach my $attribute (@{$context->{attributes}}) {
            $attribute->{name} =~ s/-/_/g;
            $entry->{ $attribute->{name} } = $attribute->{value};
        }
        my $engine_name = 'unknown';
        $engine_name = $1 if ($context->{parent} =~ /^\/engines\/engine-(.*?)\//);
        $entry->{engine_id} = $engine_name;

        push @$results, $entry;
    }

    return $results;
}

sub get_directors {
    my ($self, %options) = @_;

    my $items = $self->request_api(endpoint => '/vplex/engines/*/directors/*');

    my $results = [];
    foreach my $context (@{$items->{response}->{context}}) {
        my $entry = {};
        foreach my $attribute (@{$context->{attributes}}) {
            $attribute->{name} =~ s/-/_/g;
            $entry->{ $attribute->{name} } = $attribute->{value};
        }
        my $engine_name = 'unknown';
        $engine_name = $1 if ($context->{parent} =~ /^\/engines\/engine-(.*?)\//);
        $entry->{engine_id} = $engine_name;

        push @$results, $entry;
    }

    return $results;
}

1;

__END__

=head1 NAME

VPLEX REST API V1

=head1 SYNOPSIS

Vplex rest api v1

=head1 REST API V1 OPTIONS

=over 8

=item B<--hostname>

Hostname.

=item B<--port>

Port used (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--vplex-username>

API Username.

=item B<--vplex-password>

API Password.

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
