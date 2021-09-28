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

package storage::huawei::oceanstor::snmp::mode::storagepools;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use storage::huawei::oceanstor::snmp::mode::resources qw($health_status $running_status);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'health status: %s [running status: %s]',
        $self->{result_values}->{health_status},
        $self->{result_values}->{running_status}
    );
}

sub custom_space_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_space});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space}
    );
}

sub sp_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking storage pool '%s' [domain: %s]",
        $options{instance_value}->{name},
        $options{instance_value}->{domain_name}
    );
}

sub prefix_sp_output {
    my ($self, %options) = @_;

    return sprintf(
        "storage pool '%s' [domain: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{domain_name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'sp', type => 3, cb_prefix_output => 'prefix_sp_output', cb_long_output => 'sp_long_output',
          indent_long_output => '    ', message_multiple => 'All storage pools are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'space', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{health_status} =~ /degraded|partially broken/i',
            critical_default => '%{health_status} =~ /fault|fail/i',
            set => {
                key_values => [ { name => 'health_status' }, { name => 'running_status' }, { name => 'id' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{space} = [
         { label => 'space-usage', nlabel => 'storage_pool.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-free', nlabel => 'storage_pool.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-prct', nlabel => 'storage_pool.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' }, { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
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
        'filter-name:s'        => { name => 'filter_name' },
        'filter-domain-name:s' => { name => 'filter_domain_name' }
    });

    return $self;
}

my $mapping = {
    domain_name    => { oid => '.1.3.6.1.4.1.34774.4.1.23.4.2.1.4' }, # hwInfoStoragePoolDiskDomainName
    health_status  => { oid => '.1.3.6.1.4.1.34774.4.1.23.4.2.1.5', map => $health_status }, # hwInfoStoragePoolHealthStatus
    running_status => { oid => '.1.3.6.1.4.1.34774.4.1.23.4.2.1.6', map => $running_status }, # hwInfoStoragePoolRunningStatus
    total_space    => { oid => '.1.3.6.1.4.1.34774.4.1.23.4.2.1.7' }, # hwInfoStoragePoolTotalCapacity (MB)
    free_space     => { oid => '.1.3.6.1.4.1.34774.4.1.23.4.2.1.9' }  # hwInfoStoragePoolFreeCapacity (MB)
};

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $oid_sp_name = '.1.3.6.1.4.1.34774.4.1.23.4.2.1.2'; # hwInfoStoragePoolName
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_sp_name,
        nothing_quit => 1
    );

    $self->{sp} = {};
    foreach (keys %$snmp_result) {
        /^$oid_sp_name\.(.*)$/;
        my $instance = $1;

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$_} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping storage pool '" . $snmp_result->{$_} . "'.", debug => 1);
            next;
        }

        $self->{sp}->{ $snmp_result->{$_} } = {
            name => $snmp_result->{$_},
            instance => $instance
        };
    }

    return if (scalar(keys %{$self->{sp}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ map($_->{instance}, values(%{$self->{sp}})) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$self->{sp}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $self->{sp}->{$_}->{instance});

        if (defined($self->{option_results}->{filter_domain_name}) && $self->{option_results}->{filter_domain_name} ne '' &&
            $result->{domain_name} !~ /$self->{option_results}->{filter_domain_name}/) {
            $self->{output}->output_add(long_msg => "skipping storage pool '" . $_ . "'.", debug => 1);
            next;
        }

        $self->{sp}->{$_}->{domain_name} = $result->{domain_name};
        $result->{total_space} *= 1024 * 1024;
        $result->{free_space} *= 1024 * 1024;
        $self->{sp}->{$_}->{space} = {
            name => $_,
            total_space => $result->{total_space},
            used_space => $result->{total_space} - $result->{free_space},
            free_space => $result->{free_space},
            prct_used_space => 100 - ($result->{free_space} * 100 / $result->{total_space}),
            prct_free_space => ($result->{free_space} * 100 / $result->{total_space})
        };
        $self->{sp}->{$_}->{status} = {
            running_status => $result->{running_status},
            health_status => $result->{health_status},
            name => $_,
            domain_name => $result->{domain_name}
        };
    }
}

1;

__END__

=head1 MODE

Check storage pools.

=over 8

=item B<--filter-name>

Filter storage pool by name (can be a regexp).

=item B<--filter-domain-name>

Filter storage pool by domain name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{health_status}, %{running_status}, %{name}

=item B<--warning-status>

Set warning threshold for status (Default: '%{health_status} =~ /degraded|partially broken/i').
Can used special variables like: %{health_status}, %{running_status}, %{name}

=item B<--critical-status>

Set critical threshold for status (Default: '%{health_status} =~ /fault|fail/i').
Can used special variables like: %{health_status}, %{running_status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage', 'space-usage-free', 'space-usage-prct'.

=back

=cut
