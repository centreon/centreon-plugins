#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package storage::exagrid::snmp::mode::serverusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;
    
    return 'Server Status : ' . $self->{result_values}->{status};
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    my %total_options = ( total => $self->{result_values}->{total}, cast_int => 1);

    $self->{output}->perfdata_add(
        label => $self->{result_values}->{label} . '_' . $label, unit => 'B',
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options),
        min => 0,
        max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct_used}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        '%s Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)',
        ucfirst($self->{result_values}->{label}),
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_' . $self->{result_values}->{label} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_' . $self->{result_values}->{label} . '_used'};

    if ($self->{result_values}->{total} != 0) {
        $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
        $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
        $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    } else {
        $self->{result_values}->{free} = 0;
        $self->{result_values}->{prct_used} = 0;
        $self->{result_values}->{prct_free} = 0;
    }
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'server', type => 0, message_separator => ' - ' }
    ];
    
    $self->{maps_counters}->{server} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{status} =~ /warning/i',
            critical_default => '%{status} =~ /error/i',
            set => {
                key_values => [ { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'landing-usage', set => {
                key_values => [ { name => 'landing_used' }, { name => 'landing_total' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'landing' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold')
            }
        },
        { label => 'retention-usage', set => {
                key_values => [ { name => 'retention_used' }, { name => 'retention_total' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'retention' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold')
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
    
    return $self;
}

my $map_status = {
    1 => 'ok',
    2 => 'warning',
    3 => 'error'
};

my $mapping = {
    egLandingSpaceConfiguredWholeGigabytes      => { oid => '.1.3.6.1.4.1.14941.4.1.1' },
    egLandingSpaceAvailableWholeGigabytes       => { oid => '.1.3.6.1.4.1.14941.4.1.3' },
    egRetentionSpaceConfiguredWholeGigabytes    => { oid => '.1.3.6.1.4.1.14941.4.2.1' },
    egRetentionSpaceAvailableWholeGigabytes     => { oid => '.1.3.6.1.4.1.14941.4.2.3' },
    egServerAlarmState                          => { oid => '.1.3.6.1.4.1.14941.4.6.1', map => $map_status }
};
my $oid_exagridServerData = '.1.3.6.1.4.1.14941.4';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_exagridServerData,
        nothing_quit => 1
    );   
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');
    $self->{server} = { 
        status => $result->{egServerAlarmState},
        retention_total => $result->{egRetentionSpaceConfiguredWholeGigabytes} * 1000 * 1000 * 1000,
        retention_used => $result->{egRetentionSpaceConfiguredWholeGigabytes} * 1000 * 1000 * 1000 - $result->{egRetentionSpaceAvailableWholeGigabytes} * 1000 * 1000 * 1000,
        landing_total => $result->{egLandingSpaceConfiguredWholeGigabytes} * 1000 * 1000 * 1000,
        landing_used => $result->{egLandingSpaceConfiguredWholeGigabytes} * 1000 * 1000 * 1000 - $result->{egLandingSpaceAvailableWholeGigabytes} * 1000 * 1000 * 1000
    };
}

1;

__END__

=head1 MODE

Check server status and usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /warning/i').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /error/i').
Can used special variables like: %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'retention-usage' (%), 'landing-usage' (%).

=back

=cut
