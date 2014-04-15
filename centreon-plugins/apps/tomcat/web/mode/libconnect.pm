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
# Author : Florian Asche <info@florian-asche.de>
#
# Based on De Bodt Lieven plugin
# Based on Apache Mode by Simon BOMM
####################################################################################

package apps::tomcat::web::mode::libconnect;

use strict;
use warnings;
use LWP::UserAgent;

sub connect {
    my ($self, %options) = @_;
    my $ua = LWP::UserAgent->new( protocols_allowed => ['http', 'https'], timeout => $self->{option_results}->{timeout});
    my $connection_exit = defined($options{connection_exit}) ? $options{connection_exit} : 'unknown';
    
    my ($response, $content);

    my $req = HTTP::Request->new( GET => $self->{option_results}->{proto}."://" .$self->{option_results}->{hostname}.':'.$self->{option_results}->{port}.$self->{option_results}->{path});
    
    if (defined($self->{option_results}->{credentials})) {
        $req->authorization_basic($self->{option_results}->{username}, $self->{option_results}->{password});
    }
    
    if (defined($self->{option_results}->{proxyurl})) {
         $ua->proxy(['http', 'https'], $self->{option_results}->{proxyurl});
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

