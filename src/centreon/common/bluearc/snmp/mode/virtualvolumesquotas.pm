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

package centreon::common::bluearc::snmp::mode::virtualvolumesquotas;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($usage_value, $usage_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{usage});

    my $msg;
    if ($self->{result_values}->{usageLimit} > 0) {
        my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{usageLimit});
        my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{usageLimit} - $self->{result_values}->{usage});
        my $usagePrct = $self->{result_values}->{usage} * 100 / $self->{result_values}->{usageLimit};
        $msg = sprintf(
            'usage total: %s %s used: %s %s (%.2f%%) free: %s %s (%.2f%%)',
            $total_value, $total_unit,
            $usage_value, $usage_unit,
            $usagePrct,
            $free_value, $free_unit,
            100 - $usagePrct
        );
    } else {
        $msg = sprintf(
            'usage: %s %s',
            $usage_value, $usage_unit
        );
    }

    return $msg;
}

sub custom_files_output {
    my ($self, %options) = @_;

    my $msg;
    if ($self->{result_values}->{fileCountLimit} > 0) {
        my $usagePrct = $self->{result_values}->{fileCount} * 100 / $self->{result_values}->{fileCountLimit};
        $msg = sprintf(
            'files total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
            $self->{result_values}->{fileCountLimit},
            $self->{result_values}->{fileCount},
            $usagePrct,
            $self->{result_values}->{fileCountLimit} - $self->{result_values}->{fileCount},
            100 - $usagePrct
        );
    } else {
        $msg = sprintf(
            'files: %s',
            $self->{result_values}->{fileCount}
        );
    }

    return $msg;
}

sub custom_files_calc {
    my ($self, %options) = @_;

    return -10 if ($options{new_datas}->{$self->{instance} . '_fileCountLimit'} <= 0);

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{fsLabel} = $options{new_datas}->{$self->{instance} . '_fsLabel'};
    $self->{result_values}->{target} = $options{new_datas}->{$self->{instance} . '_target'};

    $self->{result_values}->{fileCountLimit} = $options{new_datas}->{$self->{instance} . '_fileCountLimit'};
    $self->{result_values}->{fileCount} = $options{new_datas}->{$self->{instance} . '_fileCount'};
    $self->{result_values}->{fileFreeCount} = $self->{result_values}->{fileCountLimit} - $self->{result_values}->{fileCount};
    $self->{result_values}->{filePrct} = $self->{result_values}->{fileCount} * 100 / $self->{result_values}->{fileCountLimit};

    return 0;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    return -10 if ($options{new_datas}->{$self->{instance} . '_usageLimit'} <= 0);

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{fsLabel} = $options{new_datas}->{$self->{instance} . '_fsLabel'};
    $self->{result_values}->{target} = $options{new_datas}->{$self->{instance} . '_target'};

    $self->{result_values}->{usageLimit} = $options{new_datas}->{$self->{instance} . '_usageLimit'};
    $self->{result_values}->{usage} = $options{new_datas}->{$self->{instance} . '_usage'};
    $self->{result_values}->{free} = $self->{result_values}->{usageLimit} - $self->{result_values}->{usage};
    $self->{result_values}->{usagePrct} = $self->{result_values}->{usage} * 100 / $self->{result_values}->{usageLimit};

    return 0;
}

