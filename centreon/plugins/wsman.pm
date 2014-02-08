################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package centreon::plugins::wsman;

use strict;
use warnings;
use openwsman;

my %auth_method_map = (
    noauth          => $openwsman::NO_AUTH_STR,
    basic           => $openwsman::BASIC_AUTH_STR,
    digest          => $openwsman::DIGEST_AUTH_STR,
    pass            => $openwsman::PASS_AUTH_STR,
    ntml            => $openwsman::NTML_AUTH_STR,
    gssnegotiate    => $openwsman::GSSNEGOTIATE_AUTH_STR,
);

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;
    # $options{options} = options object
    # $options{output} = output object
    # $options{exit_value} = integer
    
    if (!defined($options{output})) {
        print "Class wsman: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class wsman: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    $options{options}->add_options(arguments => 
                { "hostname|host:s"           => { name => 'host' },
                  "wsman-port:s"              => { name => 'wsman_port', default => 5985 },
                  "wsman-path:s"              => { name => 'wsman_path', default => '/wsman' },
                  "wsman-scheme:s"            => { name => 'wsman_scheme', default => 'http' },
                  "wsman-username:s"          => { name => 'wsman_username' },
                  "wsman-password:s"          => { name => 'wsman_password' },
                  "wsman-timeout:s"           => { name => 'wsman_timeout', default => 30 },
                  "wsman-proxy-url:s"         => { name => 'wsman_proxy_url', },
                  "wsman-proxy-username:s"    => { name => 'wsman_proxy_username', },
                  "wsman-proxy-password:s"    => { name => 'wsman_proxy_password', },
                  "wsman-debug"               => { name => 'wsman_debug', },
                  "wsman-auth-method:s"       => { name => 'wsman_auth_method', default => 'basic' },
                  "wsman-errors-exit:s"       => { name => 'wsman_errors_exit', default => 'unknown' },
    });
    $options{options}->add_help(package => __PACKAGE__, sections => 'WSMAN OPTIONS');

    #####
    $self->{client} = undef;
    $self->{output} = $options{output};
    $self->{wsman_params} = {};

    $self->{error_msg} = undef;
    $self->{error_status} = 0;
    
    return $self;
}

