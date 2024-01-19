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

package storage::huawei::oceanstor::snmp::mode::luns;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_space_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_space});
    my ($total_prot_value, $total_prot_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{prot_space});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%) protection: %s',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space},
        $total_prot_value . " " . $total_prot_unit
    );
}

sub lun_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking LUN '%s' [sp: %s]",
        $options{instance_value}->{name},
        $options{instance_value}->{storage_pool}
    );
}

sub prefix_lun_output {
    my ($self, %options) = @_;

    return sprintf(
        "LUN '%s' [sp: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{storage_pool}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'lun', type => 3, cb_prefix_output => 'prefix_lun_output', cb_long_output => 'lun_long_output',
          indent_long_output => '    ', message_multiple => 'All LUNs are ok',
            group => [
                #{ name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'space', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{space} = [
         { label => 'space-usage', nlabel => 'lun.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'prot_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-free', nlabel => 'lun.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'prot_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-prct', nlabel => 'lun.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' }, { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'prot_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-prot', nlabel => 'lun.space.prot.bytes', display_ok => 0, set => {
                key_values => [ { name => 'prot_space' },  { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'free_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'            => { name => 'filter_name' },
        'include-non-exposed-luns' => { name => 'include_non_exposed_luns' }
    });

    return $self;
}

my $mapping = {
    name           => { oid => '.1.3.6.1.4.1.34774.4.1.23.4.8.1.2' }, # hwInfoLunName
    storage_pool   => { oid => '.1.3.6.1.4.1.34774.4.1.23.4.8.1.4' }, # hwInfoLunPoolName
    total_space    => { oid => '.1.3.6.1.4.1.34774.4.1.23.4.8.1.5' }, # hwInfoLunCapacity (MB)
    used_space     => { oid => '.1.3.6.1.4.1.34774.4.1.23.4.8.1.6' }, # hwInfoLunSubscribedCapacity (MB)
    prot_space     => { oid => '.1.3.6.1.4.1.34774.4.1.23.4.8.1.7' }, # hwInfoLunProtectionCapacity (KB)
    exposed        => { oid => '.1.3.6.1.4.1.34774.4.1.23.4.8.1.14' } # hwInfoLunExposedToInitiator	
};

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $oid_sp_entry = '.1.3.6.1.4.1.34774.4.1.23.4.8.1'; # hwInfoLunTable
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_sp_entry,
        nothing_quit => 1
    );

    $self->{lun} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping LUN '" . $result->{name} . "'.", debug => 1);
            next;
        }
        
        if (!defined($self->{option_results}->{include_non_exposed_luns}) && $result->{exposed} == 0) {
            $self->{output}->output_add(long_msg => "skipping LUN '" . $result->{name} . "'.", debug => 1);
            next;
        }

        $result->{total_space} *= 1024 * 1024;
        $result->{used_space} *= 1024 * 1024;
        $result->{prot_space} *= 1024;
        $self->{lun}->{ $result->{name} } = {
            name => $result->{name},
            storage_pool => $result->{storage_pool},
            space => $result
        };
        $self->{lun}->{ $result->{name} }->{space}->{free_space} = $result->{total_space} - $result->{used_space};
        $self->{lun}->{ $result->{name} }->{space}->{prct_used_space} = $result->{used_space} * 100 / $result->{total_space};
        $self->{lun}->{ $result->{name} }->{space}->{prct_free_space} = 100 - $result->{used_space};
    }
}

1;

__END__

=head1 MODE

Check LUNs.

=over 8

=item B<--filter-name>

Filter LUN by name (can be a regexp).

=item B<--include-non-exposed-luns>

Include LUN not exposed to an iniator, usually LUN snapshots.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage', 'space-usage-free', 'space-usage-prct'.

=back

=cut