sub prefix_vvq_output {
    my ($self, %options) = @_;

    return sprintf(
        "virtual volume '%s' [fs: %s] [target: %s] quota ",
        $options{instance_value}->{name},
        $options{instance_value}->{fsLabel},
        $options{instance_value}->{target}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Virtual volumes quotas ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', },
        { name => 'vvq', type => 1, cb_prefix_output => 'prefix_vvq_output', message_multiple => 'All virtual volumes quotas are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'vvq-detected', display_ok => 0, nlabel => 'virtual_volumes.quotas.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vvq} = [
        { label => 'vvq-usage', nlabel => 'virtual_volume.quota.usage.bytes', set => {
                key_values => [
                    { name => 'usage' }, { name => 'usageLimit' },
                    { name => 'name' }, { name => 'fsLabel' }, { name => 'target' }
                ],
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_threshold_check => sub {
                    my ($self, %options) = @_;

                    return $self->{perfdata}->threshold_check(value => $self->{result_values}->{usage}, threshold => [ { label => 'critical-' . $self->{thlabel} . '-' . $self->{instance}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel} . '-' . $self->{instance}, exit_litteral => 'warning' } ]);
                },
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'B',
                        instances => [$self->{result_values}->{name}, $self->{result_values}->{fsLabel}, $self->{result_values}->{target}],
                        value => $self->{result_values}->{usage},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel} . '-' . $self->{instance}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel} . '-' . $self->{instance}),
                        min => 0
                    );
                }
            }
        },
        { label => 'vvq-usage-free', nlabel => 'virtual_volume.quota.free.bytes', display_ok => 0, set => {
                key_values => [
                    { name => 'usage' }, { name => 'usageLimit' },
                    { name => 'name' }, { name => 'fsLabel' }, { name => 'target' }
                ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_threshold_check => sub {
                    my ($self, %options) = @_;

                    return $self->{perfdata}->threshold_check(value => $self->{result_values}->{free}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
                },
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'B',
                        instances => [$self->{result_values}->{name}, $self->{result_values}->{fsLabel}, $self->{result_values}->{target}],
                        value => $self->{result_values}->{free},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0,
                        max => $self->{result_values}->{usageLimit}
                    );
                }
            }
        },
        { label => 'vvq-usage-prct', nlabel => 'virtual_volume.quota.usage.percentage', display_ok => 0, set => {
                key_values => [
                    { name => 'usage' }, { name => 'usageLimit' },
                    { name => 'name' }, { name => 'fsLabel' }, { name => 'target' }
                ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_threshold_check => sub {
                    my ($self, %options) = @_;

                    return $self->{perfdata}->threshold_check(value => $self->{result_values}->{usagePrct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
                },
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => '%',
                        instances => [$self->{result_values}->{name}, $self->{result_values}->{fsLabel}, $self->{result_values}->{target}],
                        value => $self->{result_values}->{usagePrct},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0,
                        max => 100
                    );
                }
            }
        },
        { label => 'vvq-files', nlabel => 'virtual_volume.quota.files.count', set => {
                key_values => [
                    { name => 'fileCount' }, { name => 'fileCountLimit' },
                    { name => 'name' }, { name => 'fsLabel' }, { name => 'target' }
                ],
                closure_custom_output => $self->can('custom_files_output'),
                closure_custom_threshold_check => sub {
                    my ($self, %options) = @_;

                    return $self->{perfdata}->threshold_check(value => $self->{result_values}->{fileCount}, threshold => [ { label => 'critical-' . $self->{thlabel} . '-' . $self->{instance}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel} . '-' . $self->{instance}, exit_litteral => 'warning' } ]);
                },
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        instances => [$self->{result_values}->{name}, $self->{result_values}->{fsLabel}, $self->{result_values}->{target}],
                        value => $self->{result_values}->{fileCount},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel} . '-' . $self->{instance}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel} . '-' . $self->{instance}),
                        min => 0
                    );
                }
            }
        },
        { label => 'vvq-files-free', nlabel => 'virtual_volume.quota.files.free.count', set => {
                key_values => [
                    { name => 'fileCount' }, { name => 'fileCountLimit' },
                    { name => 'name' }, { name => 'fsLabel' }, { name => 'target' }
                ],
                closure_custom_calc => $self->can('custom_files_calc'),
                closure_custom_output => $self->can('custom_files_output'),
                closure_custom_threshold_check => sub {
                    my ($self, %options) = @_;

                    return $self->{perfdata}->threshold_check(value => $self->{result_values}->{fileFreeCount}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
                },
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        instances => [$self->{result_values}->{name}, $self->{result_values}->{fsLabel}, $self->{result_values}->{target}],
                        value => $self->{result_values}->{fileFreeCount},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
                    );
                }
            }
        },
        { label => 'vvq-files-prct', nlabel => 'virtual_volume.quota.files.percentage', set => {
                key_values => [
                    { name => 'fileCount' }, { name => 'fileCountLimit' },
                    { name => 'name' }, { name => 'fsLabel' }, { name => 'target' }
                ],
                closure_custom_calc => $self->can('custom_files_calc'),
                closure_custom_output => $self->can('custom_files_output'),
                closure_custom_threshold_check => sub {
                    my ($self, %options) = @_;

                    return $self->{perfdata}->threshold_check(value => $self->{result_values}->{filePrct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
                },
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => '%',
                        instances => [$self->{result_values}->{name}, $self->{result_values}->{fsLabel}, $self->{result_values}->{target}],
                        value => $self->{result_values}->{filePrct},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0,
                        max => 100
                    );
                }
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-filesystem-label:s' => { name => 'filter_filesystem_label' },
        'filter-volume-name:s'      => { name => 'filter_volume_name' },
        'filter-target:s'           => { name => 'filter_target' }
    });

    return $self;
}

