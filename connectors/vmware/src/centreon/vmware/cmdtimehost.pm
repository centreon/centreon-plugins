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

package centreon::vmware::cmdtimehost;

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'timehost';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{esx_hostname}) && $options{arguments}->{esx_hostname} eq "") {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: esx hostname cannot be null");
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

    if ($self->{connector}->{module_date_parse_loaded} == 0) {
        $self->{manager}->{output}->output_add(severity => 'UNKNOWN',
                                               short_msg => "Need to install Date::Parse CPAN Module");
        return ;
    }
    
    my %filters = ();
    my $multiple = 0;

    if (defined($self->{esx_hostname}) && !defined($self->{filter})) {
        $filters{name} = qr/^\Q$self->{esx_hostname}\E$/;
    } elsif (!defined($self->{esx_hostname})) {
        $filters{name} = qr/.*/;
    } else {
        $filters{name} = qr/$self->{esx_hostname}/;
    }
    my @properties = ('name', 'configManager.dateTimeSystem', 'runtime.connectionState');

    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'HostSystem', properties => \@properties, filter => \%filters);
    return if (!defined($result));

    $self->{manager}->{output}->output_add(severity => 'OK',
                                           short_msg => 'Time Host(s):');
    my @host_array = ();
    foreach my $entity_view (@$result) {
        if (centreon::vmware::common::is_connected(state => $entity_view->{'runtime.connectionState'}->{val}) == 0) {
            $self->{manager}->{output}->output_add(long_msg => sprintf("  '%s' is disconnected", 
                                                                            $entity_view->{name}));
            next;
        }
        if (defined($entity_view->{'configManager.dateTimeSystem'})) {
            push @host_array, $entity_view->{'configManager.dateTimeSystem'};
        }
    }
    
    @properties = ();
    my $result2 = centreon::vmware::common::get_views($self->{connector}, \@host_array, \@properties);
    return if (!defined($result2));
    
    foreach my $entity_view (@$result) {
        my $host_dts_value = $entity_view->{'configManager.dateTimeSystem'}->{value};
        foreach my $host_dts_view (@$result2) {
            if ($host_dts_view->{mo_ref}->{value} eq $host_dts_value) {
                my $time = $host_dts_view->QueryDateTime();
                my $timestamp = Date::Parse::str2time($time);
                $self->{manager}->{output}->output_add(long_msg => sprintf("  '%s': unix timestamp %s, date: %s", 
                                                                            $entity_view->{name}, $timestamp, $time));
                last;
            }
        }
    }
}

1;
