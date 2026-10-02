#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package storage::exagrid::snmp::mode::dataprotection;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use POSIX qw(floor);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

# -------------------------------------------------------------------------
# Status counter
# -------------------------------------------------------------------------
sub custom_status_output {
    my ($self, %options) = @_;
    return 'Server alarm state: ' . $self->{result_values}->{status};
}

# -------------------------------------------------------------------------
# Deduplication ratio
# -------------------------------------------------------------------------
sub custom_dedup_ratio_calc {
    my ($self, %options) = @_;
    $self->{result_values}->{dedup_ratio} =
        ($options{new_datas}->{ $self->{instance} . '_backup_consumed' } > 0)
        ? $options{new_datas}->{ $self->{instance} . '_backup_available' } /
          $options{new_datas}->{ $self->{instance} . '_backup_consumed'  }
        : 1;
    return 0;
}

sub custom_dedup_ratio_output {
    my ($self, %options) = @_;
    return sprintf('Deduplication ratio: %.2f:1', $self->{result_values}->{dedup_ratio});
}

sub custom_dedup_ratio_perfdata {
    my ($self, %options) = @_;
    $self->{output}->perfdata_add(
        label    => 'dedup_ratio',
        value    => sprintf('%.2f', $self->{result_values}->{dedup_ratio}),
        warning  => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min      => 1
    );
}

sub custom_dedup_ratio_threshold {
    my ($self, %options) = @_;
    return $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{dedup_ratio},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'  . $self->{thlabel}, exit_litteral => 'warning'  }
        ]
    );
}

# -------------------------------------------------------------------------
# Backup data available for restore
# -------------------------------------------------------------------------
sub custom_backup_available_calc {
    my ($self, %options) = @_;
    $self->{result_values}->{bytes} =
        $options{new_datas}->{ $self->{instance} . '_backup_available_whole' } * 1_073_741_824 +
        $options{new_datas}->{ $self->{instance} . '_backup_available_frac'  };
    return 0;
}

sub custom_backup_available_output {
    my ($self, %options) = @_;
    my ($val, $unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{bytes});
    return sprintf('Backup data available for restore: %s %s', $val, $unit);
}

sub custom_backup_available_perfdata {
    my ($self, %options) = @_;
    $self->{output}->perfdata_add(
        label    => 'backup_data_available',
        unit     => 'B',
        value    => $self->{result_values}->{bytes},
        warning  => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min      => 0
    );
}

sub custom_backup_available_threshold {
    my ($self, %options) = @_;
    return $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{bytes},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'  . $self->{thlabel}, exit_litteral => 'warning'  }
        ]
    );
}

# -------------------------------------------------------------------------
# Pending deduplication (bytes)
# -------------------------------------------------------------------------
sub custom_pending_dedup_calc {
    my ($self, %options) = @_;
    $self->{result_values}->{bytes} =
        $options{new_datas}->{ $self->{instance} . '_pending_dedup_whole' } * 1_073_741_824 +
        $options{new_datas}->{ $self->{instance} . '_pending_dedup_frac'  };
    return 0;
}

sub custom_pending_dedup_output {
    my ($self, %options) = @_;
    my ($val, $unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{bytes});
    return sprintf('Pending deduplication: %s %s', $val, $unit);
}

sub custom_pending_dedup_perfdata {
    my ($self, %options) = @_;
    $self->{output}->perfdata_add(
        label    => 'pending_dedup',
        unit     => 'B',
        value    => $self->{result_values}->{bytes},
        warning  => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min      => 0
    );
}

sub custom_pending_dedup_threshold {
    my ($self, %options) = @_;
    return $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{bytes},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'  . $self->{thlabel}, exit_litteral => 'warning'  }
        ]
    );
}

# -------------------------------------------------------------------------
# Pending deduplication age
# -------------------------------------------------------------------------
sub custom_pending_dedup_age_calc {
    my ($self, %options) = @_;
    # SNMP TimeTicks are hundredths of a second
    $self->{result_values}->{age_sec} =
        $options{new_datas}->{ $self->{instance} . '_pending_dedup_age' } / 100;
    return 0;
}

sub custom_pending_dedup_age_output {
    my ($self, %options) = @_;
    return sprintf('Pending deduplication age: %s', _format_duration($self->{result_values}->{age_sec}));
}

sub custom_pending_dedup_age_perfdata {
    my ($self, %options) = @_;
    $self->{output}->perfdata_add(
        label    => 'pending_dedup_age',
        unit     => 's',
        value    => $self->{result_values}->{age_sec},
        warning  => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min      => 0
    );
}

