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