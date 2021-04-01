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

package storage::quantum::dxi::ssh::mode::reduction;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_volume_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => $self->{result_values}->{label}, unit => 'B',
        value => $self->{result_values}->{volume},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label})
    );
}

sub custom_volume_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{volume},
        threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]
    );
    return $exit;
}

sub custom_volume_output {
    my ($self, %options) = @_;

    my ($volume_value, $volume_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{volume});
    return sprintf('%s: %s %s', $self->{result_values}->{display}, $volume_value, $volume_unit);
}

sub custom_volume_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{volume} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}};
    $self->{result_values}->{display} = $options{extra_options}->{display_ref};
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'size-before-reduction', set => {
                key_values => [ { name => 'size_before_reduction' } ],
                closure_custom_calc => $self->can('custom_volume_calc'),
                closure_custom_calc_extra_options => { label_ref => 'size_before_reduction', display_ref => 'Data Size Before Reduction' },
                closure_custom_output => $self->can('custom_volume_output'),
                closure_custom_perfdata => $self->can('custom_volume_perfdata'),
                closure_custom_threshold_check => $self->can('custom_volume_threshold'),
            }
        },
        { label => 'size-after-reduction', set => {
                key_values => [ { name => 'size_after_reduction' } ],
                closure_custom_calc => $self->can('custom_volume_calc'),
                closure_custom_calc_extra_options => { label_ref => 'size_after_reduction', display_ref => 'Data Size After Reduction' },
                closure_custom_output => $self->can('custom_volume_output'),
                closure_custom_perfdata => $self->can('custom_volume_perfdata'),
                closure_custom_threshold_check => $self->can('custom_volume_threshold'),
            }
        },
        { label => 'incoming-namespace', set => {
                key_values => [ { name => 'incoming_namespace' } ],
                closure_custom_calc => $self->can('custom_volume_calc'),
                closure_custom_calc_extra_options => { label_ref => 'incoming_namespace', display_ref => 'Incoming Namespace' },
                closure_custom_output => $self->can('custom_volume_output'),
                closure_custom_perfdata => $self->can('custom_volume_perfdata'),
                closure_custom_threshold_check => $self->can('custom_volume_threshold'),
            }
        },
        { label => 'nfs-deduplicated-shares', set => {
                key_values => [ { name => 'nfs_deduplicated_shares' } ],
                closure_custom_calc => $self->can('custom_volume_calc'),
                closure_custom_calc_extra_options => { label_ref => 'nfs_deduplicated_shares', display_ref => 'NFS Deduplicated Shares' },
                closure_custom_output => $self->can('custom_volume_output'),
                closure_custom_perfdata => $self->can('custom_volume_perfdata'),
                closure_custom_threshold_check => $self->can('custom_volume_threshold'),
            }
        },
        { label => 'cifs-smb-deduplicated-shares', set => {
                key_values => [ { name => 'cifs_smb_deduplicated_shares' } ],
                closure_custom_calc => $self->can('custom_volume_calc'),
                closure_custom_calc_extra_options => { label_ref => 'cifs_smb_deduplicated_shares', display_ref => 'CIFS/SMB Deduplicated Shares' },
                closure_custom_output => $self->can('custom_volume_output'),
                closure_custom_perfdata => $self->can('custom_volume_perfdata'),
                closure_custom_threshold_check => $self->can('custom_volume_threshold'),
            }
        },
        { label => 'application-specific-deduplicated-shares', set => {
                key_values => [ { name => 'application_specific_deduplicated_shares' } ],
                closure_custom_calc => $self->can('custom_volume_calc'),
                closure_custom_calc_extra_options => { label_ref => 'application_specific_deduplicated_shares', display_ref => 'Application Specific Deduplicated Shares' },
                closure_custom_output => $self->can('custom_volume_output'),
                closure_custom_perfdata => $self->can('custom_volume_perfdata'),
                closure_custom_threshold_check => $self->can('custom_volume_threshold'),
            }
        },
        { label => 'deduplicated-partitions', set => {
                key_values => [ { name => 'deduplicated_partitions' } ],
                closure_custom_calc => $self->can('custom_volume_calc'),
                closure_custom_calc_extra_options => { label_ref => 'deduplicated_partitions', display_ref => 'Deduplicated Partitions' },
                closure_custom_output => $self->can('custom_volume_output'),
                closure_custom_perfdata => $self->can('custom_volume_perfdata'),
                closure_custom_threshold_check => $self->can('custom_volume_threshold'),
            }
        },
        { label => 'ost-storage-servers', set => {
                key_values => [ { name => 'ost_storage_servers' } ],
                closure_custom_calc => $self->can('custom_volume_calc'),
                closure_custom_calc_extra_options => { label_ref => 'ost_storage_servers', display_ref => 'OST Storage Servers' },
                closure_custom_output => $self->can('custom_volume_output'),
                closure_custom_perfdata => $self->can('custom_volume_perfdata'),
                closure_custom_threshold_check => $self->can('custom_volume_threshold'),
            }
        },
        { label => 'total-reduction-ratio', set => {
                key_values => [ { name => 'total_reduction_ratio' } ],
                output_template => 'Total Reduction Ratio: %.2f',
                perfdatas => [
                    { label => 'total_reduction_ratio', value => 'total_reduction_ratio', template => '%.2f',
                      unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => 'deduplication-ratio', set => {
                key_values => [ { name => 'deduplication_ratio' } ],
                output_template => 'Deduplication Ratio: %.2f',
                perfdatas => [
                    { label => 'deduplication_ratio', value => 'deduplication_ratio', template => '%.2f',
                      unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => 'compression-ratio', set => {
                key_values => [ { name => 'compression_ratio' } ],
                output_template => 'Compression Ratio: %.2f',
                perfdatas => [
                    { label => 'compression_ratio', value => 'compression_ratio', template => '%.2f',
                      unit => '%', min => 0, max => 100 },
                ],
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

sub manage_selection {
    my ($self, %options) = @_;

    my $stdout = $options{custom}->execute_command(command => 'syscli --get datareductionstat');
    # Output data:
    #     Data Size Before Reduction = 346.08 TB
    #     - Incoming Namespace = 0.00 MB
    #     - NFS Deduplicated Shares = 125.98 GB
    #     - CIFS/SMB Deduplicated Shares = 2.04 TB
    #     - Application Specific Deduplicated Shares = 0.00 MB
    #     - Deduplicated Partitions = 343.91 TB
    #     - OST Storage Servers = 0.00 MB
    #     Data Size After Reduction = 66.00 TB
    #     Total Reduction Ratio = 5.24 : 1
    #     - Deduplication Ratio = 3.95 : 1
    #     - Compression Ratio = 1.33 : 1

    $self->{global} = {};
    foreach (split(/\n/, $stdout)) {
        $self->{global}->{size_before_reduction} = $options{custom}->convert_to_bytes(raw_value => $1) if (/.*Data\sSize\sBefore\sReduction\s=\s(.*)$/i);
        $self->{global}->{incoming_namespace} = $options{custom}->convert_to_bytes(raw_value => $1) if (/.*Incoming\sNamespace\s=\s(.*)$/i);
        $self->{global}->{nfs_deduplicated_shares} = $options{custom}->convert_to_bytes(raw_value => $1) if (/.*NFS\sDeduplicated\sShares\s=\s(.*)$/i);
        $self->{global}->{cifs_smb_deduplicated_shares} = $options{custom}->convert_to_bytes(raw_value => $1) if (/.*CIFS\/SMB\sDeduplicated\sShares\s=\s(.*)$/i);
        $self->{global}->{application_specific_deduplicated_shares} = $options{custom}->convert_to_bytes(raw_value => $1) if (/.*Application\sSpecific\sDeduplicated\sShares\s=\s(.*)$/i);
        $self->{global}->{deduplicated_partitions} = $options{custom}->convert_to_bytes(raw_value => $1) if (/.*Deduplicated\sPartitions\s=\s(.*)$/i);
        $self->{global}->{ost_storage_servers} = $options{custom}->convert_to_bytes(raw_value => $1) if (/.*OST\sStorage\sServers\s=\s(.*)$/i);
        $self->{global}->{size_after_reduction} = $options{custom}->convert_to_bytes(raw_value => $1) if (/.*Data\sSize\sAfter\sReduction\s=\s(.*)$/i);
        $self->{global}->{total_reduction_ratio} = $1 if (/.*Total\sReduction\sRatio\s=\s(.*)\s:\s1$/i);
        $self->{global}->{deduplication_ratio} = $1 if (/.*Deduplication\sRatio\s=\s(.*)\s:\s1$/i);
        $self->{global}->{compression_ratio} = $1 if (/.*Compression\sRatio\s=\s(.*)\s:\s1$/i);
    }
}

1;

__END__

=head1 MODE

Check data reduction statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='ratio'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'size-before-reduction', 'size-after-reduction', 'incoming-namespace',
'nfs-deduplicated-shares', cifs-smb-deduplicated-shares',
'application-specific-deduplicated-shares', 'deduplicated-partitions',
'ost-storage-servers', 'total-reduction-ratio',
'deduplication-ratio', 'compression-ratio'.

=back

=cut
