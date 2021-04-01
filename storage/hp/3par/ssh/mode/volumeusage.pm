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

package storage::hp::3par::ssh::mode::volumeusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my $msg = sprintf("Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                   $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'volume', type => 1, cb_prefix_output => 'prefix_volume_output', message_multiple => 'All volumes are ok' },
    ];
    
    $self->{maps_counters}->{volume} = [
        { label => 'usage', nlabel => 'volume.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { label => 'used', value => 'used', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'volume.space.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { label => 'free', value => 'free', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'volume.space.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'display' } ],
                output_template => 'Used : %.2f %%',
                perfdatas => [
                    { label => 'used_prct', value => 'prct_used', template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "filter-name:s"       => { name => 'filter_name' },
    });
    
    return $self;
}

sub prefix_volume_output {
    my ($self, %options) = @_;
    
    return "Volume '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($result, $exit) = $options{custom}->execute_command(commands => ['showvv -showcols Id,Name,VSize_MB,Snp_Rsvd_MB,Snp_Used_MB,Adm_Rsvd_MB,Adm_Used_MB,Usr_Rsvd_MB,Usr_Used_MB']);

    #  Id Name                             VSize_MB Snp_Rsvd_MB Snp_Used_MB Adm_Rsvd_MB Adm_Used_MB Usr_Rsvd_MB Usr_Used_MB
    #2056 .srdata                             81920           0           0           0           0       81920       81920
    #   0 admin                               10240           0           0           0           0       10240       10240
    # 494 DFS_DATA01                        4608000           0           0        2560        2032     3156864     3147727
    # 495 DFS_DATA02                        1126400           0           0        1024         612      979072      966739
    # 496 DFS_DATA03                       16777216           0           0       10240        9576    15281920    15281185

    $self->{volume} = {};
    my @lines = split /\n/, $result;
    foreach (@lines) {
        next if (!/^\s*\d+\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
        my ($name, $total, $snap_used, $adm_used, $usr_used) = ($1, $2 * 1024 * 1024, $4 * 1024 * 1024, $6 * 1024 * 1024, $8 * 1024 * 1024);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping volume '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        my $used = $snap_used + $adm_used + $usr_used;
        $self->{volume}->{$name} = {
            display => $name,
            total => $total,
            used => $used,
            free => ($total - $used) >= 0 ? ($total - $used) : 0,
            prct_used => $used * 100 / $total,
            prct_free => (100 - ($used * 100 / $total) >= 0) ? (100 - ($used * 100 / $total)) : 0,
        };
    }
    
    if (scalar(keys %{$self->{volume}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No volume found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check volume usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^usage$'

=item B<--filter-name>

Filter volume name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
