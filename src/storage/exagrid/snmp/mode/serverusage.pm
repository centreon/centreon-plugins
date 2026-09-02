# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package storage::exagrid::snmp::mode::serverusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

# =============================================================================
# Internal helper
# =============================================================================
sub _timeticks_to_seconds { return int( ( $_[0] // 0 ) / 100 ) }

# =============================================================================
# STATUS
# =============================================================================
sub custom_status_output {
    my ($self, %options) = @_;
    return 'Server Status : ' . $self->{result_values}->{status};
}

# =============================================================================
# LANDING ZONE — available bytes
# =============================================================================
sub custom_landing_available_calc {
    my ($self, %options) = @_;
    $self->{result_values}->{landing_available} =
        $options{new_datas}->{ $self->{instance} . '_landing_available_whole' } * 1_000_000_000
      + $options{new_datas}->{ $self->{instance} . '_landing_available_frac'  };
    return 0;
}

sub custom_landing_available_output {
    my ($self, %options) = @_;
    my ($val, $unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{landing_available});
    return sprintf('Landing Zone available for next backup: %s %s', $val, $unit);
}

sub custom_landing_available_perfdata {
    my ($self, %options) = @_;
    $self->{output}->perfdata_add(
        label    => 'landing_available',
        unit     => 'B',
        value    => $self->{result_values}->{landing_available},
        warning  => $self->{perfdata}->get_perfdata_for_output(label => 'warning-'  . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min      => 0
    );
}

sub custom_landing_available_threshold {
    my ($self, %options) = @_;
    return $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{landing_available},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'  . $self->{thlabel}, exit_litteral => 'warning'  }
        ]
    );
}

# =============================================================================
# RETENTION SPACE — used% (unchanged from working version)
# =============================================================================
sub custom_usage_calc {
    my ($self, %options) = @_;
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{total} = $options{new_datas}->{ $self->{instance} . '_' . $self->{result_values}->{label} . '_total' };
    $self->{result_values}->{used}  = $options{new_datas}->{ $self->{instance} . '_' . $self->{result_values}->{label} . '_used'  };

    if ($self->{result_values}->{total} != 0) {
        $self->{result_values}->{free}      = $self->{result_values}->{total} - $self->{result_values}->{used};
        $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
        $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    } else {
        $self->{result_values}->{free}      = 0;
        $self->{result_values}->{prct_used} = 0;
        $self->{result_values}->{prct_free} = 0;
    }
    return 0;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    my ($tv, $tu) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($uv, $uu) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($fv, $fu) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        '%s Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)',
        ucfirst($self->{result_values}->{label}),
        $tv . ' ' . $tu,
        $uv . ' ' . $uu, $self->{result_values}->{prct_used},
        $fv . ' ' . $fu, $self->{result_values}->{prct_free}
    );
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    $self->{output}->perfdata_add(
        label    => $self->{result_values}->{label} . '_used',
        unit     => 'B',
        value    => $self->{result_values}->{used},
        warning  => $self->{perfdata}->get_perfdata_for_output(
            label => 'warning-' . $self->{thlabel},
            total => $self->{result_values}->{total},
            cast_int => 1
        ),
        critical => $self->{perfdata}->get_perfdata_for_output(
            label => 'critical-' . $self->{thlabel},
            total => $self->{result_values}->{total},
            cast_int => 1
        ),
        min => 0,
        max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    return $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{prct_used},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'  . $self->{thlabel}, exit_litteral => 'warning'  }
        ]
    );
}

# =============================================================================
# RETENTION BREAKDOWN — absolute bytes (primary, replica, pending-purge)
# =============================================================================
sub custom_retention_detail_calc {
    my ($self, %options) = @_;
    my $key = $options{extra_options}->{key_ref};
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{bytes} = $options{new_datas}->{ $self->{instance} . '_' . $key } // 0;
    return 0;
}

sub custom_retention_detail_output {
    my ($self, %options) = @_;
    my ($v, $u) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{bytes});
    return sprintf('%s: %s %s', $self->{result_values}->{label}, $v, $u);
}

sub custom_retention_detail_perfdata {
    my ($self, %options) = @_;
    my $perfkey = lc($self->{result_values}->{label});
    $perfkey =~ s/\s+/_/g;
    $self->{output}->perfdata_add(
        label    => $perfkey,
        unit     => 'B',
        value    => $self->{result_values}->{bytes},
        warning  => $self->{perfdata}->get_perfdata_for_output(label => 'warning-'  . $self->{label}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}),
        min      => 0
    );
}

