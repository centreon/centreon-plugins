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

sub get_attributes {
    my ($self, %options) = @_;
    my $dont_quit = defined($options{dont_quit}) && $options{dont_quit} == 1 ? 1 : 0;
    
    if (!defined($self->{jmx4perl})) {
        $self->connect();
    }
    
    my $resp;
    eval {
        local $SIG{__DIE__} = 'IGNORE';
        my $attributes = $options{attributes};
        if (defined($attributes) && ref($attributes) eq 'ARRAY' && scalar(@{$attributes}) == 1) {
            $attributes = $attributes->[0];
        }
        $resp = $self->{jmx4perl}->get_attribute($options{mbean_pattern}, $attributes, $options{path});
    };
    if ($@ && $dont_quit == 0) {
        $self->{output}->add_option_msg(short_msg => "protocol issue: " . $@);
        $self->{output}->option_exit();
    }

    return $resp;
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