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

package storage::hitachi::hcp::snmp::mode::tenants;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

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

sub custom_space_usage_prct_threshold {
    my ($self, %options) = @_;

    my $threshold = $self->{instance_mode}->{option_results}->{'warning-instance-tenant-space-usage-percentage'};
    $threshold = $self->{result_values}->{soft_quota} if (!defined($threshold) || $threshold eq '');
    $self->{perfdata}->threshold_validate(
        label => 'warning-' . $self->{thlabel} . '-' . $self->{result_values}->{instance},
        value => $threshold
    );

    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{prct_used},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel} . '-' . $self->{result_values}->{instance}, exit_litteral => 'warning' }
        ]
    );
}

sub custom_space_usage_prct_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => $self->{result_values}->{name},
        value => sprintf('%.2f', $self->{result_values}->{prct_used}),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel} . '-' . $self->{result_values}->{instance}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        unit => '%',
        min => 0,
        max => 100
    );
}

sub tenant_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking tenant '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_tenant_output {
    my ($self, %options) = @_;

    return sprintf(
        "tenant '%s' ",
        $options{instance_value}->{name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'tenants', type => 3, cb_prefix_output => 'prefix_tenant_output', cb_long_output => 'tenant_long_output',
          indent_long_output => '    ', message_multiple => 'All tenants are ok',
            group => [
                { name => 'space', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{space} = [
         { label => 'space-usage', nlabel => 'tenant.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-free', display_ok => 0, nlabel => 'tenant.space.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-prct', display_ok => 0, nlabel => 'tenant.space.usage.percentage', set => {
                key_values => [
                    { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' },
                    { name => 'soft_quota' }, { name => 'instance' }, { name => 'name' }
                ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                closure_custom_threshold_check => $self->can('custom_space_usage_prct_threshold'),
                closure_custom_perfdata => $self->can('custom_space_usage_prct_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-tenant-name:s' => { name => 'filter_tenant_name' }
    });

    return $self;
}

my $mapping = {
    hard_quota => { oid => '.1.3.6.1.4.1.116.5.46.4.1.1.21' }, # tenantHardQuota (This is the total amount of storage available to the tenant)
    soft_quota => { oid => '.1.3.6.1.4.1.116.5.46.4.1.1.22' }, # tenantSoftQuota (percentage)
    used       => { oid => '.1.3.6.1.4.1.116.5.46.4.1.1.24' }  # tenantPhysicalBytesUsed
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_tenantName = '.1.3.6.1.4.1.116.5.46.4.1.1.2';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_tenantName,
        nothing_quit => 1
    );

    $self->{tenants} = {};
    foreach (keys %$snmp_result) {
        /\.(\d+)$/;
        my $instance = $1;

        if (defined($self->{option_results}->{filter_tenant_name}) && $self->{option_results}->{filter_tenant_name} ne '' &&
            $snmp_result->{$_} !~ /$self->{option_results}->{filter_tenant_name}/) {
            $self->{output}->output_add(long_msg => "skipping tenant '" . $snmp_result->{$_} . "'.", debug => 1);
            next;
        }

        $self->{tenants}->{ $snmp_result->{$_} } = {
            name => $snmp_result->{$_},
            instance => $instance,
            space => {
                name => $snmp_result->{$_},
                instance => $instance
            }
        };
    }

    return if (scalar(keys %{$self->{tenants}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ map($_->{instance}, values(%{$self->{tenants}})) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$self->{tenants}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $self->{tenants}->{$_}->{instance});

        next if (!defined($result->{hard_quota}));

        $self->{tenants}->{$_}->{space}->{soft_quota} = $result->{soft_quota};
        $self->{tenants}->{$_}->{space}->{total} = $result->{hard_quota};
        $self->{tenants}->{$_}->{space}->{free} = $result->{hard_quota} - $result->{used};
        $self->{tenants}->{$_}->{space}->{used} = $result->{used};
        $self->{tenants}->{$_}->{space}->{prct_used} = $result->{used} * 100 / $result->{hard_quota};
        $self->{tenants}->{$_}->{space}->{prct_free} = 100 - $self->{tenants}->{$_}->{space}->{prct_used};
    }
}

1;

__END__

=head1 MODE

Check tenants.

=over 8

=item B<--filter-tenant-name>

Filter tenants by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage-prct', 'space-usage', 'space-usage-free'.

=back

=cut
