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

package storage::emc::DataDomain::snmp::mode::filesystems;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use storage::emc::DataDomain::snmp::lib::functions;

sub custom_disk_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub fs_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking filesystem '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_fs_output {
    my ($self, %options) = @_;

    return sprintf(
        "filesystem '%s' ",
        $options{instance_value}->{name}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of filesystems ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'fs', type => 3, cb_prefix_output => 'prefix_fs_output', cb_long_output => 'fs_long_output', indent_long_output => '    ', message_multiple => 'All filesystems are ok',
            group => [
                { name => 'space', type => 0, skipped_code => { -10 => 1 } },
                { name => 'precomp', type => 0, skipped_code => { -10 => 1 } },
                { name => 'cleanable', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'fs-detected', display_ok => 0, nlabel => 'filesystems.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{space} = [
        { label => 'space-usage', nlabel => 'filesystem.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_disk_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'space-usage-free', nlabel => 'filesystem.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_disk_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'space-usage-prct', nlabel => 'filesystem.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_disk_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{precomp} = [
        { label => 'space-precompression-usage', nlabel => 'filesystem.precompression.space.usage.bytes', set => {
                key_values => [ { name => 'size' }, { name => 'name' } ],
                output_template => 'space precompression used: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cleanable} = [
        { label => 'space-cleanable', nlabel => 'filesystem.space.cleanable.bytes', set => {
                key_values => [ { name => 'space_cleanable' }, { name => 'name' } ],
                output_template => 'space cleanable: %s%s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'name' }
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
        'filter-fs-name:s' => { name => 'filter_fs_name' }
    });

    return $self;
}

my $oid_fileSystemSpaceEntry = '.1.3.6.1.4.1.19746.1.3.2.1.1';
my $oid_sysDescr = '.1.3.6.1.2.1.1.1.0'; # 'Data Domain OS 5.4.1.1-411752'
my ($oid_fileSystemResourceName, $oid_fileSystemSpaceUsed, $oid_fileSystemSpaceAvail);
my ($oid_fileSystemSpaceCleanable);

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ $oid_sysDescr ],
        nothing_quit => 1
    );
    if (!($self->{os_version} = storage::emc::DataDomain::snmp::lib::functions::get_version(value => $snmp_result->{$oid_sysDescr}))) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'Cannot get DataDomain OS version.'
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    $snmp_result = $options{snmp}->get_table(
        oid => $oid_fileSystemSpaceEntry,
        nothing_quit => 1
    );

    if (centreon::plugins::misc::minimal_version($self->{os_version}, '5.x')) {
        $oid_fileSystemResourceName = '.1.3.6.1.4.1.19746.1.3.2.1.1.3';
        $oid_fileSystemSpaceUsed = '.1.3.6.1.4.1.19746.1.3.2.1.1.5';
        $oid_fileSystemSpaceAvail = '.1.3.6.1.4.1.19746.1.3.2.1.1.6';
        $oid_fileSystemSpaceCleanable = '.1.3.6.1.4.1.19746.1.3.2.1.1.8';
    } else {
        $oid_fileSystemResourceName = '.1.3.6.1.4.1.19746.1.3.2.1.1.2';
        $oid_fileSystemSpaceUsed = '.1.3.6.1.4.1.19746.1.3.2.1.1.4';
        $oid_fileSystemSpaceAvail = '.1.3.6.1.4.1.19746.1.3.2.1.1.5';
    }

    $self->{global} = { detected => 0 };
    $self->{fs} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$oid_fileSystemResourceName\.(\d+)$/);
        my $instance = $1;

        my $name = $snmp_result->{$oid_fileSystemResourceName . '.' . $instance}; 
        my $precomp = 0;
        my $postcomp = 0;

        $precomp = 1 if ($name =~ /:\s*pre-comp/);
        $postcomp = 1 if ($name =~ /:\s*post-comp/);
        $name =~ s/:\s*(pre-comp|post-comp).*//;

        next if (defined($self->{option_results}->{filter_fs_name}) && $self->{option_results}->{filter_fs_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_fs_name}/);

        my $used = int($snmp_result->{$oid_fileSystemSpaceUsed . '.' . $instance} * 1024 * 1024 * 1024);
        my $free = int($snmp_result->{$oid_fileSystemSpaceAvail . '.' . $instance} * 1024 * 1024 * 1024);
        my $total = $used + $free;

        next if ($total == 0);

        $self->{global}->{detected}++;

        if (!defined($self->{fs}->{$name})) {
            $self->{fs}->{$name} = {
                name => $name,
                space => {},
                precomp => {},
                cleanable => {}
            };
        }

        if ($precomp == 0) {
            $self->{fs}->{$name}->{space} = {
                name => $name,
                used => $used,
                free => $free,
                total => $total,
                prct_used => $used * 100 / $total,
                prct_free => $free * 100 / $total
            };
            if (defined($oid_fileSystemSpaceCleanable) && defined($snmp_result->{$oid_fileSystemSpaceCleanable . '.' . $instance})) {
                $self->{fs}->{$name}->{cleanable} = {
                    name => $name,
                    space_cleanable => int($snmp_result->{$oid_fileSystemSpaceCleanable . '.' . $instance} * 1024 * 1024 * 1024)
                };
            }
        } else {
            $self->{fs}->{$name}->{precomp} = {
                name => $name,
                size => $used
            };
        }
    }
}

1;

__END__

=head1 MODE

Check filesystems. 

=over 8

=item B<--filter-fs-name>

Check filesystems by name.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'fs-detected', 'space-usage, 'space-usage-free',
'space-usage-prct', 'space-precompression-usage', 'space-cleanable'.

=back

=cut
