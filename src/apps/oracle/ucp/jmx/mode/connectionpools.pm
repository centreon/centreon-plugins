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

package apps::oracle::ucp::jmx::mode::connectionpools;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => $self->{result_values}->{poolName},
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => $self->{result_values}->{total} > 0 ? $self->{result_values}->{total} : undef
    );
}

sub custom_usage_free_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => $self->{result_values}->{poolName},
        value => $self->{result_values}->{free},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => $self->{result_values}->{total}
    );
}

sub custom_usage_prct_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => '%',
        instances => $self->{result_values}->{poolName},
        value => sprintf('%.2f', $self->{result_values}->{prct_used}),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0, max => 100
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{used}, threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' },
        ]
    );
}

sub custom_usage_free_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{free}, threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
}

sub custom_usage_prct_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{prct_used}, threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my $msg;
    if ($self->{result_values}->{total} <= 0) {
        $msg = sprintf("used: %s (unlimited)", $self->{result_values}->{used});
    } else {
        $msg = sprintf(
            "total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
            $self->{result_values}->{total},
            $self->{result_values}->{used}, $self->{result_values}->{prct_used},
            $self->{result_values}->{free}, $self->{result_values}->{prct_free}
        );
    }

    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{poolName} = $options{new_datas}->{$self->{instance} . '_poolName'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};

    if ($self->{result_values}->{total} == 0) {
        return -10 if ($options{extra_options}->{label} ne 'usage');
        return 0;
    }

    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    
    return 0;
}

sub prefix_pool_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "Connection pool '%s' ",
        $options{instance_value}->{poolName}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'pools', type => 1, cb_prefix_output => 'prefix_pool_output', message_multiple => 'All connection pools are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{pools} = [
         { label => 'usage', nlabel => 'connection_pool.usage.count', set => {
                key_values => [
                    { name => 'poolName' }, { name => 'used' }, { name => 'total' }
                ],
                closure_custom_calc_extra_options => { label => 'usage' },
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata')
            }
        },
        { label => 'usage-free', nlabel => 'connection_pool.free.count', display_ok => 0, set => {
                key_values => [
                    { name => 'poolName' }, { name => 'used' }, { name => 'total' }
                ],
                closure_custom_calc_extra_options => { label => 'free' },
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_threshold_check => $self->can('custom_usage_free_threshold'),
                closure_custom_perfdata => $self->can('custom_usage_free_perfdata')
            }
        },
        { label => 'usage-prct', nlabel => 'connection_pool.usage.percentage', display_ok => 0, set => {
                key_values => [ 
                    { name => 'poolName' }, { name => 'used' }, { name => 'total' }
                ],
                closure_custom_calc_extra_options => { label => 'prct' },
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_threshold_check => $self->can('custom_usage_prct_threshold'),
                closure_custom_perfdata => $self->can('custom_usage_prct_perfdata')
            }
        }
    ];
}


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-pool-name:s' => { name => 'filter_pool_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $request = [
        { mbean => "oracle.ucp.admin.UniversalConnectionPoolMBean:name=UniversalConnectionPoolManager*,poolName=*", attributes => 
            [ { name => 'remainingPoolCapacityCount' }, { name => 'totalConnectionsCount' }, { name => 'maxPoolSize' } ] }
    ];

    my $result = $options{custom}->get_attributes(request => $request, nothing_quit => 1);

    $self->{pools} = {};
    foreach my $key (keys %$result) {
        $key =~ /(?:[:,])poolName=(.*?)(?:,|$)/;
        my $poolName = $1;

        next if (defined($self->{option_results}->{filter_pool_name}) && $self->{option_results}->{filter_pool_name} ne '' &&
            $poolName !~ /$self->{option_results}->{filter_pool_name}/);

        $self->{pools}->{$poolName} = {
            poolName => $poolName,
            used => $result->{$key}->{totalConnectionsCount},
            total => defined($result->{$key}->{maxPoolSize}) ? $result->{$key}->{maxPoolSize} : 0
        };
    }

    if (scalar(keys %{$self->{pools}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No connection pools found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check connection pools.

=over 8

=item B<--filter-pool-name>

Filter connection pools by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage', 'usage-free', 'usage-prct'.

=back

=cut