my $mapping_vvq = {
    target     => { oid => '.1.3.6.1.4.1.11096.6.2.1.2.1.7.1.1' }, # virtualVolumeTitanQuotasTarget
    targetType => { oid => '.1.3.6.1.4.1.11096.6.2.1.2.1.7.1.3' }  # virtualVolumeTitanQuotasTargetType
};
my $mapping_stats = {
    usage          => { oid => '.1.3.6.1.4.1.11096.6.2.1.2.1.7.1.4' }, # virtualVolumeTitanQuotasUsage
    fileCount      => { oid => '.1.3.6.1.4.1.11096.6.2.1.2.1.7.1.5' }, # virtualVolumeTitanQuotasFileCount
    usageLimit     => { oid => '.1.3.6.1.4.1.11096.6.2.1.2.1.7.1.6' }, # virtualVolumeTitanQuotasUsageLimit
    usageWarn      => { oid => '.1.3.6.1.4.1.11096.6.2.1.2.1.7.1.9' }, # virtualVolumeTitanQuotasUsageWarning
    usageCrit      => { oid => '.1.3.6.1.4.1.11096.6.2.1.2.1.7.1.10' }, # virtualVolumeTitanQuotasUsageCritical
    fileCountLimit => { oid => '.1.3.6.1.4.1.11096.6.2.1.2.1.7.1.11' }, # virtualVolumeTitanQuotasFileCountLimit
    fileCountWarn  => { oid => '.1.3.6.1.4.1.11096.6.2.1.2.1.7.1.14' }, # virtualVolumeTitanQuotasFileCountWarning
    fileCountCrit  => { oid => '.1.3.6.1.4.1.11096.6.2.1.2.1.7.1.15' }  # virtualVolumeTitanQuotasFileCountCritical
};