sub custom_pending_dedup_age_threshold {
    my ($self, %options) = @_;
    return $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{age_sec},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'  . $self->{thlabel}, exit_litteral => 'warning'  }
        ]
    );
}

# -------------------------------------------------------------------------
# Pending replication (bytes)
# -------------------------------------------------------------------------
sub custom_pending_repl_calc {
    my ($self, %options) = @_;
    $self->{result_values}->{bytes} =
        $options{new_datas}->{ $self->{instance} . '_pending_repl_whole' } * 1_073_741_824 +
        $options{new_datas}->{ $self->{instance} . '_pending_repl_frac'  };
    return 0;
}

sub custom_pending_repl_output {
    my ($self, %options) = @_;
    my ($val, $unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{bytes});
    return sprintf('Pending replication: %s %s', $val, $unit);
}

sub custom_pending_repl_perfdata {
    my ($self, %options) = @_;
    $self->{output}->perfdata_add(
        label    => 'pending_replication',
        unit     => 'B',
        value    => $self->{result_values}->{bytes},
        warning  => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min      => 0
    );
}

sub custom_pending_repl_threshold {
    my ($self, %options) = @_;
    return $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{bytes},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'  . $self->{thlabel}, exit_litteral => 'warning'  }
        ]
    );
}

# -------------------------------------------------------------------------
# Pending replication age
# -------------------------------------------------------------------------
sub custom_pending_repl_age_calc {
    my ($self, %options) = @_;
    $self->{result_values}->{age_sec} =
        $options{new_datas}->{ $self->{instance} . '_pending_repl_age' } / 100;
    return 0;
}

sub custom_pending_repl_age_output {
    my ($self, %options) = @_;
    return sprintf('Pending replication age: %s', _format_duration($self->{result_values}->{age_sec}));
}

sub custom_pending_repl_age_perfdata {
    my ($self, %options) = @_;
    $self->{output}->perfdata_add(
        label    => 'pending_replication_age',
        unit     => 's',
        value    => $self->{result_values}->{age_sec},
        warning  => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min      => 0
    );
}

sub custom_pending_repl_age_threshold {
    my ($self, %options) = @_;
    return $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{age_sec},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'  . $self->{thlabel}, exit_litteral => 'warning'  }
        ]
    );
}

# -------------------------------------------------------------------------
# Retention-locked (pending purge) space
# -------------------------------------------------------------------------
sub custom_pending_purge_calc {
    my ($self, %options) = @_;
    $self->{result_values}->{bytes} =
        $options{new_datas}->{ $self->{instance} . '_pending_purge_whole' } * 1_073_741_824 +
        $options{new_datas}->{ $self->{instance} . '_pending_purge_frac'  };
    return 0;
}

sub custom_pending_purge_output {
    my ($self, %options) = @_;
    my ($val, $unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{bytes});
    return sprintf('Retention-locked (pending purge) space: %s %s', $val, $unit);
}

sub custom_pending_purge_perfdata {
    my ($self, %options) = @_;
    $self->{output}->perfdata_add(
        label    => 'pending_purge',
        unit     => 'B',
        value    => $self->{result_values}->{bytes},
        warning  => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min      => 0
    );
}

sub custom_pending_purge_threshold {
    my ($self, %options) = @_;
    return $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{bytes},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'  . $self->{thlabel}, exit_litteral => 'warning'  }
        ]
    );
}

# -------------------------------------------------------------------------
# I/O rate helpers  (read / write / dedup share the same output/perf/thr subs)
# -------------------------------------------------------------------------
sub custom_rate_output {
    my ($self, %options) = @_;
    return sprintf('%s rate: %.2f MB/s',
        ucfirst($self->{result_values}->{rate_label}),
        $self->{result_values}->{rate_mbps});
}

sub custom_rate_perfdata {
    my ($self, %options) = @_;
    $self->{output}->perfdata_add(
        label    => $self->{result_values}->{rate_label} . '_rate',
        unit     => 'MB/s',
        value    => sprintf('%.2f', $self->{result_values}->{rate_mbps}),
        warning  => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min      => 0
    );
}

sub custom_rate_threshold {
    my ($self, %options) = @_;
    return $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{rate_mbps},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'  . $self->{thlabel}, exit_litteral => 'warning'  }
        ]
    );
}

sub custom_read_rate_calc {
    my ($self, %options) = @_;
    $self->{result_values}->{rate_label} = 'read';
    $self->{result_values}->{rate_mbps}  = $options{new_datas}->{ $self->{instance} . '_read_rate' };
    return 0;
}