sub custom_retention_detail_threshold {
    my ($self, %options) = @_;
    return $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{bytes},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'  . $self->{thlabel}, exit_litteral => 'warning'  }
        ]
    );
}

# =============================================================================
# DEDUP RATIO
# =============================================================================
sub custom_dedup_ratio_calc {
    my ($self, %options) = @_;
    $self->{result_values}->{dedup_ratio} = $options{new_datas}->{ $self->{instance} . '_dedup_ratio' } // 0;
    return 0;
}

sub custom_dedup_ratio_output {
    my ($self, %options) = @_;
    return sprintf('Deduplication Ratio: %.2f:1', $self->{result_values}->{dedup_ratio});
}

sub custom_dedup_ratio_perfdata {
    my ($self, %options) = @_;
    $self->{output}->perfdata_add(
        label    => 'dedup_ratio',
        value    => sprintf('%.4f', $self->{result_values}->{dedup_ratio}),
        warning  => $self->{perfdata}->get_perfdata_for_output(label => 'warning-'  . $self->{label}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}),
        min      => 0
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

# =============================================================================
# PENDING BYTES (dedup / replication)
# =============================================================================
sub custom_pending_bytes_calc {
    my ($self, %options) = @_;
    my $lbl = $options{extra_options}->{label_ref};
    $self->{result_values}->{label} = $lbl;
    $self->{result_values}->{bytes} = $options{new_datas}->{ $self->{instance} . '_' . $lbl . '_pending_bytes' } // 0;
    return 0;
}

sub custom_pending_bytes_output {
    my ($self, %options) = @_;
    my ($v, $u) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{bytes});
    return sprintf('Pending %s: %s %s', ucfirst($self->{result_values}->{label}), $v, $u);
}

sub custom_pending_bytes_perfdata {
    my ($self, %options) = @_;
    $self->{output}->perfdata_add(
        label    => $self->{result_values}->{label} . '_pending',
        unit     => 'B',
        value    => $self->{result_values}->{bytes},
        warning  => $self->{perfdata}->get_perfdata_for_output(label => 'warning-'  . $self->{label}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}),
        min      => 0
    );
}

sub custom_pending_bytes_threshold {
    my ($self, %options) = @_;
    return $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{bytes},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'  . $self->{thlabel}, exit_litteral => 'warning'  }
        ]
    );
}

# =============================================================================
# PENDING AGE (dedup / replication) — seconds
# =============================================================================
sub custom_pending_age_calc {
    my ($self, %options) = @_;
    my $lbl = $options{extra_options}->{label_ref};
    $self->{result_values}->{label}   = $lbl;
    $self->{result_values}->{seconds} = _timeticks_to_seconds(
        $options{new_datas}->{ $self->{instance} . '_' . $lbl . '_pending_age' }
    );
    return 0;
}

sub custom_pending_age_output {
    my ($self, %options) = @_;
    my $s = $self->{result_values}->{seconds};
    return sprintf('Pending %s age: %dh%02dm%02ds',
        ucfirst($self->{result_values}->{label}),
        int($s / 3600), int(($s % 3600) / 60), $s % 60
    );
}

sub custom_pending_age_perfdata {
    my ($self, %options) = @_;
    $self->{output}->perfdata_add(
        label    => $self->{result_values}->{label} . '_pending_age',
        unit     => 's',
        value    => $self->{result_values}->{seconds},
        warning  => $self->{perfdata}->get_perfdata_for_output(label => 'warning-'  . $self->{label}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}),
        min      => 0
    );
}

sub custom_pending_age_threshold {
    my ($self, %options) = @_;
    return $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{seconds},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'  . $self->{thlabel}, exit_litteral => 'warning'  }
        ]
    );
}

# =============================================================================
# I/O RATES (MB/s)
# =============================================================================
sub custom_rate_calc {
    my ($self, %options) = @_;
    my $lbl = $options{extra_options}->{label_ref};
    $self->{result_values}->{label}     = $lbl;
    $self->{result_values}->{rate_mbps} = $options{new_datas}->{ $self->{instance} . '_' . $lbl . '_rate_mbps' } // 0;
    return 0;
}

