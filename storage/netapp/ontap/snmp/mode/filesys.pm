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

package storage::netapp::ontap::snmp::mode::filesys;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_vs_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        "vserver '%s' status : %s",
        $self->{result_values}->{vserver_name},
        $self->{result_values}->{vserver_status},
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'fs', type => 1, cb_prefix_output => 'prefix_fs_output', message_multiple => 'All filesystems are ok', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{fs} = [
        { label => 'usage', set => {
                key_values => [ { name => 'display' }, { name => 'used' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'inodes', set => {
                key_values => [ { name => 'dfPerCentInodeCapacity' }, { name => 'display' } ],
                output_template => 'Inodes Used : %s %%', output_error_template => "Inodes : %s",
                perfdatas => [
                    { label => 'inodes', value => 'dfPerCentInodeCapacity', template => '%d',
                       unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'compresssaved', set => {
                key_values => [ { name => 'dfCompressSavedPercent' }, { name => 'display' } ],
                output_template => 'Compress Saved : %s %%', output_error_template => "Compress Saved : %s",
                perfdatas => [
                    { label => 'compresssaved', value => 'dfCompressSavedPercent', template => '%d',
                       unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'dedupsaved', set => {
                key_values => [ { name => 'dfDedupeSavedPercent' }, { name => 'display' } ],
                output_template => 'Dedupe Saved : %s %%', output_error_template => "Dedupe Saved : %s",
                perfdatas => [
                    { label => 'dedupsaved', value => 'dfDedupeSavedPercent', template => '%d',
                       unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'vserver-status', threshold => 0, set => {
                key_values => [ { name => 'vserver_status' }, { name => 'vserver_name' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_vs_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    return if ($self->{result_values}->{total} <= 0);
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
    
    return 'ok' if ($self->{result_values}->{total} <= 0);
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
    
    my $msg;
    if ($self->{result_values}->{total} == 0) {
        $msg = 'skipping: total size is 0';
    } elsif ($self->{result_values}->{total} < 0) {
        $msg = 'skipping: negative total value (maybe use snmp v2c)';
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
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};

    return 0 if ($options{new_datas}->{$self->{instance} . '_total'} == 0);
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};

    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    # snapshot can be over 100%
    if ($self->{result_values}->{free} < 0) {
        $self->{result_values}->{free} = 0;
        $self->{result_values}->{prct_free} = 0;
    }
    
    return 0;
}

sub prefix_fs_output {
    my ($self, %options) = @_;
    
    return "Filesys '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'units:s'                   => { name => 'units', default => '%' },
        'free'                      => { name => 'free' },
        'filter-name:s'             => { name => 'filter_name' },
        'filter-type:s'             => { name => 'filter_type' },
        'filter-vserver:s'          => { name => 'filter_vserver' },
        'filter-vserver-state:s'    => { name => 'filter_vserver_state' },
        'unknown-vserver-status:s'  => { name => 'unknown_vserver_status', default => '' },
        'warning-vserver-status:s'  => { name => 'warning_vserver_status', default => '' },
        'critical-vserver-status:s' => { name => 'critical_vserver_status', default => '' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_vserver_status', 'critical_vserver_status', 'unknown_vserver_status']);
}

my $map_types = {
    1 => 'traditionalVolume',
    2 => 'flexibleVolume',
    3 => 'aggregate',
    4 => 'stripedAggregate',
    5 => 'stripedVolume'
};
my $map_vserver_state = {
    0 => 'running', 1 => 'stopped', 2 => 'starting', 3 => 'stopping'
};
my $mapping = {
    dfType      => { oid => '.1.3.6.1.4.1.789.1.5.4.1.23', map => $map_types },
};
my $mapping2 = {
    dfFileSys               => { oid => '.1.3.6.1.4.1.789.1.5.4.1.2' },
    dfKBytesTotal           => { oid => '.1.3.6.1.4.1.789.1.5.4.1.3' },
    dfKBytesUsed            => { oid => '.1.3.6.1.4.1.789.1.5.4.1.4' },
    dfPerCentInodeCapacity  => { oid => '.1.3.6.1.4.1.789.1.5.4.1.9' },
    df64TotalKBytes         => { oid => '.1.3.6.1.4.1.789.1.5.4.1.29' },
    df64UsedKBytes          => { oid => '.1.3.6.1.4.1.789.1.5.4.1.30' },
    dfVserver               => { oid => '.1.3.6.1.4.1.789.1.5.4.1.34' },
    dfCompressSavedPercent  => { oid => '.1.3.6.1.4.1.789.1.5.4.1.38' },
    dfDedupeSavedPercent    => { oid => '.1.3.6.1.4.1.789.1.5.4.1.40' },
};
my $mapping3 = {
    vserverName     => { oid => '.1.3.6.1.4.1.789.1.27.1.1.2' },
    vserverState    => { oid => '.1.3.6.1.4.1.789.1.27.1.1.16', map => $map_vserver_state },
};

sub get_vserver_state {
    my ($self, %options) = @_;

    return if (
        (!defined($self->{option_results}->{filter_vserver_state}) || $self->{option_results}->{filter_vserver} eq '') &&
        (!defined($self->{option_results}->{warning_vserver_status}) || $self->{option_results}->{warning_vserver_status} eq '') &&
        (!defined($self->{option_results}->{critical_vserver_status}) || $self->{option_results}->{critical_vserver_status} eq '') &&
        (!defined($self->{option_results}->{unknown_vserver_status}) || $self->{option_results}->{unknown_vserver_status} eq '')
    );

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping3->{vserverName}->{oid} }, 
            { oid => $mapping3->{vserverState}->{oid} }
        ],
        return_type => 1,
    );
    
    $self->{vserver} = {};
    foreach (keys %$snmp_result) {
        next if (! /^$mapping3->{vserverName}->{oid}\.(.*)/);
        my $result = $options{snmp}->map_instance(mapping => $mapping3, results => $snmp_result, instance => $1);
        $self->{vserver}->{$result->{vserverName}} = $result->{vserverState};
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my @oids = (
        $mapping2->{dfKBytesTotal}->{oid},
        $mapping2->{dfKBytesUsed}->{oid},
        $mapping2->{dfPerCentInodeCapacity}->{oid},
        $mapping2->{dfCompressSavedPercent}->{oid},
        $mapping2->{dfDedupeSavedPercent}->{oid},
        $mapping2->{dfVserver}->{oid},
    );
    if (!$options{snmp}->is_snmpv1()) {
        push @oids, $mapping2->{df64TotalKBytes}->{oid};
        push @oids, $mapping2->{df64UsedKBytes}->{oid};
    }

    $self->get_vserver_state(%options);

    my $results;
    if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '') {
        $results = $options{snmp}->get_multiple_table(
            oids => [
                { oid => $mapping->{dfType}->{oid} }, 
                { oid => $mapping2->{dfFileSys}->{oid} }
            ],
            return_type => 1,
            nothing_quit => 1
        );
    } else {
        $results = $options{snmp}->get_table(oid => $mapping2->{dfFileSys}->{oid}, nothing_quit => 1);
    }
    my @fs_selected;
    foreach my $oid (keys %{$results}) {
        next if ($oid !~ /^$mapping2->{dfFileSys}->{oid}\.(\d+)/);
        my $instance = $1;
        my $name = $results->{$oid};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter name.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $map_types->{$results->{$mapping->{dfType}->{oid} . '.' . $instance}} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter type.", debug => 1);
            next;
        }
        push @fs_selected, $instance;
    }

    if (scalar(@fs_selected) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }

    $self->{fs} = {};
    $options{snmp}->load(oids => \@oids, instances => \@fs_selected);
    my $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    foreach my $instance (sort @fs_selected) {
        my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => $instance);

        if (defined($result2->{dfVserver}) && $result2->{dfVserver} ne '' && 
            defined($self->{option_results}->{filter_vserver_state}) && $self->{option_results}->{filter_vserver_state} ne '' &&
            $self->{vserver}->{$result2->{dfVserver}} !~ /$self->{option_results}->{filter_vserver_state}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $instance . "': no matching filter vserver state.", debug => 1);
            next;
        }
        if (defined($result2->{dfVserver}) && defined($self->{option_results}->{filter_vserver}) && $self->{option_results}->{filter_vserver} ne '' &&
            $result2->{dfVserver} !~ /$self->{option_results}->{filter_vserver}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $instance . "': no matching filter vserver.", debug => 1);
            next;
        }

        $self->{fs}->{$instance} = {
            display => defined($result2->{dfVserver}) && $result2->{dfVserver} ne '' ? 
                $result2->{dfVserver} . ':' . $results->{$mapping2->{dfFileSys}->{oid} . '.' . $instance} : 
                $results->{$mapping2->{dfFileSys}->{oid} . '.' . $instance}
        };
        $self->{fs}->{$instance}->{total} = $result2->{dfKBytesTotal} * 1024;
        $self->{fs}->{$instance}->{used} = $result2->{dfKBytesUsed} * 1024;
        if (defined($result2->{df64TotalKBytes}) && $result2->{df64TotalKBytes} > 0) {
            $self->{fs}->{$instance}->{total} = $result2->{df64TotalKBytes} * 1024;
            $self->{fs}->{$instance}->{used} = $result2->{df64UsedKBytes} * 1024;
        }
        $self->{fs}->{$instance}->{dfCompressSavedPercent} = $result2->{dfCompressSavedPercent};
        $self->{fs}->{$instance}->{dfDedupeSavedPercent} = $result2->{dfDedupeSavedPercent};
        if ($self->{fs}->{$instance}->{total} > 0) {
            $self->{fs}->{$instance}->{dfPerCentInodeCapacity} = $result2->{dfPerCentInodeCapacity};
        }

        $self->{fs}->{$instance}->{vserver_name} = $result2->{dfVserver};
        $self->{fs}->{$instance}->{vserver_status} = defined($result2->{dfVserver}) ? $self->{vserver}->{$result2->{dfVserver}} : undef;
    }
}

1;

__END__

=head1 MODE

Check filesystem usage (volumes, snapshots and aggregates also).

=over 8

=item B<--unknown-vserver-status>

Set unknown threshold for status (Default: '').
Can used special variables like: %{vserver_status}, %{vserver_name}

=item B<--warning-vserver-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{vserver_status}, %{vserver_name}

=item B<--critical-vserver-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{vserver_status}, %{vserver_name}

=item B<--warning-*>

Threshold warning.
Can be: usage, inodes (%), compresssaved (%), dedupsaved (%).

=item B<--critical-*>

Threshold critical.
Can be: usage, inodes (%), compresssaved (%), dedupsaved (%).

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--filter-name>

Filter by filesystem name (can be a regexp).

=item B<--filter-vserver>

Filter by vserver name (can be a regexp).

=item B<--filter-vserver-state>

Filter by vserver state (can be a regexp).

=item B<--filter-type>

Filter filesystem type (can be a regexp. Example: 'flexibleVolume|aggregate').

=back

=cut