sub custom_write_rate_calc {
    my ($self, %options) = @_;
    $self->{result_values}->{rate_label} = 'write';
    $self->{result_values}->{rate_mbps}  = $options{new_datas}->{ $self->{instance} . '_write_rate' };
    return 0;
}

sub custom_dedup_rate_calc {
    my ($self, %options) = @_;
    $self->{result_values}->{rate_label} = 'dedup';
    $self->{result_values}->{rate_mbps}  = $options{new_datas}->{ $self->{instance} . '_dedup_rate' };
    return 0;
}

# -------------------------------------------------------------------------
# Internal helper
# -------------------------------------------------------------------------
sub _format_duration {
    my ($sec) = @_;
    return '0s' unless defined $sec && $sec > 0;
    my $d = floor($sec / 86400); $sec -= $d * 86400;
    my $h = floor($sec / 3600);  $sec -= $h * 3600;
    my $m = floor($sec / 60);    $sec -= $m * 60;
    my @parts;
    push @parts, "${d}d" if $d;
    push @parts, "${h}h" if $h;
    push @parts, "${m}m" if $m;
    push @parts, "${sec}s" if $sec || !@parts;
    return join(' ', @parts);
}

# -------------------------------------------------------------------------
# Counter map  — type => 0 (global), type => 2 (status text)
# matching the style of serverusage.pm exactly; no constants.pm needed
# -------------------------------------------------------------------------
sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' }
    ];

    $self->{maps_counters}->{global} = [

        { label => 'status', type => 2,
          warning_default  => '%{status} =~ /warning/i',
          critical_default => '%{status} =~ /error/i',
          set => {
            key_values                     => [ { name => 'status' } ],
            closure_custom_output          => $self->can('custom_status_output'),
            closure_custom_perfdata        => sub { return 0; },
            closure_custom_threshold_check => \&catalog_status_threshold_ng
          }
        },

        { label => 'dedup-ratio', set => {
            key_values => [ { name => 'backup_available' }, { name => 'backup_consumed' } ],
            closure_custom_calc            => $self->can('custom_dedup_ratio_calc'),
            closure_custom_output          => $self->can('custom_dedup_ratio_output'),
            closure_custom_perfdata        => $self->can('custom_dedup_ratio_perfdata'),
            closure_custom_threshold_check => $self->can('custom_dedup_ratio_threshold')
        }},

        { label => 'backup-available', set => {
            key_values => [ { name => 'backup_available_whole' }, { name => 'backup_available_frac' } ],
            closure_custom_calc            => $self->can('custom_backup_available_calc'),
            closure_custom_output          => $self->can('custom_backup_available_output'),
            closure_custom_perfdata        => $self->can('custom_backup_available_perfdata'),
            closure_custom_threshold_check => $self->can('custom_backup_available_threshold')
        }},

        { label => 'pending-dedup', set => {
            key_values => [ { name => 'pending_dedup_whole' }, { name => 'pending_dedup_frac' } ],
            closure_custom_calc            => $self->can('custom_pending_dedup_calc'),
            closure_custom_output          => $self->can('custom_pending_dedup_output'),
            closure_custom_perfdata        => $self->can('custom_pending_dedup_perfdata'),
            closure_custom_threshold_check => $self->can('custom_pending_dedup_threshold')
        }},

        { label => 'pending-dedup-age', set => {
            key_values => [ { name => 'pending_dedup_age' } ],
            closure_custom_calc            => $self->can('custom_pending_dedup_age_calc'),
            closure_custom_output          => $self->can('custom_pending_dedup_age_output'),
            closure_custom_perfdata        => $self->can('custom_pending_dedup_age_perfdata'),
            closure_custom_threshold_check => $self->can('custom_pending_dedup_age_threshold')
        }},

        { label => 'pending-replication', set => {
            key_values => [ { name => 'pending_repl_whole' }, { name => 'pending_repl_frac' } ],
            closure_custom_calc            => $self->can('custom_pending_repl_calc'),
            closure_custom_output          => $self->can('custom_pending_repl_output'),
            closure_custom_perfdata        => $self->can('custom_pending_repl_perfdata'),
            closure_custom_threshold_check => $self->can('custom_pending_repl_threshold')
        }},

        { label => 'pending-replication-age', set => {
            key_values => [ { name => 'pending_repl_age' } ],
            closure_custom_calc            => $self->can('custom_pending_repl_age_calc'),
            closure_custom_output          => $self->can('custom_pending_repl_age_output'),
            closure_custom_perfdata        => $self->can('custom_pending_repl_age_perfdata'),
            closure_custom_threshold_check => $self->can('custom_pending_repl_age_threshold')
        }},

        { label => 'pending-purge', set => {
            key_values => [ { name => 'pending_purge_whole' }, { name => 'pending_purge_frac' } ],
            closure_custom_calc            => $self->can('custom_pending_purge_calc'),
            closure_custom_output          => $self->can('custom_pending_purge_output'),
            closure_custom_perfdata        => $self->can('custom_pending_purge_perfdata'),
            closure_custom_threshold_check => $self->can('custom_pending_purge_threshold')
        }},

        { label => 'read-rate', set => {
            key_values => [ { name => 'read_rate' } ],
            closure_custom_calc            => $self->can('custom_read_rate_calc'),
            closure_custom_output          => $self->can('custom_rate_output'),
            closure_custom_perfdata        => $self->can('custom_rate_perfdata'),
            closure_custom_threshold_check => $self->can('custom_rate_threshold')
        }},

        { label => 'write-rate', set => {
            key_values => [ { name => 'write_rate' } ],
            closure_custom_calc            => $self->can('custom_write_rate_calc'),
            closure_custom_output          => $self->can('custom_rate_output'),
            closure_custom_perfdata        => $self->can('custom_rate_perfdata'),
            closure_custom_threshold_check => $self->can('custom_rate_threshold')
        }},

        { label => 'dedup-rate', set => {
            key_values => [ { name => 'dedup_rate' } ],
            closure_custom_calc            => $self->can('custom_dedup_rate_calc'),
            closure_custom_output          => $self->can('custom_rate_output'),
            closure_custom_perfdata        => $self->can('custom_rate_perfdata'),
            closure_custom_threshold_check => $self->can('custom_rate_threshold')
        }},
    ];
}

