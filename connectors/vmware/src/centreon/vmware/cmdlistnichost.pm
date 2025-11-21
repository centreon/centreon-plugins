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

package centreon::vmware::cmdlistnichost;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'listnichost';
    
    return $self;
}

sub checkArgs {
    my ($self, %options) = @_;

    if (!defined($options{arguments}->{esx_hostname}) || $options{arguments}->{esx_hostname} eq "") {
        centreon::vmware::common::set_response(code => 100, short_message => "Argument error: esx hostname need to be set");
        return 1;
    }
    return 0;
}

sub run {
    my $self = shift;
    my %nic_in_vswitch = ();
    
    my $filters = $self->build_filter(label => 'name', search_option => 'esx_hostname', is_regexp => 'filter');
    my @properties = ('config.network.pnic', 'config.network.vswitch', 'config.network.proxySwitch');
    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'HostSystem', properties => \@properties, filter => $filters);
    return if (!defined($result));
    
    # Get Name from vswitch
    if (defined($$result[0]->{'config.network.vswitch'})) {
        foreach (@{$$result[0]->{'config.network.vswitch'}}) {
            next if (!defined($_->{pnic}));
            foreach my $keynic (@{$_->{pnic}}) {
                $nic_in_vswitch{$keynic} = 1;
            }
        }
    }
    # Get Name from proxySwitch
    if (defined($$result[0]->{'config.network.proxySwitch'})) {
        foreach (@{$$result[0]->{'config.network.proxySwitch'}}) {
            next if (!defined($_->{pnic}));
            foreach my $keynic (@{$_->{pnic}}) {
                $nic_in_vswitch{$keynic} = 1;
            }
        }
    }
    
    my %nics = ();
    foreach (@{$$result[0]->{'config.network.pnic'}}) {
        if (defined($nic_in_vswitch{$_->key})) {
            $nics{$_->device}{vswitch} = 1;
        }
        if (defined($_->linkSpeed)) {
            $nics{$_->device}{up} = 1;
        } else {
            $nics{$_->device}{down} = 1;
        }
    }

    my $data = {};
    foreach my $nic_name (sort keys %nics) {
        my $status = defined($nics{$nic_name}{up}) ? 'up' : 'down';
        my $vswitch = defined($nics{$nic_name}{vswitch}) ? 1 : 0;
        
        $data->{$nic_name} = { name => $nic_name, status => $status, vswitch => $vswitch };
    }

    centreon::vmware::common::set_response(data => $data);
}

1;
