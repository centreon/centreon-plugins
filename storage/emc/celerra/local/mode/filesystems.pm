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

package storage::emc::celerra::local::mode::filesystems;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_space});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space}
    );
}

sub pool_long_output {
    my ($self, %options) = @_;

    return "checking pool '" . $options{instance_value}->{name} . "'";
}

sub prefix_pool_output {
    my ($self, %options) = @_;

    return "Pool '" . $options{instance_value}->{name} . "' ";
}

sub prefix_fs_output {
    my ($self, %options) = @_;
    
    return "filesystem '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'pools', type => 3, cb_prefix_output => 'prefix_pool_output', cb_long_output => 'pool_long_output', indent_long_output => '    ', message_multiple => 'All pools are ok',
            group => [
                { name => 'fs', display_long => 1, cb_prefix_output => 'prefix_fs_output', message_multiple => 'filesystems are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{fs} = [
        { label => 'space-usage', nlabel => 'filesystem.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-free', nlabel => 'filesystem.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-prct', nlabel => 'filesystem.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' }, { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
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
        'filter-pool-name:s'       => { name => 'filter_pool_name' },
        'filter-filesystem-name:s' => { name => 'filter_filesystem_name' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'NAS_DB=/nas /nas/bin/nas_fs -query:inuse==y:type=uxfs:IsRoot=False:RWServersNumeric==1 -fields:RWservers,rwvdms,StoragePoolName,Name,PctUsed,MaxSize -format:%L,%L,%s,%s,%d,%d----',
        command_options => '2>&1',
    );

    my $content = '';
    $content = $1 if ($stdout =~ /^(.*)----$/m);

    $self->{pools} = {};
    foreach my $entry (split(/----/, $stdout)) {
        my ($servers, $vdms, $pool_name, $fs_name, $prct_used, $size) = split(/,/, $entry);
        if (defined($self->{option_results}->{filter_pool_name}) && $self->{option_results}->{filter_pool_name} ne '' &&
            $pool_name !~ /$self->{option_results}->{filter_pool_name}/) {
            $self->{output}->output_add(long_msg => "skipping filesystem '" . $fs_name . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_filesystem_name}) && $self->{option_results}->{filter_filesystem_name} ne '' &&
            $fs_name !~ /$self->{option_results}->{filter_filesystem_name}/) {
            $self->{output}->output_add(long_msg => "skipping filesystem '" . $fs_name . "': no matching filter.", debug => 1);
            next;
        }

        if (!defined($self->{pools}->{$pool_name})) {
            $self->{pools}->{$pool_name} = {
                name => $pool_name,
                fs => {}
            };
        }

        $size *= 1024 * 1024;
        my $used_space = int($prct_used * $size / 100);
        $self->{pools}->{$pool_name}->{fs}->{$fs_name} = {
            name => $fs_name,
            total_space => $size,
            used_space => $used_space,
            free_space => $size - $used_space,
            prct_used_space => $prct_used,
            prct_free_space => 100 - $prct_used
        };
    }
}

1;

__END__

=head1 MODE

Check filesystems.

Command used: NAS_DB=/nas /nas/bin/nas_fs -query:inuse==y:type=uxfs:IsRoot=False:RWServersNumeric==1 -fields:RWservers,rwvdms,StoragePoolName,Name,PctUsed,MaxSize -format:%L,%L,%s,%s,%d,%d---- 2>&1

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='usage$'

=item B<--filter-pool-name>

Filter filesystems by pool name (can be a regexp).

=item B<--filter-filesystem-name>

Filter filesystems by filesystem name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage' (B), 'space-usage-free' (B), 'space-usage-prct' (%).

=back

=cut