# -------------------------------------------------------------------------
# Constructor
# -------------------------------------------------------------------------
sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

# -------------------------------------------------------------------------
# OID mapping  — same approach as serverusage.pm
# -------------------------------------------------------------------------
my $map_status = {
    1 => 'ok',
    2 => 'warning',
    3 => 'error'
};

my $mapping = {
    egBackupDataAvailableWholeGigabytes                     => { oid => '.1.3.6.1.4.1.14941.4.3.1',  default => 0 },
    egBackupDataAvailableFractionalGigabytes                => { oid => '.1.3.6.1.4.1.14941.4.3.2',  default => 0 },
    egBackupDataSpaceConsumedWholeGigabytes                 => { oid => '.1.3.6.1.4.1.14941.4.3.3',  default => 0 },
    egBackupDataSpaceConsumedFractionalGigabytes            => { oid => '.1.3.6.1.4.1.14941.4.3.4',  default => 0 },
    egPendingDeduplicationWholeGigabytes                    => { oid => '.1.3.6.1.4.1.14941.4.4.1',  default => 0 },
    egPendingDeduplicationFractionalGigabytes               => { oid => '.1.3.6.1.4.1.14941.4.4.2',  default => 0 },
    egPendingDeduplicationAge                               => { oid => '.1.3.6.1.4.1.14941.4.4.3',  default => 0 },
    egPendingReplicationWholeGigabytes                      => { oid => '.1.3.6.1.4.1.14941.4.5.1',  default => 0 },
    egPendingReplicationFractionalGigabytes                 => { oid => '.1.3.6.1.4.1.14941.4.5.2',  default => 0 },
    egPendingReplicationAge                                 => { oid => '.1.3.6.1.4.1.14941.4.5.3',  default => 0 },
    egServerAlarmState                                      => { oid => '.1.3.6.1.4.1.14941.4.6.1',  map => $map_status },
    egServerReadRateMegabytesSec                            => { oid => '.1.3.6.1.4.1.14941.4.7.1',  default => 0 },
    egServerWriteRateMegabytesSec                           => { oid => '.1.3.6.1.4.1.14941.4.7.2',  default => 0 },
    egServerDedupRateMegabytesSec                           => { oid => '.1.3.6.1.4.1.14941.4.7.3',  default => 0 },
    egRetentionSpaceAllPendingPurgeBytesWholeGigabytes      => { oid => '.1.3.6.1.4.1.14941.4.2.13', default => 0 },
    egRetentionSpaceAllPendingPurgeBytesFractionalGigabytes => { oid => '.1.3.6.1.4.1.14941.4.2.14', default => 0 },
};