sub custom_rate_output {
    my ($self, %options) = @_;
    return sprintf('%s rate: %.2f MB/s', ucfirst($self->{result_values}->{label}),
                   $self->{result_values}->{rate_mbps});
}

sub custom_rate_perfdata {
    my ($self, %options) = @_;
    $self->{output}->perfdata_add(
        label    => $self->{result_values}->{label} . '_rate',
        unit     => 'MB\/s',
        value    => $self->{result_values}->{rate_mbps},
        warning  => $self->{perfdata}->get_perfdata_for_output(label => 'warning-'  . $self->{label}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}),
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

# =============================================================================
# COUNTER DEFINITIONS
# =============================================================================
sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'server', type => 0, message_separator => ' - ' }
    ];

    $self->{maps_counters}->{server} = [

        # ---- Status --------------------------------------------------------
        { label => 'status', type => 2,
          warning_default  => '%{status} =~ /warning/i',
          critical_default => '%{status} =~ /error/i',
          set => {
            key_values                     => [ { name => 'status' } ],
            closure_custom_output          => $self->can('custom_status_output'),
            closure_custom_perfdata        => sub { return 0 },
            closure_custom_threshold_check => \&catalog_status_threshold_ng
          }
        },

        # ---- Landing Zone: available bytes ---------------------------------
        { label => 'landing-available', set => {
            key_values => [
                { name => 'landing_available_whole' },
                { name => 'landing_available_frac'  }
            ],
            closure_custom_calc            => $self->can('custom_landing_available_calc'),
            closure_custom_output          => $self->can('custom_landing_available_output'),
            closure_custom_perfdata        => $self->can('custom_landing_available_perfdata'),
            closure_custom_threshold_check => $self->can('custom_landing_available_threshold'),
            output_template                => 'Landing Zone available: %s',
        }},

        # ---- Retention space: used% ----------------------------------------
        { label => 'retention-usage', set => {
            key_values => [ { name => 'retention_used' }, { name => 'retention_total' } ],
            closure_custom_calc               => $self->can('custom_usage_calc'),
            closure_custom_calc_extra_options => { label_ref => 'retention' },
            closure_custom_output             => $self->can('custom_usage_output'),
            closure_custom_perfdata           => $self->can('custom_usage_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_usage_threshold'),
            output_template                   => 'Retention Usage: %s',
        }},

        # ---- Retention breakdown: Primary ----------------------------------
        { label => 'retention-primary', set => {
            key_values => [ { name => 'retention_primary_bytes' } ],
            closure_custom_calc               => $self->can('custom_retention_detail_calc'),
            closure_custom_calc_extra_options => { label_ref => 'Primary Retention', key_ref => 'retention_primary_bytes' },
            closure_custom_output             => $self->can('custom_retention_detail_output'),
            closure_custom_perfdata           => $self->can('custom_retention_detail_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_retention_detail_threshold'),
            output_template                   => 'Primary Retention: %s',
        }},

        # ---- Retention breakdown: Replica ----------------------------------
        { label => 'retention-replica', set => {
            key_values => [ { name => 'retention_replica_bytes' } ],
            closure_custom_calc               => $self->can('custom_retention_detail_calc'),
            closure_custom_calc_extra_options => { label_ref => 'Replica Retention', key_ref => 'retention_replica_bytes' },
            closure_custom_output             => $self->can('custom_retention_detail_output'),
            closure_custom_perfdata           => $self->can('custom_retention_detail_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_retention_detail_threshold'),
            output_template                   => 'Replica Retention: %s',
        }},

        # ---- Retention breakdown: Pending Purge ----------------------------
        { label => 'retention-pending-purge', set => {
            key_values => [ { name => 'retention_pending_purge_bytes' } ],
            closure_custom_calc               => $self->can('custom_retention_detail_calc'),
            closure_custom_calc_extra_options => { label_ref => 'Pending Purge', key_ref => 'retention_pending_purge_bytes' },
            closure_custom_output             => $self->can('custom_retention_detail_output'),
            closure_custom_perfdata           => $self->can('custom_retention_detail_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_retention_detail_threshold'),
            output_template                   => 'Pending Purge: %s',
        }},

        # ---- Deduplication ratio -------------------------------------------
        { label => 'dedup-ratio', set => {
            key_values => [ { name => 'dedup_ratio' } ],
            closure_custom_calc            => $self->can('custom_dedup_ratio_calc'),
            closure_custom_output          => $self->can('custom_dedup_ratio_output'),
            closure_custom_perfdata        => $self->can('custom_dedup_ratio_perfdata'),
            closure_custom_threshold_check => $self->can('custom_dedup_ratio_threshold'),
            output_template                => 'Dedup Ratio: %s',
        }},

        # ---- Pending deduplication: bytes ----------------------------------
        { label => 'pending-dedup', set => {
            key_values => [ { name => 'deduplication_pending_bytes' } ],
            closure_custom_calc               => $self->can('custom_pending_bytes_calc'),
            closure_custom_calc_extra_options => { label_ref => 'deduplication' },
            closure_custom_output             => $self->can('custom_pending_bytes_output'),
            closure_custom_perfdata           => $self->can('custom_pending_bytes_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_pending_bytes_threshold'),
            output_template                   => 'Pending Dedup: %s',
        }},

        # ---- Pending deduplication: age ------------------------------------
        { label => 'pending-dedup-age', set => {
            key_values => [ { name => 'deduplication_pending_age' } ],
            closure_custom_calc               => $self->can('custom_pending_age_calc'),
            closure_custom_calc_extra_options => { label_ref => 'deduplication' },
            closure_custom_output             => $self->can('custom_pending_age_output'),
            closure_custom_perfdata           => $self->can('custom_pending_age_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_pending_age_threshold'),
            output_template                   => 'Pending Dedup Age: %s',
        }},

        # ---- Pending replication: bytes ------------------------------------
        { label => 'pending-replication', set => {
            key_values => [ { name => 'replication_pending_bytes' } ],
            closure_custom_calc               => $self->can('custom_pending_bytes_calc'),
            closure_custom_calc_extra_options => { label_ref => 'replication' },
            closure_custom_output             => $self->can('custom_pending_bytes_output'),
            closure_custom_perfdata           => $self->can('custom_pending_bytes_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_pending_bytes_threshold'),
            output_template                   => 'Pending Replication: %s',
        }},

        # ---- Pending replication: age --------------------------------------
        { label => 'pending-replication-age', set => {
            key_values => [ { name => 'replication_pending_age' } ],
            closure_custom_calc               => $self->can('custom_pending_age_calc'),
            closure_custom_calc_extra_options => { label_ref => 'replication' },
            closure_custom_output             => $self->can('custom_pending_age_output'),
            closure_custom_perfdata           => $self->can('custom_pending_age_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_pending_age_threshold'),
            output_template                   => 'Pending Replication Age: %s',
        }},

        # ---- I/O Rates -----------------------------------------------------
        { label => 'read-rate', set => {
            key_values => [ { name => 'read_rate_mbps' } ],
            closure_custom_calc               => $self->can('custom_rate_calc'),
            closure_custom_calc_extra_options => { label_ref => 'read' },
            closure_custom_output             => $self->can('custom_rate_output'),
            closure_custom_perfdata           => $self->can('custom_rate_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_rate_threshold'),
            output_template                   => 'Read Rate: %s',
        }},

        { label => 'write-rate', set => {
            key_values => [ { name => 'write_rate_mbps' } ],
            closure_custom_calc               => $self->can('custom_rate_calc'),
            closure_custom_calc_extra_options => { label_ref => 'write' },
            closure_custom_output             => $self->can('custom_rate_output'),
            closure_custom_perfdata           => $self->can('custom_rate_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_rate_threshold'),
            output_template                   => 'Write Rate: %s',
        }},

        { label => 'dedup-rate', set => {
            key_values => [ { name => 'dedup_rate_mbps' } ],
            closure_custom_calc               => $self->can('custom_rate_calc'),
            closure_custom_calc_extra_options => { label_ref => 'dedup' },
            closure_custom_output             => $self->can('custom_rate_output'),
            closure_custom_perfdata           => $self->can('custom_rate_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_rate_threshold'),
            output_template                   => 'Dedup Rate: %s',
        }},

    ];
}

