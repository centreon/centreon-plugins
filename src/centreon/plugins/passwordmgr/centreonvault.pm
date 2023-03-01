#
# Copyright 2023 Centreon (http://www.centreon.com/)
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
        'auth-method:s'    => { name => 'auth_method', default => 'token' },
        'auth-settings:s%' => { name => 'auth_settings' },
        #'map-option:s@'    => { name => 'map_option' },
        'vault-config:s'   => { name => 'vault_config', default => '/etc/centreon-engine/centreonvault.json'},
        #'vault-address:$@'  => { name => 'vault_address'},
        #'vault-port:s@'     => { name => 'vault_port'},
        #'vault-protocol:s@' => { name => 'vault_protocol'},
        #'vault-token:s@'    => { name => 'vault_token'}
    });
    $options{options}->add_help(package => __PACKAGE__, sections => 'VAULT OPTIONS');

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, noptions => 1, default_backend => 'curl');

    return $self;
}

sub extract_map_options {
    my ($self, %options) = @_;

    foreach my $option (keys %{$options{option_results}}) {
        if (defined($options{option_results}{$option})) {
            next if ($option eq 'map_option');
            if (ref $options{option_results}{$option} eq 'ARRAY') {
                foreach (@{$options{option_results}{$option}}) {
                    if ($_ =~ /\{.*\:\:secret\:\:(.*)\}/i) {
                        push (@{$self->{request_endpoint}}, "/v1".$1);
                        push (@{$options{option_results}->{map_option}}, $option."=%".$_);
                    }
                }
            } else {
                if ($options{option_results}{$option} =~ /\{.*\:\:secret\:\:(.*)\}/i) {
                    push (@{$self->{request_endpoint}}, "/v1".$1);
                    push (@{$options{option_results}->{map_option}}, $option."=%".$options{option_results}{$option});
                }
            }
        }
    }
}

sub vault_settings {
    my ($self, %options) = @_;

    if (defined($options{option_results}->{vault_config})
        && $options{option_results}->{vault_config} ne ''
        && -f $options{option_results}->{vault_config}
    ) {
        my $file_content;
        open(FH, '<', $options{option_results}->{vault_config}) or die $!;
        $file_content = do { local ($/); <FH> };
        close(FH);

        my $json = JSON::XS->new->utf8->pretty->decode($file_content);
        foreach my $vault_name (keys %{$json}) {
            if ($json->{$vault_name}->{'vault-protocol'} && $json->{$vault_name}->{'vault-protocol'} ne '') {
                $self->{vault_protocol} = $json->{$vault_name}->{'vault-protocol'};
            } else {
                $self->{vault_protocol} = 'http';
            }
            if ($json->{$vault_name}->{'vault-address'} && $json->{$vault_name}->{'vault-address'} ne '') {
                $self->{vault_address} = $json->{$vault_name}->{'vault-address'};
            }
            if ($json->{$vault_name}->{'vault-port'} && $json->{$vault_name}->{'vault-port'} ne '') {
                $self->{vault_port} = $json->{$vault_name}->{'vault-port'};
            } else {
                $self->{vault_port} = '8200';
            }
            if ($json->{$vault_name}->{'vault-token'} && $json->{$vault_name}->{'vault-token'} ne '') {
                $self->{vault_token} = $json->{$vault_name}->{'vault-token'};
            }
        }

        $self->{http}->add_header(key => 'Accept', value => 'application/json');
        if (defined($self->{vault_token})) {
            $self->{http}->add_header(key => 'X-Vault-Token', value => $self->{vault_token});
        }
    }

    if (!defined($self->{vault_address})) {
        $self->{output}->add_option_msg(short_msg => "Please configure vault-address in $options{option_results}->{vault_config} file");
        $self->{output}->option_exit();
    }
}

sub request_api {
    my ($self, %options) = @_;

    $self->vault_settings(%options);

    foreach my $endpoint (@{$self->{request_endpoint}}) {
        my $json;
        my $response = $self->{http}->request(
            hostname => $self->{vault_address},
            port => $self->{vault_port},
            proto => $self->{vault_protocol},
            method => 'GET',
            url_path => $endpoint
        );
        $self->{output}->output_add(long_msg => $response, debug => 1);
        eval {
            $json = JSON::XS->new->utf8->decode($response);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode Vault JSON response: $@");
            $self->{output}->option_exit();
        } else {
            foreach (keys %{$json->{data}}) {
                $self->{lookup_values}->{"{".$_."::secret::".substr($endpoint, index($endpoint, "/", 1))."}"} = $json->{data}->{$_};
            }
        }
    }
}

sub do_map {
    my ($self, %options) = @_;

    return if (!defined($options{option_results}->{map_option}));
    foreach (@{$options{option_results}->{map_option}}) {
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

    return if (!defined($options{option_results}->{map_option}));

    my ($content, $debug) = $self->request_api(%options);
    if (!defined($content)) {
        $self->{output}->add_option_msg(short_msg => "Cannot read Vault information");
        $self->{output}->option_exit();
    }
    $self->do_map(%options);

    $self->{output}->output_add(long_msg => Data::Dumper::Dumper($debug), debug => 1) if ($self->{output}->is_debug());
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