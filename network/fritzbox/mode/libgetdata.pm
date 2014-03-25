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
# Authors : Florian Asche <info@florian-asche.de>
#
####################################################################################

package network::fritzbox::mode::libgetdata;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use SOAP::Lite;

my $soap;
my $response;

sub init {
    my ($self, %options) = @_;
    
    my $proxy = 'http://' . $self->{option_results}->{hostname} . ':' . $self->{option_results}->{port} . $options{pfad};

    $soap = SOAP::Lite->new(
        proxy		=> $proxy,
        uri         => $options{uri},
        timeout     => $self->{option_results}->{timeout}
    );
    $soap->on_fault(
        sub {    # SOAP fault handler
            my $soap = shift;
            my $res  = shift;

            if(ref($res)) {
                chomp( my $err = $res->faultstring );
                $self->{output}->output_add(severity => 'UNKNOWN',
                                            short_msg => "SOAP Fault: $err");
            } else {
                chomp( my $err = $soap->transport->status );
                $self->{output}->output_add(severity => 'UNKNOWN',
                                            short_msg => "Transport error: $err");     
            }
            
            $self->{output}->display();
            $self->{output}->exit();
        }
    );
}

sub call {
    my ($self, %options) = @_;
    
    my $method = $options{soap_method};
    $response = $soap->$method();
}

sub value {
    my ($self, %options) = @_;
    my $value = $response->valueof($options{path});
    
    return $value;
}

1;