# =============================================================================
# Constructor — all custom warning/critical options must be registered here
# because the counter framework only auto-registers options for counters
# that use the standard output_template+perfdatas pattern, not custom closures.
# =============================================================================
sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    return $self;
}

# =============================================================================
# OID mapping
# =============================================================================
my $map_status = {
    1 => 'ok',
    2 => 'warning',
    3 => 'error'
};

my $mapping = {
    egLandingSpaceAvailableWholeGigabytes               => { oid => '.1.3.6.1.4.1.14941.4.1.3',  default => 0 },
    egLandingSpaceAvailableFractionalGigabytes          => { oid => '.1.3.6.1.4.1.14941.4.1.4',  default => 0 },
    egRetentionSpaceConfiguredWholeGigabytes            => { oid => '.1.3.6.1.4.1.14941.4.2.1',  default => 0 },
    egRetentionSpaceConfiguredFractionalGigabytes       => { oid => '.1.3.6.1.4.1.14941.4.2.2',  default => 0 },
    egRetentionSpaceAvailableWholeGigabytes             => { oid => '.1.3.6.1.4.1.14941.4.2.3',  default => 0 },
    egRetentionSpaceAvailableFractionalGigabytes        => { oid => '.1.3.6.1.4.1.14941.4.2.4',  default => 0 },
    egRetentionSpacePrimarySharesWholeGigabytes         => { oid => '.1.3.6.1.4.1.14941.4.2.5',  default => 0 },
    egRetentionSpacePrimarySharesFractionalGigabytes    => { oid => '.1.3.6.1.4.1.14941.4.2.6',  default => 0 },
    egRetentionSpaceReplicasWholeGigabytes              => { oid => '.1.3.6.1.4.1.14941.4.2.7',  default => 0 },
    egRetentionSpaceReplicasFractionalGigabytes         => { oid => '.1.3.6.1.4.1.14941.4.2.8',  default => 0 },
    egRetentionSpaceAllPendingPurgeBytesWholeGigabytes       => { oid => '.1.3.6.1.4.1.14941.4.2.13', default => 0 },
    egRetentionSpaceAllPendingPurgeBytesFractionalGigabytes  => { oid => '.1.3.6.1.4.1.14941.4.2.14', default => 0 },
    egBackupDataAvailableWholeGigabytes                 => { oid => '.1.3.6.1.4.1.14941.4.3.1',  default => 0 },
    egBackupDataAvailableFractionalGigabytes            => { oid => '.1.3.6.1.4.1.14941.4.3.2',  default => 0 },
    egBackupDataSpaceConsumedWholeGigabytes             => { oid => '.1.3.6.1.4.1.14941.4.3.3',  default => 0 },
    egBackupDataSpaceConsumedFractionalGigabytes        => { oid => '.1.3.6.1.4.1.14941.4.3.4',  default => 0 },
    egPendingDeduplicationWholeGigabytes                => { oid => '.1.3.6.1.4.1.14941.4.4.1',  default => 0 },
    egPendingDeduplicationAge                           => { oid => '.1.3.6.1.4.1.14941.4.4.3',  default => 0 },
    egPendingReplicationWholeGigabytes                  => { oid => '.1.3.6.1.4.1.14941.4.5.1',  default => 0 },
    egPendingReplicationAge                             => { oid => '.1.3.6.1.4.1.14941.4.5.3',  default => 0 },
    egServerAlarmState                                  => { oid => '.1.3.6.1.4.1.14941.4.6.1',  map => $map_status },
    egServerReadRateMegabytesSec                        => { oid => '.1.3.6.1.4.1.14941.4.7.1',  default => 0 },
    egServerWriteRateMegabytesSec                       => { oid => '.1.3.6.1.4.1.14941.4.7.2',  default => 0 },
    egServerDedupRateMegabytesSec                       => { oid => '.1.3.6.1.4.1.14941.4.7.3',  default => 0 },
};

