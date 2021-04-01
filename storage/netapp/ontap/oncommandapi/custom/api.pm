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

package storage::netapp::ontap::oncommandapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;
use URI::Encode;

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
            'hostname:s@' => { name => 'hostname' },
            'url-path:s@' => { name => 'url_path' },
            'port:s@'     => { name => 'port' },
            'proto:s@'    => { name => 'proto' },
            'username:s@' => { name => 'username' },
            'password:s@' => { name => 'password' },
            'timeout:s@'  => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'OnCommand API OPTIONS', once => 1);

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
    $self->{url_path} = (defined($self->{option_results}->{url_path})) ? shift(@{$self->{option_results}->{url_path}}) : '/api/4.0/ontap';
    $self->{port} = (defined($self->{option_results}->{port})) ? shift(@{$self->{option_results}->{port}}) : 8443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? shift(@{$self->{option_results}->{proto}}) : 'https';
    $self->{username} = (defined($self->{option_results}->{username})) ? shift(@{$self->{option_results}->{username}}) : '';
    $self->{password} = (defined($self->{option_results}->{password})) ? shift(@{$self->{option_results}->{password}}) : '';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : 10;
 
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
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{credentials} = 1;
    $self->{option_results}->{basic} = 1;
    $self->{option_results}->{username} = $self->{username};
    $self->{option_results}->{password} = $self->{password};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_connection_info {
    my ($self, %options) = @_;
    
    return $self->{hostname} . ":" . $self->{port};
}

sub get_objects {
    my ($self, %options) = @_;

    my %objects;
    my $objects = $self->get(%options);
    foreach my $object (@{$objects}) {
        $objects{$object->{$options{key}}} = $object->{$options{name}};
    }

    return \%objects;
}

sub get_next {
    my ($self, %options) = @_;

    my $encoded_tag = '';
    if (defined($options{nextTag})) {
        my $uri = URI::Encode->new({encode_reserved => 1});
        $encoded_tag = "nextTag=" . $uri->encode($options{nextTag});
    }

    my $url_path = $self->{url_path} . $options{path};
    $url_path .= '?' . $options{args} if (defined($options{args}));
    $url_path .= '?' . $encoded_tag if (defined($options{nextTag}) && !defined($options{args}));
    $url_path .= '&' . $encoded_tag if (defined($options{nextTag}) && defined($options{args}));
    
    my $response = $self->{http}->request(url_path => $url_path);
    
    my $content;
    eval {
        $content = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    if (defined($content->{errmsg})) {
        $self->{output}->add_option_msg(short_msg => "Cannot get data: " . $content->{errmsg});
        $self->{output}->option_exit();
    }
    
    return $content;
}

sub get {
    my ($self, %options) = @_;

    $self->settings();

    my @result;
    while(my $content = $self->get_next(%options)) {
        push @result, @{$content->{result}->{records}};
        
        last if (!defined($content->{result}->{nextTag}));
        $options{nextTag} = $content->{result}->{nextTag};
    }

    return \@result;
}

1;

__END__

=head1 NAME

NetApp OnCommand API

=head1 SYNOPSIS

NetApp OnCommand API custom mode

=head1 OnCommand API OPTIONS

=over 8

=item B<--hostname>

NetApp hostname.

=item B<--url-path>

OnCommand API url path (Default: '/api/4.0/ontap')

=item B<--port>

OnCommand API port (Default: 8443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--username>

OnCommand API username.

=item B<--password>

OnCommand API password.

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
