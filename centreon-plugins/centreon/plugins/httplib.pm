###############################################################################
# Copyright 2005-2015 CENTREON
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
# As a special exception, the copyright holders of this program give CENTREON
# permission to link this program with independent modules to produce an timeelapsedutable,
# regardless of the license terms of these independent modules, and to copy and
# distribute the resulting timeelapsedutable under terms of CENTREON choice, provided that
# CENTREON also meet, for each linked independent module, the terms  and conditions
# of the license of that module. An independent module is a module which is not
# derived from this program. If you modify this program, you may extend this
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
#
# For more information : contact@centreon.com
# Authors : Simon BOMM <sbomm@merethis.com>
#           Mathieu Cinquin <mcinqui@centreon.com>
#
# Based on De Bodt Lieven plugin
####################################################################################

package centreon::plugins::httplib;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Cookies;
use URI;

sub get_port {
    my ($self, %options) = @_;

    my $cache_port = '';
    if (defined($self->{option_results}->{port}) && $self->{option_results}->{port} ne '') {
        $cache_port = $self->{option_results}->{port};
    } else {
        $cache_port = 80 if ($self->{option_results}->{proto} eq 'http');
        $cache_port = 443 if ($self->{option_results}->{proto} eq 'https');
    }

    return $cache_port;
}

sub connect {
    my ($self, %options) = @_;
    my $method = defined($options{method}) ? $options{method} : 'GET';
    my $connection_exit = defined($options{connection_exit}) ? $options{connection_exit} : 'unknown';

    my $ua = LWP::UserAgent->new(keep_alive => 1, protocols_allowed => ['http', 'https'], timeout => $self->{option_results}->{timeout},
                                 requests_redirectable => [ 'GET', 'HEAD', 'POST' ]);
    if (defined($options{cookies_file})) {
        $ua->cookie_jar(HTTP::Cookies->new(file => $options{cookies_file},
                                           autosave => 1));
    }

    my ($response, $content);
    my ($req, $url);
    if (defined($self->{option_results}->{port}) && $self->{option_results}->{port} =~ /^[0-9]+$/) {
        $url = $self->{option_results}->{proto}. "://" . $self->{option_results}->{hostname}.':'. $self->{option_results}->{port} . $self->{option_results}->{url_path};
    } else {
        $url = $self->{option_results}->{proto}. "://" . $self->{option_results}->{hostname} . $self->{option_results}->{url_path};
    }

    my $uri = URI->new($url);
    if (defined($options{query_form_get})) {
        $uri->query_form($options{query_form_get});
    }
    $req = HTTP::Request->new($method => $uri);

    my $content_type_forced;
    if (defined($options{headers})) {
        foreach my $key (keys %{$options{headers}}) {
            if ($key !~ /content-type/i) {
                $req->header($key => $options{headers}->{$key});
            } else {
                $content_type_forced = $options{headers}->{$key};
            }
        }
    }

    if ($method eq 'POST') {
        if (defined($content_type_forced)) {
            $req->content_type($content_type_forced);
            $req->content($options{query_form_post});
        } else {
            my $uri_post = URI->new();
            if (defined($options{query_form_post})) {
                $uri_post->query_form($options{query_form_post});
            }
            $req->content_type('application/x-www-form-urlencoded');
            $req->content($uri_post->query);
        }
    }

    if (defined($self->{option_results}->{credentials}) && defined($self->{option_results}->{ntlm})) {
        $ua->credentials($self->{option_results}->{hostname} . ':' . $self->{option_results}->{port}, '', $self->{option_results}->{username}, $self->{option_results}->{password});
    } elsif (defined($self->{option_results}->{credentials})) {
        $req->authorization_basic($self->{option_results}->{username}, $self->{option_results}->{password});
    }

    if (defined($self->{option_results}->{proxyurl})) {
        $ua->proxy(['http', 'https'], $self->{option_results}->{proxyurl});
    }

	if (defined($self->{option_results}->{ssl}) && $self->{option_results}->{ssl} ne '') {
		use IO::Socket::SSL;
		my $context = new IO::Socket::SSL::SSL_Context(
			SSL_version => $self->{option_results}->{ssl},
		);
		IO::Socket::SSL::set_default_context($context);
    }

    if (defined($self->{option_results}->{cert_pkcs12}) && $self->{option_results}->{cert_file} ne '' && $self->{option_results}->{cert_pwd} ne '') {
        use Net::SSL;
        $ENV{HTTPS_PKCS12_FILE} = $self->{option_results}->{cert_file};
        $ENV{HTTPS_PKCS12_PASSWORD} = $self->{option_results}->{cert_pwd};
    }

    if (defined($self->{option_results}->{cert_file}) && !defined($self->{option_results}->{cert_pkcs12})) {
        use Net::SSL;
        $ENV{HTTPS_CERT_FILE} = $self->{option_results}->{cert_file};
    }

    $response = $ua->request($req);

    if ($response->is_success) {
        $content = $response->content;
        return $content;
    }

    $self->{output}->output_add(severity => $connection_exit,
                                short_msg => $response->status_line);
    $self->{output}->display();
    $self->{output}->exit();
}

1;
