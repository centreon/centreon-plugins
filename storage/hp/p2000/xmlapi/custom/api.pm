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

package storage::hp::p2000::xmlapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use Digest::MD5 qw(md5_hex);
use XML::LibXML::Simple;

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
            'hostname:s@'      => { name => 'hostname' },
            'port:s@'          => { name => 'port' },
            'proto:s@'         => { name => 'proto' },
            'urlpath:s@'       => { name => 'url_path' },
            'username:s@'      => { name => 'username' },
            'password:s@'      => { name => 'password' },
            'timeout:s@'       => { name => 'timeout' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'P2000 OPTIONS', once => 1);

    $self->{http} = centreon::plugins::http->new(%options);

    $self->{output} = $options{output};
    
    $self->{session_id} = '';
    $self->{logon} = 0;
    
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
    $self->{username} = (defined($self->{option_results}->{username})) ? shift(@{$self->{option_results}->{username}}) : undef;
    $self->{password} = (defined($self->{option_results}->{password})) ? shift(@{$self->{option_results}->{password}}) : undef;
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : 45;
    $self->{port} = (defined($self->{option_results}->{port})) ? shift(@{$self->{option_results}->{port}}) : undef;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? shift(@{$self->{option_results}->{proto}}) : 'http';
    $self->{url_path} = (defined($self->{option_results}->{url_path})) ? shift(@{$self->{option_results}->{url_path}}) : '/api/';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300' ;
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';
        
    if (!defined($self->{hostname})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify hostname option.');
        $self->{output}->option_exit();
    }
    if (!defined($self->{username}) || !defined($self->{password})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify username or/and password option.');
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
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{url_path} = $self->{url_path};
}

sub check_login {
    my ($self, %options) = @_;

    my $xml;
    eval {
        $SIG{__WARN__} = sub {};
        $xml = XMLin($options{content}, ForceArray => [], KeyAttr => []);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot parse login response: $@");
        $self->{output}->option_exit();
    }

    if (!defined($xml->{OBJECT}) || !defined($xml->{OBJECT}->{PROPERTY})) {
        $self->{output}->add_option_msg(short_msg => 'Cannot find login response');
        $self->{output}->option_exit();
    }

    my ($session_id, $return_code);
    foreach (@{$xml->{OBJECT}->{PROPERTY}}) {
        $return_code = $_->{content} if ($_->{name} eq 'return-code');
        $session_id = $_->{content} if ($_->{name} eq 'response');
    }

    if ($return_code != 1) {
        $self->{output}->add_option_msg(short_msg => 'Login authentification failed (return-code: ' . $return_code . ').');
        $self->{output}->option_exit();
    }

    $self->{session_id} = $session_id;
    $self->{logon} = 1;
}

sub DESTROY {
    my $self = shift;
    
    if ($self->{logon} == 1) {
        $self->{http}->request(
            url_path => $self->{url_path} . 'exit',
            header => [
                'Cookie: wbisessionkey=' . $self->{session_id} . '; wbiusername=' . $self->{username},
                'dataType: api', 'sessionKey: '. $self->{session_id}
            ],
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status},
        );
    }
}

