# Copyright 2015 Centreon (http://www.centreon.com/)
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

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'listnichost';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my ($self, %options) = @_;

    if (!defined($options{arguments}->{esx_hostname}) || $options{arguments}->{esx_hostname} eq "") {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: esx hostname need to be set");
        return 1;
    }
    return 0;
}

sub initArgs {
     my ($self, %options) = @_;
    
    foreach (keys %{$options{arguments}}) {
        $self->{$_} = $options{arguments}->{$_};
    }
    $self->{manager} = centreon::vmware::common::init_response();
    $self->{manager}->{output}->{plugin} = $options{arguments}->{identity};
}

sub set_connector {
    my ($self, %options) = @_;
    
    $self->{connector} = $options{connector};
}

sub run {
    my $self = shift;
    my %nic_in_vswitch = ();
    
    my %filters = (name => $self->{esx_hostname});
    my @properties = ('config.network.pnic', 'config.network.vswitch', 'config.network.proxySwitch');
    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'HostSystem', properties => \@properties, filter => \%filters);
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

    if (!defined($self->{disco_show})) {
        $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => 'List nic host:');
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
    
    foreach my $nic_name (sort keys %nics) {
        my $status = defined($nics{$nic_name}{up}) ? 'up' : 'down';
        my $vswitch = defined($nics{$nic_name}{vswitch}) ? 1 : 0;
        
        if (defined($self->{disco_show})) {
            $self->{manager}->{output}->add_disco_entry(name => $nic_name,
                                                        status => $status,
                                                        vswitch => $vswitch);
        } else {
            $self->{manager}->{output}->output_add(long_msg => sprintf('%s [status: %s] [vswitch: %s]', 
                                                                       $nic_name, $status, $vswitch));
        }
    }
    
    if (defined($self->{disco_show})) {
        my $stdout;
        {
            local *STDOUT;
            $self->{manager}->{output}->{option_results}->{output_xml} = 1;
            open STDOUT, '>', \$stdout;
            $self->{manager}->{output}->display_disco_show();
            delete $self->{manager}->{output}->{option_results}->{output_xml};
            $self->{manager}->{output}->output_add(severity => 'OK',
                                                   short_msg => $stdout);
        }
    }
}

1;
