# Copyright 2024 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets 
# the needs in IT infrastructure and application monitoring for 
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0  
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package centreon::vmware::cmdlicenses;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'licenses';
    
    return $self;
}

sub checkArgs {
    my ($self, %options) = @_;

    return 0;
}

sub run {
    my $self = shift;

    my $entries = centreon::vmware::common::get_view($self->{connector}, $self->{connector}->{session}->get_service_content()->licenseManager);

    my $data = {};
    if (defined($entries->licenses)) {
        foreach my $license (@{$entries->licenses}) {
            $data->{ $license->{name} } = {
                total => $license->{total},
                used => $license->{used},
                edition => $license->{editionKey}
            };
            foreach my $prop (@{$license->{properties}}) {
                if ($prop->{key} eq 'expirationMinutes') {
                    $data->{ $license->{name} }->{expiration_minutes} = $prop->{value};
                }
            }
        }
    }

    centreon::vmware::common::set_response(data => $data);    
}

1;
