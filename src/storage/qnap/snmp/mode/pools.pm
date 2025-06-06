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

package storage::qnap::snmp::mode::pools;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status: %s",
        $self->{result_values}->{status}
    );
}

sub custom_space_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        "space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub pool_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking pool '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_pool_output {
    my ($self, %options) = @_;

    return sprintf(
        "pool '%s' ",
        $options{instance_value}->{name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'pools', type => 3, cb_prefix_output => 'prefix_pool_output', cb_long_output => 'pool_long_output',
          indent_long_output => '    ', message_multiple => 'All pools are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'space', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'pool-status',
            type => 2,
            warning_default => '%{status} =~ /degraded|warning/i',
            critical_default => '%{status} =~ /error|critical/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'name' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{space} = [
         { label => 'space-usage', nlabel => 'pool.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'space-usage-free', display_ok => 0, nlabel => 'pool.space.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'space-usage-prct', display_ok => 0, nlabel => 'pool.space.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'name' }
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
        'filter-name:s'   => { name => 'filter_name' }
    });

    return $self;
}

sub convert_bytes {
    my ($self, %options) = @_;
    my $multiple = defined($options{network}) ? 1000 : 1024;
    my %units = (K => 1, M => 2, G => 3, T => 4);
    
    if ($options{value} !~ /^\s*([0-9\.\,]+)\s*(.)/) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            output => "Cannot convert value '" . $options{value} . "'"
        );
        $self->{output}->display();
        $self->{output}->exit();
    }
    my ($bytes, $unit) = ($1, uc($2));
    
    for (my $i = 0; $i < $units{$unit}; $i++) {
        $bytes *= $multiple;
    }

    return $bytes;
}

my $map_status = {
    0 => 'ready',
    -1 => 'warning',
    -2 => 'notReady',
    -3 => 'error'
};

my $mapping = {
    ex => {
        name   => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.2.2.2.1.2' }, # poolID
        total  => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.2.2.2.1.3' }, # poolCapacity
        free   => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.2.2.2.1.4' }, # poolFreeSize
        status => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.2.2.2.1.5', map => $map_status }  # poolStatus
    },
    es => {
        name   => { oid => '.1.3.6.1.4.1.24681.2.2.23.1.2' }, # es-SysPoolID
        total  => { oid => '.1.3.6.1.4.1.24681.2.2.23.1.3' }, # es-SysPoolCapacity
        free   => { oid => '.1.3.6.1.4.1.24681.2.2.23.1.4' }, # es-SysPoolFreeSize
        status => { oid => '.1.3.6.1.4.1.24681.2.2.23.1.5' }  # es-SysPoolStatus
    },
    quts => {
        name   => { oid => '.1.3.6.1.4.1.55062.2.10.7.1.2' }, # es-SysPoolID
        total  => { oid => '.1.3.6.1.4.1.55062.2.10.7.1.3' }, # es-SysPoolCapacity
        free   => { oid => '.1.3.6.1.4.1.55062.2.10.7.1.4' }, # es-SysPoolFreeSize
        status => { oid => '.1.3.6.1.4.1.55062.2.10.7.1.5', , map => $map_status }  # es-SysPoolStatus
    }
};

sub check_pools {
    my ($self, %options) = @_;

    return 0 if (scalar(keys %{$options{snmp_result}}) <= 0);

    foreach (keys %{$options{snmp_result}}) {
        next if (! /^$mapping->{ $options{type} }->{name}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping->{ $options{type} }, results => $options{snmp_result}, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping pool $result->{name}", debug => 1);
            next;
        }

        if ($options{type} ne "quts" && defined($options{convert})) {
            $result->{total} = $self->convert_bytes(value => $result->{total});
            $result->{free} = $self->convert_bytes(value => $result->{free});
        }

        $self->{pools}->{$instance} = {
            name   => $result->{name},
            status => {
                name => $result->{name},
                status => $result->{status}
            }
        };
        if (defined($result->{total}) && $result->{total} > 0) {
            $self->{pools}->{$instance}->{space} = {
                name => $result->{name},
                total => $result->{total},
                free  => $result->{free},
                used  => $result->{total} - $result->{free},
                prct_free => $result->{free} * 100 / $result->{total},
                prct_used => ($result->{total} - $result->{free}) * 100 / $result->{total}
            };
        }
    }

    return 1;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{pools} = {};

    my $snmp_result = $options{snmp}->get_table(
        oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.2.2.2' # poolTable
    );
    return if ($self->check_pools(snmp => $options{snmp}, type => 'ex', snmp_result => $snmp_result));

    $snmp_result = $options{snmp}->get_table(
        oid => '.1.3.6.1.4.1.55062.2.10.7', # QuTS hero storagePoolTable
        nothing_quit => 1
    );
    return if $self->check_pools(snmp => $options{snmp}, type => 'quts', snmp_result => $snmp_result, convert => 1);

    $snmp_result = $options{snmp}->get_table(
        oid => '.1.3.6.1.4.1.24681.2.2.23', # es-SystemPoolTable
        nothing_quit => 1
    );
    $self->check_pools(snmp => $options{snmp}, type => 'es', snmp_result => $snmp_result, convert => 1);
}

1;

__END__

=head1 MODE

Check pools.

=over 8

=item B<--filter-name>

Filter pools by name (can be a regexp).

=item B<--unknown-pool-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{name}

=item B<--warning-pool-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /degraded|warning/i').
You can use the following variables: %{status}, %{name}

=item B<--critical-pool-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /error|critical/i').
You can use the following variables: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage-prct', 'space-usage', 'space-usage-free'.

=back

=cut
    
