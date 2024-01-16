#
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
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package network::enterasys::snmp::mode::storage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'total: %s %s used: %s %s (%.2f%%) free: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free}
    );
}

sub prefix_storage_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "Storage '%s' [%s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{physicalName}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'storage', type => 1, cb_prefix_output => 'prefix_storage_output', message_multiple => 'All storages are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{storage} = [
        { label => 'usage', display_ok => 0, nlabel => 'storage.space.usage.bytes', set => {
                key_values => [
                    { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' },
                    { name => 'physicalName' }, { name => 'name'}
                ],
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'B',
                        instances => [$self->{result_values}->{physicalName}, $self->{result_values}->{name}],
                        value => $self->{result_values}->{used},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0,
                        max => $self->{result_values}->{total}
                    );
                }
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'storage.space.free.bytes', set => {
                key_values => [
                    { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' },
                    { name => 'physicalName' }, { name => 'name'}
                ],
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'B',
                        instances => [$self->{result_values}->{physicalName}, $self->{result_values}->{name}],
                        value => $self->{result_values}->{free},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0,
                        max => $self->{result_values}->{total}
                    );
                }
            }
        },
        { label => 'usage-prct', nlabel => 'storage.space.usage.percentage', set => {
                key_values => [
                    { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' },
                    { name => 'physicalName' }, { name => 'name'}
                ],
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => '%',
                        instances => [$self->{result_values}->{physicalName}, $self->{result_values}->{name}],
                        value => sprintf('%.2f', $self->{result_values}->{prct_used}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0,
                        max => 100
                    );
                }
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-entity-name:s'  => { name => 'filter_entity_name' },
        'filter-storage-name:s' => { name => 'filter_storage_name' }
    });

    return $self;
}

my $mapping = {
    descr => { oid => '.1.3.6.1.4.1.5624.1.2.49.1.3.1.1.3' }, # etsysResourceStorageDescr (KB)
    total => { oid => '.1.3.6.1.4.1.5624.1.2.49.1.3.1.1.4' }, # etsysResourceStorageSize (KB)
    free  => { oid => '.1.3.6.1.4.1.5624.1.2.49.1.3.1.1.5' }  # etsysResourceStorageAvailable (KB)
};
my $oid_etsysResourceStorageTable = '.1.3.6.1.4.1.5624.1.2.49.1.3.1';
my $oid_entPhysicalName = '.1.3.6.1.2.1.47.1.1.1.1.7';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_etsysResourceStorageTable,
        nothing_quit => 1
    );

    $self->{storage} = {};
    my $indexes = {};
    foreach (keys %$snmp_result) {
        next if (! /^$mapping->{total}->{oid}\.(\d+).(\d+)\.(\d+)$/);
        my ($physicalIndex, $type) = ($1, $2);
        my $instance = $1 . '.' . $2 . '.' . $3;

        next if ($type == 2); # 2 = ram

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        next if ($result->{total} <= 0);

        next if (defined($self->{option_results}->{filter_storage_name}) && $self->{option_results}->{filter_storage_name} ne '' &&
            $result->{descr} !~ /$self->{option_results}->{filter_storage_name}/);

        $options{snmp}->load(oids => [ $oid_entPhysicalName . '.' . $physicalIndex ]) if (!defined($indexes->{$physicalIndex}));
        $indexes->{$physicalIndex} = 1;

        $result->{total} *= 1024;
        $result->{free} *= 1024;
        $self->{storage}->{ $result->{descr} } = {
            physicalIndex => $physicalIndex,
            name => $result->{descr},
            used => $result->{total} - $result->{free},
            free => $result->{free},
            prct_used => ($result->{total} - $result->{free}) * 100 / $result->{total},
            prct_free => $result->{free} * 100 / $result->{total},
            total => $result->{total}
        };
    }

    if (scalar(keys %$indexes) > 0) {
        $snmp_result = $options{snmp}->get_leef();
        foreach (keys %{$self->{storage}}) {
            my $entity_name = $snmp_result->{ $oid_entPhysicalName . '.' . $self->{storage}->{$_}->{physicalIndex} };
            if (defined($self->{option_results}->{filter_entity_name}) && $self->{option_results}->{filter_entity_name} ne '' &&
                $entity_name !~ /$self->{option_results}->{filter_entity_name}/) {
                delete $self->{storage}->{$_};
                next;
            }
            $self->{storage}->{$_}->{physicalName} = $entity_name;
        }
    }
}

1;

__END__

=head1 MODE

Check storages.

=over 8

=item B<--filter-entity-name>

Filter entity name (can be a regexp).

=item B<--filter-storage-name>

Filter storage name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
