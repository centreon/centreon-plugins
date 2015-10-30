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

package centreon::vmware::cmddatastoreio;

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'datastoreio';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{datastore_name}) && $options{arguments}->{datastore_name} eq "") {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: datastore name cannot be null");
        return 1;
    }
    if (defined($options{arguments}->{disconnect_status}) && 
        $options{manager}->{output}->is_litteral_status(status => $options{arguments}->{disconnect_status}) == 0) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: wrong value for disconnect status '" . $options{arguments}->{disconnect_status} . "'");
        return 1;
    }
    foreach my $label (('warning', 'critical')) {
        if (($options{manager}->{perfdata}->threshold_validate(label => $label, value => $options{arguments}->{$label})) == 0) {
            $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                    short_msg => "Argument error: wrong value for $label value '" . $options{arguments}->{$label} . "'.");
            return 1;
        }
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
    foreach my $label (('warning', 'critical')) {
        $self->{manager}->{perfdata}->threshold_validate(label => $label, value => $options{arguments}->{$label});
    }
}

sub set_connector {
    my ($self, %options) = @_;
    
    $self->{connector} = $options{connector};
}

sub run {
    my $self = shift;

    if (!($self->{connector}->{perfcounter_speriod} > 0)) {
        $self->{manager}->{output}->output_add(severity => 'UNKNOWN',
                                               short_msg => "Can't retrieve perf counters");
        return ;
    }
    
    my %filters = ();
    my $multiple = 0;
    if (defined($self->{datastore_name}) && !defined($self->{filter})) {
        $filters{name} = qr/^\Q$self->{datastore_name}\E$/;
    } elsif (!defined($self->{datastore_name})) {
        $filters{name} = qr/.*/;
    } else {
        $filters{name} = qr/$self->{datastore_name}/;
    }
    my @properties = ('summary.name', 'summary.accessible');
    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'Datastore', properties => \@properties, filter => \%filters);
    return if (!defined($result));
    
    my $values = centreon::vmware::common::generic_performance_values_historic($self->{connector},
                        $result, 
                        [{'label' => 'datastore.read.average', 'instances' => ['']},
                         {'label' => 'datastore.write.average', 'instances' => ['']}],
                        $self->{connector}->{perfcounter_speriod},
                        sampling_period => $self->{sampling_period}, time_shift => $self->{time_shift},
                        skip_undef_counter => 1, multiples => 1, multiples_result_by_entity => 1);
    return if (centreon::vmware::common::performance_errors($self->{connector}, $values) == 1);
    
    if (scalar(@$result) > 1) {
        $multiple = 1;
    }
    if ($multiple == 1) {
        $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => sprintf("All datastore rates are ok"));
    }
    
    foreach my $entity_view (@$result) {
        next if (centreon::vmware::common::datastore_state(connector => $self->{connector},
                                                         name => $entity_view->{'summary.name'}, 
                                                         state => $entity_view->{'summary.accessible'},
                                                         status => $self->{disconnect_status},
                                                         multiple => $multiple) == 0);
        my $entity_value = $entity_view->{mo_ref}->{value};
    
        # in KBps
        my $read_counter = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'datastore.read.average'}->{'key'} . ":"})) * 1024;    
        my $write_counter = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'datastore.write.average'}->{'key'} . ":"})) * 1024;

        my $exit1 = $self->{manager}->{perfdata}->threshold_check(value => $read_counter, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        my $exit2 = $self->{manager}->{perfdata}->threshold_check(value => $write_counter, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        my $exit = $self->{manager}->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
        my ($read_value, $read_unit) = $self->{manager}->{perfdata}->change_bytes(value => $read_counter);
        my ($write_value, $write_unit) = $self->{manager}->{perfdata}->change_bytes(value => $write_counter);
        
        $self->{manager}->{output}->output_add(long_msg => sprintf("'%s' Rate of reading data: %s Rate of writing data: %s", 
                                            $entity_view->{'summary.name'},
                                            $read_value . " " . $read_unit . "/s",
                                            $write_value . " " . $write_unit . "/s"));
        if ($multiple == 0 ||
            !$self->{manager}->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
             $self->{manager}->{output}->output_add(severity => $exit,
                                                    short_msg => sprintf("'%s' Rate of reading data: %s Rate of writing data: %s", 
                                            $entity_view->{'summary.name'},
                                            $read_value . " " . $read_unit . "/s",
                                            $write_value . " " . $write_unit . "/s"));
        }
        
        my $extra_label = '';
        $extra_label = '_' . $entity_view->{'summary.name'} if ($multiple == 1);
        $self->{manager}->{output}->perfdata_add(label => 'read_rate' . $extra_label, unit => 'B/s',
                                                 value => $read_counter,
                                                 warning => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                                 critical => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                                 min => 0);
        $self->{manager}->{output}->perfdata_add(label => 'write_rate' . $extra_label, unit => 'B/s',
                                                 value => $write_counter,
                                                 warning => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                                 critical => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                                 min => 0);
    }
}

1;
