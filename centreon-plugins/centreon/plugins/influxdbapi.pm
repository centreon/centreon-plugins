###############################################################################
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
# permission to link this program with independent modules to produce an timeelapsedutable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting timeelapsedutable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
#
# For more information : contact@centreon.com
# Author : Mathieu Cinquin <mcinquin@merethis.com>
#
####################################################################################

package centreon::plugins::influxdbapi;

use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use URI;

sub get_port {
    my ($self, %options) = @_;

    my $cache_port = '';
    if (defined($self->{option_results}->{port}) && $self->{option_results}->{port} ne '') {
        $cache_port = $self->{option_results}->{port};
    } else {
        $cache_port = 8086;
    }

    return $cache_port;
}

sub connect {
    my ($self, %options) = @_;
    my $ua = LWP::UserAgent->new( keep_alive => 1, protocols_allowed => ['http','https'], timeout => $self->{option_results}->{timeout});
    my $connection_exit = defined($options{connection_exit}) ? $options{connection_exit} : 'unknown';

    my ($response, $content);
    my $req;
    my $url = $self->{option_results}->{proto}.'://'.$self->{option_results}->{hostname}.':'.$self->{option_results}->{port};
    $url .= '/db/'.$self->{option_results}->{database}."/series";

    my $uri = URI->new($url);
    $uri->query_form(q => $self->{option_results}->{query}, u => $self->{option_results}->{username}, p => $self->{option_results}->{password});

    $req = HTTP::Request->new( GET => $uri);
    $response = $ua->request($req);

    if ($response->is_success) {
        my $json = JSON->new;

        eval {
            $content = $json->decode($response->content);
        };

        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
            $self->{output}->option_exit();
        }

        return $content;
    }

    $self->{output}->output_add(severity => $connection_exit,
                                short_msg => $response->status_line);
    $self->{output}->display();
    $self->{output}->exit();
}

1;