sub manage_selection {
    my ($self, %options) = @_;

     if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $oid_fsLabel = '.1.3.6.1.4.1.11096.6.1.1.6.3.2.1.2'; # fsStatsFsLabel
    my $oid_vvName = '.1.3.6.1.4.1.11096.6.2.1.2.1.2.1.2'; # virtualVolumeTitanName
    my $oid_vvqTable = '.1.3.6.1.4.1.11096.6.2.1.2.1.7'; # virtualVolumeTitanQuotasTable
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_fsLabel },
            { oid => $oid_vvqTable, start => $mapping_vvq->{target}->{oid}, end => $mapping_vvq->{targetType}->{oid} }
        ],
        nothing_quit => 1
    );

    $self->{global} = { detected => 0 };
    $self->{vvq} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_vvqTable}}) {
        next if ($oid !~ /^$mapping_vvq->{target}->{oid}\.(.*)$/);
        my $instance = $1;

        my $instanceTarget = '';
        $instanceTarget = '.' . join('.', map(ord($_), split(//, $snmp_result->{$oid_vvqTable}->{$oid})))
            if ($snmp_result->{$oid_vvqTable}->{$oid} ne '');
        $oid =~ /^$mapping_vvq->{target}->{oid}\.(\d+)\.(.*?)$instanceTarget\.\d+$/;
        my $spanId = $1;
        my @indexes = split(/\./, $2);

        my $fsLabel = $snmp_result->{$oid_fsLabel}->{$oid_fsLabel . '.' . $spanId};
        my $name = $self->{output}->decode(join('', map(chr($_), @indexes)));

        my $result = $options{snmp}->map_instance(mapping => $mapping_vvq, results => $snmp_result->{$oid_vvqTable}, instance => $instance);
        my $target = 'virtualVolume';
        if ($result->{targetType} == 1) {
            $target = 'user:' . $result->{target};
        } elsif ($result->{targetType} == 2) {
            $target = 'group:' . $result->{target};
        }

        next if (defined($self->{option_results}->{filter_filesystem_label}) && $self->{option_results}->{filter_filesystem_label} ne '' &&
            $fsLabel !~ /$self->{option_results}->{filter_filesystem_label}/);
        next if (defined($self->{option_results}->{filter_volume_name}) && $self->{option_results}->{filter_volume_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_volume_name}/);
        next if (defined($self->{option_results}->{filter_target}) && $self->{option_results}->{filter_target} ne '' &&
            $target !~ /$self->{option_results}->{filter_target}/);

        $self->{vvq}->{$instance} = {
            fsLabel => $fsLabel,
            target => $target,
            name => $name
        };
    }

    return if (scalar(keys %{$self->{vvq}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping_stats)) ],
        instances => [ map($_, keys %{$self->{vvq}}) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();

    foreach (keys %{$self->{vvq}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping_stats, results => $snmp_result, instance => $_);

        $self->{vvq}->{$_}->{usage} = $result->{usage};
        $self->{vvq}->{$_}->{usageLimit} = $result->{usageLimit};
        $self->{vvq}->{$_}->{fileCount} = $result->{fileCount};
        $self->{vvq}->{$_}->{fileCountLimit} = $result->{fileCountLimit};
        $self->{global}->{detected}++;

        if (defined($self->{option_results}->{'warning-instance-virtual_volume-quota-usage-bytes'}) && $self->{option_results}->{'warning-instance-virtual_volume-quota-usage-bytes'} ne '') {
            $self->{perfdata}->threshold_validate(label => 'warning-instance-virtual_volume-quota-usage-bytes-' . $_, value => $self->{option_results}->{'warning-instance-virtual_volume-quota-usage-bytes'});
        } elsif (defined($result->{usageWarn}) && $result->{usageWarn} > 0) {
            $self->{perfdata}->threshold_validate(label => 'warning-instance-virtual_volume-quota-usage-bytes-' . $_, value => $result->{usageWarn});
        }

        if (defined($self->{option_results}->{'critical-instance-virtual_volume-quota-usage-bytes'}) && $self->{option_results}->{'critical-instance-virtual_volume-quota-usage-bytes'} ne '') {
            $self->{perfdata}->threshold_validate(label => 'critical-instance-virtual_volume-quota-usage-bytes-' . $_, value => $self->{option_results}->{'critical-instance-virtual_volume-quota-usage-bytes'});
        } elsif (defined($result->{usageCrit}) && $result->{usageCrit} > 0) {
            $self->{perfdata}->threshold_validate(label => 'critical-instance-virtual_volume-quota-usage-bytes-' . $_, value => $result->{usageCrit});
        }

        if (defined($self->{option_results}->{'warning-instance-virtual_volume-quota-files-count'}) && $self->{option_results}->{'warning-instance-virtual_volume-quota-files-count'} ne '') {
            $self->{perfdata}->threshold_validate(label => 'warning-instance-virtual_volume-quota-files-count-' . $_, value => $self->{option_results}->{'warning-instance-virtual_volume-quota-files-count'});
        } elsif (defined($result->{fileCountWarn}) && $result->{fileCountWarn} > 0) {
            $self->{perfdata}->threshold_validate(label => 'warning-instance-virtual_volume-quota-files-count-' . $_, value => $result->{fileCountWarn});
        }

        if (defined($self->{option_results}->{'critical-instance-virtual_volume-quota-files-count'}) && $self->{option_results}->{'critical-instance-virtual_volume-quota-files-count'} ne '') {
            $self->{perfdata}->threshold_validate(label => 'critical-instance-virtual_volume-quota-files-count-' . $_, value => $self->{option_results}->{'critical-instance-virtual_volume-quota-files-count'});
        } elsif (defined($result->{fileCountCrit}) && $result->{fileCountCrit} > 0) {
            $self->{perfdata}->threshold_validate(label => 'critical-instance-virtual_volume-quota-files-count-' . $_, value => $result->{fileCountCrit});
        }
    }
}

1;

__END__

=head1 MODE

Check virtual volumes quotas.

=over 8

=item B<--filter-filesystem-label>

Filter virtual volume quota by filesystem label.

=item B<--filter-volume-name>

Filter virtual volumes quota by volume name.

=item B<--filter-target>

Filter virtual volumes quota by target.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'vvq-detected', 
'vvq-usage', 'vvq-usage-free', 'vvq-usage-prct',
'vvq-files', 'vvq-files-free', 'vvq-files-prct'.

=back

=cut