my $oid_exagridServerData = '.1.3.6.1.4.1.14941.4';

# =============================================================================
# Data collection
# =============================================================================
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

    # Retention space
    my $retention_total = $result->{egRetentionSpaceConfiguredWholeGigabytes}  * 1_000_000_000
                        + $result->{egRetentionSpaceConfiguredFractionalGigabytes};
    my $retention_avail = $result->{egRetentionSpaceAvailableWholeGigabytes}   * 1_000_000_000
                        + $result->{egRetentionSpaceAvailableFractionalGigabytes};
    $retention_avail = $retention_total if $retention_avail > $retention_total;

    # Retention breakdown
    my $retention_primary = $result->{egRetentionSpacePrimarySharesWholeGigabytes}   * 1_000_000_000
                          + $result->{egRetentionSpacePrimarySharesFractionalGigabytes};
    my $retention_replica = $result->{egRetentionSpaceReplicasWholeGigabytes}         * 1_000_000_000
                          + $result->{egRetentionSpaceReplicasFractionalGigabytes};
    my $retention_purge   = $result->{egRetentionSpaceAllPendingPurgeBytesWholeGigabytes}     * 1_000_000_000
                          + $result->{egRetentionSpaceAllPendingPurgeBytesFractionalGigabytes};

    # Dedup ratio
    my $backup_available = $result->{egBackupDataAvailableWholeGigabytes}     * 1_000_000_000
                         + $result->{egBackupDataAvailableFractionalGigabytes};
    my $backup_consumed  = $result->{egBackupDataSpaceConsumedWholeGigabytes} * 1_000_000_000
                         + $result->{egBackupDataSpaceConsumedFractionalGigabytes};
    my $dedup_ratio = ($backup_consumed > 0) ? ($backup_available / $backup_consumed) : 0;

    $self->{server} = {
        status                        => $result->{egServerAlarmState},

        landing_available_whole       => $result->{egLandingSpaceAvailableWholeGigabytes},
        landing_available_frac        => $result->{egLandingSpaceAvailableFractionalGigabytes},

        retention_total               => $retention_total,
        retention_used                => $retention_total - $retention_avail,

        retention_primary_bytes       => $retention_primary,
        retention_replica_bytes       => $retention_replica,
        retention_pending_purge_bytes => $retention_purge,

        dedup_ratio                   => $dedup_ratio,

        deduplication_pending_bytes   => $result->{egPendingDeduplicationWholeGigabytes} * 1_000_000_000,
        deduplication_pending_age     => $result->{egPendingDeduplicationAge},

        replication_pending_bytes     => $result->{egPendingReplicationWholeGigabytes} * 1_000_000_000,
        replication_pending_age       => $result->{egPendingReplicationAge},

        read_rate_mbps                => $result->{egServerReadRateMegabytesSec},
        write_rate_mbps               => $result->{egServerWriteRateMegabytesSec},
        dedup_rate_mbps               => $result->{egServerDedupRateMegabytesSec},
    };
}