sub connect {
    my ($self, %options) = @_;

    if (!$self->{output}->is_litteral_status(status => $self->{wsman_errors_exit})) {
        $self->{output}->add_option_msg(short_msg => "Unknown value '" . $self->{wsman_errors_exit}  . "' for --wsman-errors-exit.");
        $self->{output}->option_exit(exit_litteral => 'unknown');
    }
    
    openwsman::set_debug(1) if (defined($self->{wsman_params}->{wsman_debug});
    $self->{client} = new openwsman::Client::($self->{wsman_params}->{host}, $self->{wsman_params}->{wsman_port}, 
                                              $self->{wsman_params}->{wsman_path}, $self->{wsman_params}->{wsman_scheme},
                                              $self->{wsman_params}->{wsman_username}, $self->{wsman_params}->{wsman_password});
    if (!defined($self->{client})) {
        $self->{output}->add_option_msg(short_msg => 'Could not create client handler');
        $self->{output}->option_exit(exit_litteral => $self->{wsman_errors_exit});
    }
    
    $self->{client}->transport()->set_auth_method($auth_method_map{$self->{wsman_params}->{wsman_auth_method}});
    $self->{client}->transport()->set_timeout($self->{wsman_params}->{wsman_timeout});
    if (defined($self->{wsman_params}->{wsman_proxy_url})) {
        $self->{client}->transport()->set_proxy($self->{wsman_params}->{wsman_proxy_url});
        if (defined($self->{wsman_params}->{wsman_proxy_username}) && defined($self->{wsman_params}->{wsman_proxy_password})) {
            $self->{client}->transport()->set_proxyauth($self->{wsman_params}->{wsman_proxy_username} . ':' . $self->{wsman_params}->{wsman_proxy_password});
        }
    }
}

sub request {
    my ($self, %options) = @_;
    # $options{nothing_quit} = integer
    # $options{dont_quit} = integer
    # $options{uri} = string
    # $options{wql_fitler} = string
    # $options{result_type} = string ('array' or 'hash' with a key)
    # $options{hash_key} = string
    
    my ($dont_quit) = (defined($options{dont_quit}) && $options{dont_quit} == 1) ? 1 : 0;
    my ($nothing_quit) = (defined($options{nothing_quit}) && $options{nothing_quit} == 1) ? 1 : 0;
    my ($result_type) = (defined($options{result_type}) && $options{result_type} =~ /^(array|hash)$/) ? $options{result_type} : 'array';
    $self->set_error();
    
    ######
    # Check options
    if (!defined($options{uri}) || !defined($options{wql_fitler})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify wql_filter and uri options');
        $self->{output}->option_exit(exit_litteral => $self->{wsman_errors_exit});
    }
    
    ######
    # ClientOptions object
    my $client_options = new openwsman::ClientOptions::();
    if (!defined($client_options)) {
        if ($dont_quit == 1) {
            $self->set_error(error_status => -1, error_msg => 'Could not create client options handler');
            return undef;
        }
        $self->{output}->add_option_msg(short_msg => 'Could not create client options handler');
        $self->{output}->option_exit(exit_litteral => $self->{wsman_errors_exit});
    }
    # Optimization
    $client_options->set_flags($openwsman::FLAG_ENUMERATION_OPTIMIZATION);
    $client_options->set_max_elements(999);
    
    ######
    # Filter/Enumerate
    my $filter = new openwsman::Filter::();
    if (!defined($filter)) {
        if ($dont_quit == 1) {
            $self->set_error(error_status => -1, error_msg => 'Could not create filter');
            return undef;
        }
        $self->{output}->add_option_msg(short_msg => 'Could not create filter.');
        $self->{output}->option_exit(exit_litteral => $self->{wsman_errors_exit});
    }
    $filter->wql($options{wql_fitler});
    
    my $result = $self->{client}->enumerate($client_options, $filter, $options{uri});
    unless($result && $result->is_fault eq 0) {
        my $fault_string = $self->{client}->fault_string();
        my $msg = 'Could not enumerate instances: ' . ((defined($fault_string)) ? $fault_string : 'use debug option to have details');
        if ($dont_quit == 1) {
            $self->set_error(error_status => -1, error_msg => $msg );
            return undef;
        }
        $self->{output}->add_option_msg(short_msg => $msg);
        $self->{output}->option_exit(exit_litteral => $self->{wsman_errors_exit});
    }

    ######
    # Fetch values
    my ($array_return, $hash_return)
    
    $array_return = [] if ($result_type eq 'array');
    $hash_return = {} if ($result_type eq 'hash');
    my $context = $result->context();
    my $total = 0;

    while ($context) {
        # Pull from local server.
        # (options, filter, resource uri, enum context)

        $result = $self->{client}->pull($client_options, $filter, $options{uri}, $context);
        next unless($result);

        # Get nodes.
        # soap body -> PullResponse -> items
        my $nodes = $result->body()->find($openwsman::XML_NS_ENUMERATION, "Items");
        next unless($nodes);

        # Get items.
        my $items;
        for (my $cnt = 0; ($cnt<$nodes->size()); $cnt++) {
            my $row_return = {};
            for (my $cnt2 = 0; ($cnt2<$nodes->get($cnt)->size()); $cnt2++) {
                $row_return->{$nodes->get($cnt)->get($cnt2)->name()} = $nodes->get($cnt)->get($cnt2)->text();
            }
            $total++;
            push @{$array_return}, $row_return if ($result_type eq 'array');
            $hash_return->{$row_return->{$options{hash_key}}} = $row_return if ($result_type eq 'hash');
        }
        $context = $result->context();
    }

    # Release context.
    $self->{client}->release($client_options, $options{uri}, $context) if($context);
    
    if ($nothing_quit == 1 && $total == 0) {
        $self->{output}->add_option_msg(short_msg => "Cant get a single value.");
        $self->{output}->option_exit(exit_litteral => $self->{option_results}->{wsman_errors_exit});
    }
    
    if ($result_type eq 'array') {
        return $array_return;
    }
    return $hash_return;
}

sub check_options {
    my ($self, %options) = @_;
    # $options{option_results} = ref to options result
    
    $self->{wsman_errors_exit} = $options{option_results}->{wsman_errors_exit};

    if (!defined($options{option_results}->{host})) {
        $self->{output}->add_option_msg(short_msg => "Missing parameter --hostname.");
        $self->{output}->option_exit();
    }
    $self->{wsman_params}->{host} = $options{option_results}->{host};

    if (!defined($options{option_results}->{wsman_scheme}) || $options{option_results}->{wsman_scheme} !~ /^(http|https)$/) {
        $self->{output}->add_option_msg(short_msg => "Wrong scheme parameter. Must be 'http' or 'https'.");
        $self->{output}->option_exit();
    }
    $self->{wsman_params}->{wsman_scheme} = $options{option_results}->{wsman_scheme};
    
    if (!defined($options{option_results}->{wsman_auth_method}) || !defined($auth_method_map{$options{option_results}->{wsman_auth_method}})) {
        $self->{output}->add_option_msg(short_msg => "Wrong wsman auth method parameter. Must be 'basic', 'noauth', 'digest', 'pass', 'ntml' or 'gssnegotiate'.");
        $self->{output}->option_exit();
    }
    $self->{wsman_params}->{wsman_auth_method} = $options{option_results}->{wsman_auth_method};

    if (!defined($options{option_results}->{wsman_port}) || $options{option_results}->{wsman_port} !~ /^([0-9]+)$/) {
        $self->{output}->add_option_msg(short_msg => "Wrong wsman port parameter. Must be an integer.");
        $self->{output}->option_exit();
    }
    $self->{wsman_params}->{wsman_port} = $options{option_results}->{wsman_port};    
    
    $self->{wsman_params}->{wsman_path} = $options{option_results}->{wsman_path};
    $self->{wsman_params}->{wsman_username} = $options{option_results}->{wsman_username};
    $self->{wsman_params}->{wsman_password} = $options{option_results}->{wsman_password};
    $self->{wsman_params}->{wsman_timeout} = $options{option_results}->{wsman_timeout};
    $self->{wsman_params}->{wsman_proxy_url} = $options{option_results}->{wsman_proxy_url};
    $self->{wsman_params}->{wsman_proxy_username} = $options{option_results}->{wsman_proxy_username};
    $self->{wsman_params}->{wsman_proxy_password} = $options{option_results}->{wsman_proxy_password};
    $self->{wsman_params}->{wsman_debug} = $options{option_results}->{wsman_debug};
}

sub set_error {
    my ($self, %options) = @_;
    # $options{error_msg} = string error
    # $options{error_status} = integer status
    
    $self->{error_status} = defined($options{error_status}) ? $options{error_status} : 0;
    $self->{error_msg} = defined($options{error_msg}) ? $options{error_msg} : undef;
}

sub error_status {
     my ($self) = @_;
    
    return $self->{error_status};
}

sub error {
    my ($self) = @_;
    
    return $self->{error_msg};
}

sub get_hostname {
    my ($self) = @_;

    my $host = $self->{wsman_params}->{host};
    return $host;
}

sub get_port {
    my ($self) = @_;

    return $self->{wsman_params}->{wsman_port};
}

1;

__END__

=head1 NAME

WSMAN global

=head1 SYNOPSIS

wsman class

=head1 WSMAN OPTIONS

=over 8

Need at least openwsman-perl version >= 2.3.0

=item B<--hostname>

Hostname to query (required).

=item B<--wsman-port>

Port (default: 5985).

=item B<--wsman-path>

Set path of URL (default: '/wsman').

=item B<--wsman-scheme>

Set transport scheme (default: 'http').

=item B<--wsman-username>

Set username for authentification.

=item B<--wsman-password>

Set username password for authentification.

=item B<--wsman-timeout>

Set HTTP Transport Timeout in seconds (default: 30).

=item B<--wsman-auth-method>

Set the authentification method (default: 'basic').

=item B<--wsman-proxy-url>

Set HTTP proxy URL.

=item B<--wsman-proxy-username>

Set the proxy username.

=item B<--wsman-proxy-password>

Set the proxy password.

=item B<--wsman-debug>

Set openwsman debug on (Only for test purpose).

=item B<--wsman-errors-exit>

Exit code for wsman Errors (default: unknown)

=back

=head1 DESCRIPTION

B<wsman>.

=cut
