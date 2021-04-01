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

package apps::inin::mediaserver::snmp::mode::cmdsrvusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'status : ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_i3MsCmdSrvStatus'};
    $self->{result_values}->{accept_sessions} = $options{new_datas}->{$self->{instance} . '_i3MsCmdSrvAcceptSessions'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        $label = 'free';
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label, unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my $msg = sprintf("Disk Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                   $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_free'};
    $self->{result_values}->{used} = $self->{result_values}->{total} - $self->{result_values}->{free};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cmd', type => 1, cb_prefix_output => 'prefix_cmd_output', message_multiple => 'All command servers are ok' }
    ];
    
    $self->{maps_counters}->{cmd} = [
         { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'i3MsCmdSrvStatus' }, { name => 'i3MsCmdSrvAcceptSessions' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'usage', set => {
                key_values => [ { name => 'display' }, { name => 'free' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'resource-count', set => {
                key_values => [ { name => 'i3MsCmdSrvResourceCount' }, { name => 'display' } ],
                output_template => 'Resource Count : %s',
                perfdatas => [
                    { label => 'resource_count', value => 'i3MsCmdSrvResourceCount', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-client:s"     => { name => 'filter_client' },
                                  "warning-status:s"    => { name => 'warning_status', default => '' },
                                  "critical-status:s"   => { name => 'critical_status', default => '%{status} !~ /^ready/i' },
                                  "units:s"             => { name => 'units', default => '%' },
                                  "free"                => { name => 'free' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_cmd_output {
    my ($self, %options) = @_;
    
    return "Command Server '" . $options{instance_value}->{display} . "' ";
}

my %map_status = (1 => 'unknown', 1 => 'ready', 2 => 'notready', 3 => 'error');
my %map_truth = (1 => 'true', 2 => 'false');
my $mapping = {
    i3MsCmdSrvAcceptSessions    => { oid => '.1.3.6.1.4.1.2793.8227.2.2.1.8', map => \%map_truth },
    i3MsCmdSrvStatus            => { oid => '.1.3.6.1.4.1.2793.8227.2.2.1.2', map => \%map_status },
    i3MsCmdSrvClient            => { oid => '.1.3.6.1.4.1.2793.8227.2.2.1.6' },
    i3MsCmdSrvResourceCount     => { oid => '.1.3.6.1.4.1.2793.8227.2.2.1.9' },
    i3MsCmdSrvRecFreeDiskSpace  => { oid => '.1.3.6.1.4.1.2793.8227.2.2.1.12' },
    i3MsCmdSrvRecTotalDiskSpace => { oid => '.1.3.6.1.4.1.2793.8227.2.2.1.13' },
};

my $oid_i3MsCommandServerInfoTableEntry = '.1.3.6.1.4.1.2793.8227.2.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cmd} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_i3MsCommandServerInfoTableEntry,
                                                nothing_quit => 1);


    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{i3MsCmdSrvStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_client}) && $self->{option_results}->{filter_client} ne '' &&
            $result->{i3MsCmdSrvClient} !~ /$self->{option_results}->{filter_client}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{i3MsCmdSrvClient} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{cmd}->{$instance} = { 
            display => $result->{i3MsCmdSrvClient},
            total => $result->{i3MsCmdSrvRecTotalDiskSpace} * 1024 * 1024,
            free => $result->{i3MsCmdSrvRecFreeDiskSpace} * 1024 * 1024,
            %$result
        };
    }
    
    if (scalar(keys %{$self->{cmd}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No command server found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check command servers usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--filter-client>

Filter client name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{accept_sessions}, %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /^ready/i').
Can used special variables like: %{accept_sessions}, %{status}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'usage', 'resource-count'.

=item B<--critical-*>

Threshold critical.
Can be: 'usage', 'resource-count'.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=back

=cut