1;

__END__

=head1 MODE

Check ExaGrid server status, space usage, retention breakdown,
deduplication ratio, pending dedup/replication, and I/O rates via SNMP.

Use --filter-counters to isolate individual metrics for independent
Nagios/NagVis service checks and graphs.

=over 8

=item B<--filter-counters>

Only display matching counters (regexp).
  --filter-counters='^status$'
  --filter-counters='^retention-usage$'
  --filter-counters='^read-rate$'

=item B<--warning-status> / B<--critical-status>

Status condition (defaults: warn '%{status} =~ /warning/i',
                            crit '%{status} =~ /error/i').

=item B<--warning-landing-available> / B<--critical-landing-available>

Landing Zone available space (bytes). Use range syntax to alert below:
  --warning-landing-available='8000000000000:'
  --critical-landing-available='5000000000000:'

=item B<--warning-retention-usage> / B<--critical-retention-usage>

Retention used space (percent 0-100).
  --warning-retention-usage=80 --critical-retention-usage=90

=item B<--warning-retention-primary> / B<--critical-retention-primary>

Primary Retention (bytes).

=item B<--warning-retention-replica> / B<--critical-retention-replica>

Replica Retention (bytes).

=item B<--warning-retention-pending-purge> / B<--critical-retention-pending-purge>

Pending Purge (bytes).

=item B<--warning-dedup-ratio> / B<--critical-dedup-ratio>

Dedup ratio. Range syntax to alert when ratio drops below value:
  --warning-dedup-ratio='3:' --critical-dedup-ratio='2:'

=item B<--warning-pending-dedup> / B<--critical-pending-dedup>

Pending deduplication (bytes).

=item B<--warning-pending-dedup-age> / B<--critical-pending-dedup-age>

Pending deduplication age (seconds).
  --warning-pending-dedup-age=7200 --critical-pending-dedup-age=21600

=item B<--warning-pending-replication> / B<--critical-pending-replication>

Pending replication (bytes).

=item B<--warning-pending-replication-age> / B<--critical-pending-replication-age>

Pending replication age (seconds).

=item B<--warning-read-rate> / B<--critical-read-rate>

Read rate (MB/s).

=item B<--warning-write-rate> / B<--critical-write-rate>

Write rate (MB/s).

=item B<--warning-dedup-rate> / B<--critical-dedup-rate>

Deduplication processing rate (MB/s).

=back

=cut