my $oid_exagridServerData = '.1.3.6.1.4.1.14941.4';

# -------------------------------------------------------------------------
# Data collection
# -------------------------------------------------------------------------
sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid          => $oid_exagridServerData,
        nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(
        mapping  => $mapping,
        results  => $snmp_result,
        instance => '0'
    );

    $self->{global} = {
        status                 => $result->{egServerAlarmState},

        backup_available       => $result->{egBackupDataAvailableWholeGigabytes}    * 1_073_741_824
                                + $result->{egBackupDataAvailableFractionalGigabytes},
        backup_consumed        => $result->{egBackupDataSpaceConsumedWholeGigabytes} * 1_073_741_824
                                + $result->{egBackupDataSpaceConsumedFractionalGigabytes},

        backup_available_whole => $result->{egBackupDataAvailableWholeGigabytes},
        backup_available_frac  => $result->{egBackupDataAvailableFractionalGigabytes},

        pending_dedup_whole    => $result->{egPendingDeduplicationWholeGigabytes},
        pending_dedup_frac     => $result->{egPendingDeduplicationFractionalGigabytes},
        pending_dedup_age      => $result->{egPendingDeduplicationAge},

        pending_repl_whole     => $result->{egPendingReplicationWholeGigabytes},
        pending_repl_frac      => $result->{egPendingReplicationFractionalGigabytes},
        pending_repl_age       => $result->{egPendingReplicationAge},

        pending_purge_whole    => $result->{egRetentionSpaceAllPendingPurgeBytesWholeGigabytes},
        pending_purge_frac     => $result->{egRetentionSpaceAllPendingPurgeBytesFractionalGigabytes},

        read_rate              => $result->{egServerReadRateMegabytesSec},
        write_rate             => $result->{egServerWriteRateMegabytesSec},
        dedup_rate             => $result->{egServerDedupRateMegabytesSec},
    };
}

1;

__END__

=head1 MODE

Check ExaGrid data-protection health: deduplication ratio and throughput,
pending deduplication and replication (bytes + age), retention-locked
(pending-purge) space, backup data available for restore, and live I/O rates.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^(status|dedup-ratio|write-rate)$'

=item B<--warning-status>

Condition for WARNING alarm state (default: '%{status} =~ /warning/i').
Available variable: %{status}

=item B<--critical-status>

Condition for CRITICAL alarm state (default: '%{status} =~ /error/i').
Available variable: %{status}

=item B<--warning-dedup-ratio>

Warning threshold for deduplication ratio. Use range syntax to alert when
the ratio drops below a minimum: --warning-dedup-ratio='2:'

=item B<--critical-dedup-ratio>

Critical threshold for deduplication ratio.
Example: --critical-dedup-ratio='1.5:'

=item B<--warning-backup-available>

Warning threshold for backup data available for restore (bytes).

=item B<--critical-backup-available>

Critical threshold for backup data available for restore (bytes).

=item B<--warning-pending-dedup>

Warning threshold for pending deduplication data (bytes).
Example: --warning-pending-dedup='53687091200' (50 GB)

=item B<--critical-pending-dedup>

Critical threshold for pending deduplication data (bytes).

=item B<--warning-pending-dedup-age>

Warning threshold for pending deduplication age (seconds).
Example: --warning-pending-dedup-age='14400' (4 hours)

=item B<--critical-pending-dedup-age>

Critical threshold for pending deduplication age (seconds).

=item B<--warning-pending-replication>

Warning threshold for pending replication data (bytes).

=item B<--critical-pending-replication>

Critical threshold for pending replication data (bytes).

=item B<--warning-pending-replication-age>

Warning threshold for pending replication lag (seconds).
Example: --warning-pending-replication-age='14400' (4 hours)

=item B<--critical-pending-replication-age>

Critical threshold for pending replication lag (seconds).

=item B<--warning-pending-purge>

Warning threshold for retention-locked (pending-purge) space (bytes).

=item B<--critical-pending-purge>

Critical threshold for retention-locked (pending-purge) space (bytes).

=item B<--warning-read-rate>

Warning threshold for read throughput (MB/s).

=item B<--critical-read-rate>

Critical threshold for read throughput (MB/s).

=item B<--warning-write-rate>

Warning threshold for write throughput (MB/s).

=item B<--critical-write-rate>

Critical threshold for write throughput (MB/s).

=item B<--warning-dedup-rate>

Warning threshold for deduplication throughput (MB/s).

=item B<--critical-dedup-rate>

Critical threshold for deduplication throughput (MB/s).

=back

=cut
