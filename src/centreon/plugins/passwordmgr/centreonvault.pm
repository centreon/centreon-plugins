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

package centreon::plugins::passwordmgr::centreonvault;

use strict;
use warnings;
use Data::Dumper;
use centreon::plugins::http;
use JSON::XS;

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
        'vault-config:s'   => { name => 'vault_config', default => '/etc/centreon-engine/centreonvault.json'},
    });
    $options{options}->add_help(package => __PACKAGE__, sections => 'VAULT OPTIONS');

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, noptions => 1, default_backend => 'curl');

    return $self;
}

sub extract_map_options {
    my ($self, %options) = @_;

    $self->{map_option} = [];

    # Parse all options to find '/\{.*\:\:secret\:\:(.*)\}/' dedicated patern in value and add entries in map_option
    foreach my $option (keys %{$options{option_results}}) {
        if (defined($options{option_results}{$option})) {
            next if ($option eq 'map_option');
            if (ref($options{option_results}{$option}) eq 'ARRAY') {
                foreach (@{$options{option_results}{$option}}) {
                    if ($_ =~ /\{.*\:\:secret\:\:(.*)\:\:(.*)\}/i) {
                        push (@{$self->{request_endpoint}}, "$1::/v1/".$2);
                        push (@{$self->{map_option}}, $option."=%".$_);
                    }
                }
            } else {
                if ($options{option_results}{$option} =~ /\{.*\:\:secret\:\:(.*)\:\:(.*)\}/i) {
                    push (@{$self->{request_endpoint}}, "$1::/v1/".$2);
                    push (@{$self->{map_option}}, $option."=%".$options{option_results}{$option});
                }
            }
        }
    }
}

sub vault_settings {
    my ($self, %options) = @_;

    if (!defined($options{option_results}->{vault_config})
        || $options{option_results}->{vault_config} eq '') {
        $self->{output}->add_option_msg(short_msg => "Please set --vault-config option");
        $self->{output}->option_exit();
    }
    if (! -f $options{option_results}->{vault_config}) {
        $self->{output}->add_option_msg(short_msg => "Cannot find file '$options{option_results}->{vault_config}'");
        $self->{output}->option_exit();
    }
    
    my $file_content = do {
        local $/ = undef;
        if (!open my $fh, "<", $options{option_results}->{vault_config}) {
            $self->{output}->add_option_msg(short_msg => "Could not open file $options{option_results}->{vault_config}: $!");
            $self->{output}->option_exit();
        }
        <$fh>;
    };

    my $json;
    eval {
        $json = JSON::XS->new->utf8->decode($file_content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json file");
        $self->{output}->option_exit();
    }

    foreach my $vault_name (keys %$json) {
        $self->{$vault_name}->{vault_protocol} = 'https';
        $self->{$vault_name}->{vault_address} = '127.0.0.1';
        $self->{$vault_name}->{vault_port} = '8100';

        $self->{$vault_name}->{vault_protocol} = $json->{$vault_name}->{'vault-protocol'}
            if ($json->{$vault_name}->{'vault-protocol'} && $json->{$vault_name}->{'vault-protocol'} ne '');
        $self->{$vault_name}->{vault_address} = $json->{$vault_name}->{'vault-address'}
            if ($json->{$vault_name}->{'vault-address'} && $json->{$vault_name}->{'vault-address'} ne '');
        $self->{$vault_name}->{vault_port} = $json->{$vault_name}->{'vault-port'}
            if ($json->{$vault_name}->{'vault-port'} && $json->{$vault_name}->{'vault-port'} ne '');
        $self->{$vault_name}->{vault_token} = $json->{$vault_name}->{'vault-token'}
            if ($json->{$vault_name}->{'vault-token'} && $json->{$vault_name}->{'vault-token'} ne '');
    }
}

sub request_api {
    my ($self, %options) = @_;

    $self->vault_settings(%options);

    $self->{lookup_values} = {};
    foreach my $item (@{$self->{request_endpoint}}) {
        # Extract vault name configuration from endpoint
        # 'vault::/v1/<root_path>/monitoring/hosts/7ad55afc-fa9e-4851-85b7-e26f47e421d7'
        my ($vault_name, $endpoint);
        if ($item =~ /(.*)\:\:(.*)/i) {
            $vault_name = $1;
            $endpoint = $2;
        }

        if (!defined($self->{$vault_name})) {
            $self->{output}->add_option_msg(short_msg => "Cannot get vault access for: $vault_name");
            $self->{output}->option_exit();
        }

        my $headers = ['Accept: application/json'];
        if (defined($self->{$vault_name}->{vault_token})) {
            push @$headers, 'X-Vault-Token: ' . $self->{$vault_name}->{vault_token};
        }

        my ($response) = $self->{http}->request(
            hostname => $self->{$vault_name}->{vault_address},
            port => $self->{$vault_name}->{vault_port},
            proto => $self->{$vault_name}->{vault_protocol},
            method => 'GET',
            url_path => $endpoint,
            header => $headers
        );
        
        my $json;
        eval {
            $json = JSON::XS->new->utf8->decode($response);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode Vault JSON response: $@");
            $self->{output}->option_exit();
        };

        foreach (keys %{$json->{data}}) {
            $self->{lookup_values}->{'{' . $_ . '::secret::' . $vault_name . '::' . substr($endpoint, index($endpoint, '/', 1) + 1) . '}'} = $json->{data}->{$_};
        }
    }
}

sub do_map {
    my ($self, %options) = @_;

    foreach (@{$self->{map_option}}) {
        next if (! /^(.+?)=%(.+)$/);

        my ($option, $map) = ($1, $2);

        $map = $self->{lookup_values}->{$2} if (defined($self->{lookup_values}->{$2}));
        $option =~ s/-/_/g;
        $options{option_results}->{$option} = $map;
    }

}

sub manage_options {
    my ($self, %options) = @_;

    $self->extract_map_options(%options);

    return if (scalar(@{$self->{map_option}}) <= 0);

    $self->request_api(%options);
    $self->do_map(%options);
}

1;

__END__

=head1 NAME

Centreon Vault password manager

=head1 SYNOPSIS

Centreon Vault password manager

To be used with an array containing keys/values saved in a secret path by resource

=head1 VAULT OPTIONS

=over 8

=item B<--vault-config>

The path to the file defining access to the Centreon vault (/etc/centreon-engine/centreonvault.json by default)

=back

=head1 DESCRIPTION

B<centreonvault>.

=cut