sub get_infos {
    my ($self, %options) = @_;
    my ($xpath, $nodeset);

    $self->login();
    my $cmd = $options{cmd};
    $cmd =~ s/ /\//g;

    my ($unknown_status, $warning_status, $critical_status) = ($self->{unknown_http_status}, $self->{warning_http_status}, $self->{critical_http_status});
    if (defined($options{no_quit}) && $options{no_quit} == 1) {
        ($unknown_status, $warning_status, $critical_status) = ('', '', '');
    }
    my ($response) = $self->{http}->request(
        url_path => $self->{url_path} . $cmd, 
        header => [
            'Cookie: wbisessionkey=' . $self->{session_id} . '; wbiusername=' . $self->{username},
            'dataType: api', 'sessionKey: '. $self->{session_id}
        ],
        unknown_status => $unknown_status,
        warning_status => $warning_status,
        critical_status => $critical_status
    );

    my $xml;
    eval {
        $SIG{__WARN__} = sub {};
        $xml = XMLin($response, ForceArray => ['OBJECT'], KeyAttr => []);
    };
    if ($@) {
        return ({}, 0) if (defined($options{no_quit}) && $options{no_quit} == 1);
        $self->{output}->add_option_msg(short_msg => "Cannot parse 'cmd' response: $@");
        $self->{output}->option_exit();
    }

    # Check if there is an error
    #<OBJECT basetype="status" name="status" oid="1">
        #<PROPERTY name="response-type" type="enumeration" size="12" draw="false" sort="nosort" display-name="Response Type">Error</PROPERTY>
        #<PROPERTY name="response-type-numeric" type="enumeration" size="12" draw="false" sort="nosort" display-name="Response">1</PROPERTY>
        #<PROPERTY name="response" type="string" size="180" draw="true" sort="nosort" display-name="Response">The command is ambiguous. Please check the help for this command.</PROPERTY>
        #<PROPERTY name="return-code" type="int32" size="5" draw="false" sort="nosort" display-name="Return Code">-10028</PROPERTY>
        #<PROPERTY name="component-id" type="string" size="80" draw="false" sort="nosort" display-name="Component ID"></PROPERTY>
    #</OBJECT>
    my $results = {};
    $results = [] if (!defined($options{key}));
    foreach my $obj (@{$xml->{OBJECT}}) {
        if ($obj->{basetype} eq 'status') {
            my ($return_code, $response) = (-1, 'n/a');
            foreach my $prop (@{$obj->{PROPERTY}}) {
                $return_code = $prop->{content} if ($prop->{name} eq 'return-code');
                $response = $prop->{content} if ($prop->{name} eq 'response');
            }

            if ($return_code != 0) {
                return ({}, 0) if (defined($options{no_quit}) && $options{no_quit} == 1);
                $self->{output}->add_option_msg(short_msg => $response);
                $self->{output}->option_exit();
            }
        }

        if ($obj->{basetype} eq $options{base_type}) {
            my $properties = {};
            foreach (keys %$obj) {
                $properties->{$_} = $obj->{$_} if (/$options{properties_name}/);
            }
            foreach my $prop (@{$obj->{PROPERTY}}) {
                if (defined($prop->{name}) &&
                    ((defined($options{key}) && $prop->{name} eq $options{key}) || $prop->{name} =~ /$options{properties_name}/)) {
                    $properties->{ $prop->{name} } = $prop->{content};
                }
            }

            if (defined($options{key})) {
                $results->{ $properties->{ $options{key} } } = $properties
                    if (defined($properties->{ $options{key} }));
            } else {
                push @$results, $properties;
            }
        }
    }

    return ($results, 1);
}

##############
# Specific methods
##############
sub login {
    my ($self, %options) = @_;

    return if ($self->{logon} == 1);

    $self->build_options_for_httplib();
    $self->{http}->set_options(%{$self->{option_results}});

    # Login First
    my $md5_hash = md5_hex($self->{username} . '_' . $self->{password});
    my $response = $self->{http}->request(
        url_path => $self->{url_path} . 'login/' . $md5_hash,
        unknown_status => $self->{unknown_http_status},
        warning_status => $self->{warning_http_status},
        critical_status => $self->{critical_http_status},
    );

    $self->check_login(content => $response);
}

1;

__END__

=head1 NAME

MSA p2000

=head1 SYNOPSIS

my p2000 xml api manage

=head1 P2000 OPTIONS

=over 8

=item B<--hostname>

HP p2000 Hostname.

=item B<--port>

Port used

=item B<--proto>

Specify https if needed

=item B<--urlpath>

Set path to xml api (Default: '/api/')

=item B<--username>

Username to connect.

=item B<--password>

Password to connect.

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
