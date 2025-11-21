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

package centreon::vmware::cmdnethost;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;

    $self->{commandName} = 'nethost';

    return $self;
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{esx_hostname}) && $options{arguments}->{esx_hostname} eq '') {
        centreon::vmware::common::set_response(code => 100, short_message => 'Argument error: esx hostname cannot be null');
        return 1;
    }

    return 0;
}

sub run {
    my $self = shift;

    if (!($self->{connector}->{perfcounter_speriod} > 0)) {
        centreon::vmware::common::set_response(code => -1, short_message => "Can't retrieve perf counters");
        return ;
    }

    my $number_nic = 0;
    my $filters = $self->build_filter(label => 'name', search_option => 'esx_hostname', is_regexp => 'filter');
    my @properties = ('name', 'config.network.pnic', 'runtime.connectionState', 'config.network.vswitch');
    if (!defined($self->{no_proxyswitch})) {
        push @properties, 'config.network.proxySwitch';
    }
    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'HostSystem', properties => \@properties, filter => $filters);
    return if (!defined($result));

    my $data = {};
    my $pnic_def_up = {};
    my $query_perfs = [];
    foreach my $entity_view (@$result) {
        my $entity_value = $entity_view->{mo_ref}->{value};
        $data->{$entity_value} = { name => $entity_view->{name}, state => $entity_view->{'runtime.connectionState'}->val, 
            pnic => { }, vswitch => { }, proxyswitch => {} };
        next if ($entity_view->{'runtime.connectionState'}->val !~ /^connected$/i);

        $pnic_def_up->{$entity_value} = {};
        my $instances = [];

        # Get Name from vswitch
        if (defined($entity_view->{'config.network.vswitch'})) {
            foreach (@{$entity_view->{'config.network.vswitch'}}) {
                $data->{$entity_value}->{vswitch}->{$_->{name}} = { pnic => [] };
                next if (!defined($_->{pnic}));
                push @{$data->{$entity_value}->{vswitch}->{$_->{name}}->{pnic}}, @{$_->{pnic}};
            }
        }
        # Get Name from proxySwitch
        if (defined($entity_view->{'config.network.proxySwitch'})) {
            foreach (@{$entity_view->{'config.network.proxySwitch'}}) {
                my $name = defined($_->{name}) ? $_->{name} : $_->{key};
                $data->{$entity_value}->{proxyswitch}->{$name} = { pnic => [] };
                next if (!defined($_->{pnic}));
                push @{$data->{$entity_value}->{proxyswitch}->{$name}->{pnic}}, @{$_->{pnic}};
            }
        }

        foreach (@{$entity_view->{'config.network.pnic'}}) {
            $data->{$entity_value}->{pnic}->{$_->device} = { speed => undef, status => 'down', key => $_->{key} };

            $number_nic++;
            if (defined($_->linkSpeed)) {
                $data->{$entity_value}->{pnic}->{$_->device}->{speed} = $_->linkSpeed->speedMb;
                $data->{$entity_value}->{pnic}->{$_->device}->{status} = 'up';
                
                $pnic_def_up->{$entity_value}->{$_->device} = $_->linkSpeed->speedMb;
                push @$instances, $_->device;
            }
        }

        push @$query_perfs, {
            entity => $entity_view,
            metrics => [ 
                {label => 'net.received.average', instances => $instances},
                {label => 'net.transmitted.average', instances => $instances},
                {label => 'net.droppedRx.summation', instances => $instances},
                {label => 'net.droppedTx.summation', instances => $instances},
                {label => 'net.packetsRx.summation', instances => $instances},
                {label => 'net.packetsTx.summation', instances => $instances}
            ]
        };
    }  

    # Nothing to retrieve. problem before already.
    return if (scalar(@$query_perfs) == 0);

    my $values = centreon::vmware::common::generic_performance_values_historic(
        $self->{connector},
        undef, 
        $query_perfs,
        $self->{connector}->{perfcounter_speriod},
        sampling_period => $self->{sampling_period}, time_shift => $self->{time_shift},
        skip_undef_counter => 1, multiples => 1, multiples_result_by_entity => 1
    );
    return if (centreon::vmware::common::performance_errors($self->{connector}, $values) == 1);

    foreach my $entity_view (@$result) {
        my $entity_value = $entity_view->{mo_ref}->{value};

        foreach (sort keys %{$pnic_def_up->{$entity_value}}) {
            # KBps
            my $traffic_in = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'net.received.average'}->{key} . ":" . $_})) * 1024 * 8;    
            my $traffic_out = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'net.transmitted.average'}->{key} . ":" . $_})) * 1024 * 8;
            my $packets_in = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'net.packetsRx.summation'}->{key} . ":" . $_}));    
            my $packets_out = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'net.packetsTx.summation'}->{key} . ":" . $_}));
            my $dropped_in = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'net.droppedRx.summation'}->{key} . ":" . $_}));    
            my $dropped_out = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'net.droppedTx.summation'}->{key} . ":" . $_}));

            $data->{$entity_value}->{pnic}->{$_}->{'net.received.average'} = $traffic_in;
            $data->{$entity_value}->{pnic}->{$_}->{'net.transmitted.average'} = $traffic_out;
            $data->{$entity_value}->{pnic}->{$_}->{'net.packetsRx.summation'} = $packets_in;
            $data->{$entity_value}->{pnic}->{$_}->{'net.packetsTx.summation'} = $packets_out;
            $data->{$entity_value}->{pnic}->{$_}->{'net.droppedRx.summation'} = $dropped_in;
            $data->{$entity_value}->{pnic}->{$_}->{'net.droppedTx.summation'} = $dropped_out;
        }
    }

    centreon::vmware::common::set_response(data => $data);
}

1;
