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

package centreon::common::h3c::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::statefile;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    if ($self->{result_values}->{total} == 4294967295) {
        $self->{output}->perfdata_add(
            label => 'used', unit => '%',
            nlabel => 'memory.usage.percentage',
            instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
            value => $self->{result_values}->{prct_used},
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
            min => 0, max => 100
        );
    } else {
        $self->{output}->perfdata_add(
            label => 'used', unit => 'B',
            nlabel => $self->{nlabel},
            instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
            value => int($self->{result_values}->{used}),
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
            min => 0, max => $self->{result_values}->{total}
        );
    }
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct_used}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my $msg;
    if ($self->{result_values}->{total} == 4294967295) {
        $msg = sprintf("Used: %.2f%% Free: %.2f%%",
                      $self->{result_values}->{prct_used},
                      $self->{result_values}->{prct_free});
    } else {
        my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
        my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
        my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
        $msg = sprintf("Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                      $total_size_value . " " . $total_size_unit,
                      $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                      $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    }
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_total'} * $options{new_datas}->{$self->{instance} . '_used_prct'} / 100;
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_total'} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = 100 - $options{new_datas}->{$self->{instance} . '_used_prct'};
    $self->{result_values}->{prct_used} = $options{new_datas}->{$self->{instance} . '_used_prct'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'memory', type => 1, cb_prefix_output => 'prefix_memory_output', message_multiple => 'All memory usages are ok' }
    ];
    
    $self->{maps_counters}->{memory} = [
        { label => 'usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'display' }, { name => 'used_prct' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub prefix_memory_output {
    my ($self, %options) = @_;
    
    return "Memory '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "reload-cache-time:s"     => { name => 'reload_cache_time', default => 180 },
        "display-entity-name"     => { name => 'display_entity_name' },
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->{statefile_cache}->check_options(%options);
}

my $oid_entPhysicalEntry = '.1.3.6.1.2.1.47.1.1.1.1';
my $oid_entPhysicalDescr = '.1.3.6.1.2.1.47.1.1.1.1.2';
my $oid_entPhysicalContainedIn = '.1.3.6.1.2.1.47.1.1.1.1.4';
my $oid_entPhysicalClass = '.1.3.6.1.2.1.47.1.1.1.1.5';
my $oid_entPhysicalName = '.1.3.6.1.2.1.47.1.1.1.1.7';

sub check_cache {
    my ($self, %options) = @_;

    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();
    
    # init cache file
    $self->{write_cache} = 0;
    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_h3c_entity_' . $self->{hostname}  . '_' . $self->{snmp_port});
    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    if ($has_cache_file == 0 ||
        !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60))) {
        push @{$self->{snmp_request}}, { oid => $oid_entPhysicalEntry, start => $oid_entPhysicalDescr, end => $oid_entPhysicalName };
        $self->{write_cache} = 1;
    }
}

sub write_cache {
    my ($self, %options) = @_;
    
    if ($self->{write_cache} == 1) {
        my $datas = {};
        $datas->{last_timestamp} = time();
        $datas->{oids} = $self->{results}->{$oid_entPhysicalEntry};
        $self->{statefile_cache}->write(data => $datas);
    } else {
        $self->{results}->{$oid_entPhysicalEntry} = $self->{statefile_cache}->get(name => 'oids');
    }
}

sub get_long_name {
    my ($self, %options) = @_;
    
    my @names = ($self->{results}->{$oid_entPhysicalEntry}->{$oid_entPhysicalDescr . '.' . $options{instance}});
    my %loop = ($options{instance} => 1);
    my $child = $self->{results}->{$oid_entPhysicalEntry}->{$oid_entPhysicalContainedIn . '.' . $options{instance}};
    while (1) {
        last if (!defined($child) || defined($loop{$child}) || !defined($self->{results}->{$oid_entPhysicalEntry}->{$oid_entPhysicalDescr . '.' . $child}));
        
        unshift @names, $self->{results}->{$oid_entPhysicalEntry}->{$oid_entPhysicalDescr . '.' . $child};
        $loop{$child} = 1;
        $child = $self->{results}->{$oid_entPhysicalEntry}->{$oid_entPhysicalContainedIn . '.' . $child};
    }
    
    return join(' > ', @names);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    my $oid_h3cEntityExtStateEntry = '.1.3.6.1.4.1.2011.10.2.6.1.1.1.1';
    my $oid_hh3cEntityExtStateEntry = '.1.3.6.1.4.1.25506.2.6.1.1.1.1';
    my $oid_hh3cEntityExtMemUsage = '.1.3.6.1.4.1.25506.2.6.1.1.1.1.8';
    my $oid_hh3cEntityExtMemSize = '.1.3.6.1.4.1.25506.2.6.1.1.1.1.10';
    my $oid_h3cEntityExtMemUsage = '.1.3.6.1.4.1.2011.10.2.6.1.1.1.1.8';
    my $oid_h3cEntityExtMemSize = '.1.3.6.1.4.1.2011.10.2.6.1.1.1.1.10';

    $self->{snmp_request} = [ 
        { oid => $oid_hh3cEntityExtMemUsage },
        { oid => $oid_hh3cEntityExtMemSize },
        { oid => $oid_h3cEntityExtMemUsage },
        { oid => $oid_h3cEntityExtMemSize },
    ];
    $self->check_cache() if (defined($self->{option_results}->{display_entity_name}));

    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{snmp_request},
                                                         nothing_quit => 1);
    $self->write_cache() if (defined($self->{option_results}->{display_entity_name}));
    $self->{branch} = $oid_hh3cEntityExtStateEntry;
    if (defined($self->{results}->{$oid_h3cEntityExtMemUsage}) && scalar(keys %{$self->{results}->{$oid_h3cEntityExtMemUsage}}) > 0) {
        $self->{branch} = $oid_h3cEntityExtStateEntry;
    }
    
    my $mapping = {
        EntityExtMemUsage => { oid => $self->{branch} . '.8' },
    };
    my $mapping2 = {
        EntityExtMemSize => { oid => $self->{branch} . '.10' },
    };
    
    $self->{memory} = {};
    foreach my $oid (keys %{$self->{results}->{$self->{branch} . '.8'}}) {
        next if ($oid !~ /^$self->{branch}\.8\.(\d+)/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$self->{branch} . '.8'}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$self->{branch} . '.10'}, instance => $instance);        
        
        if (defined($result2->{EntityExtMemSize}) && $result2->{EntityExtMemSize} > 0) {
            my $name = '-';
            
            if (defined($self->{option_results}->{display_entity_name})) {
                $name = $self->get_long_name(instance => $instance);
            }
            $self->{memory}->{$instance} = { 
                display => $instance, name => $name, 
                used_prct => $result->{EntityExtMemUsage},
                total => $result2->{EntityExtMemSize}
            };
        }
    }
    
    if (scalar(keys %{$self->{memory}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check memory usages.

=over 8

=item B<--warning-usage>

Threshold warning (in percent).

=item B<--critical-usage>

Threshold critical (in percent).

=item B<--reload-cache-time>

Time in seconds before reloading cache file (default: 180).

=item B<--display-entity-name>

Display entity name of the component. A cache file will be used.

=back

=cut
