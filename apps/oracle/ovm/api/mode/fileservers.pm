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

package apps::oracle::ovm::api::mode::fileservers;

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

sub fileserver_long_output {
    my ($self, %options) = @_;

    return "checking file server '" . $options{instance_value}->{name} . "'";
}

sub prefix_fileserver_output {
    my ($self, %options) = @_;
    
    return "File server '" . $options{instance_value}->{name} . "' ";
}

sub prefix_fs_output {
    my ($self, %options) = @_;

    return "filesystem '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'fileservers', type => 3, cb_prefix_output => 'prefix_fileserver_output', cb_long_output => 'fileserver_long_output', indent_long_output => '    ', message_multiple => 'All file servers are ok',
            group => [
                { name => 'filesystems', type => 1, display_long => 1, cb_prefix_output => 'prefix_fs_output', message_multiple => 'filesystems are ok', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{filesystems} = [
        { label => 'space-usage', nlabel => 'serverpool.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-free', nlabel => 'serverpool.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-prct', nlabel => 'serverpool.space.usage.percentage', display_ok => 0, set => {
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
        'filter-fileserver-name:s' => { name => 'filter_fileserver_name' },
        'filter-filesystem-name:s' => { name => 'filter_filesystem_name' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $manager = $options{custom}->request_api(endpoint => '/Manager');
    if ($manager->[0]->{managerRunState} ne 'RUNNING') {
        $self->{output}->add_option_msg(short_msg => 'manager is not running.');
        $self->{output}->option_exit();
    }

    my $fileservers = $options{custom}->request_api(endpoint => '/FileServer');
    my $filesystems = $options{custom}->request_api(endpoint => '/FileSystem');

    $self->{fileservers} = {};
    foreach my $fileserver (@$fileservers) {
        my $name = $fileserver->{id}->{value};
        $name = $fileserver->{name}
            if (defined($fileserver->{name}) && $fileserver->{name} ne '');

        if (defined($self->{option_results}->{filter_fileserver_name}) && $self->{option_results}->{filter_fileserver_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_fileserver_name}/) {
            $self->{output}->output_add(long_msg => "skipping file server '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{fileservers}->{$name} = {
            name => $name,
            filesystems => {}
        };

        foreach my $filesystem (@{$fileserver->{fileSystemIds}}) {
            foreach my $target (@$filesystems) {
                if ($filesystem->{value} eq $target->{id}->{value}) {
                    my $fs_name = $target->{id}->{value};
                    $fs_name = $target->{name}
                        if (defined($target->{name}) && $target->{name} ne '');

                    if (defined($self->{option_results}->{filter_filesystem_name}) && $self->{option_results}->{filter_filesystem_name} ne '' &&
                        $fs_name !~ /$self->{option_results}->{filter_filesystem_name}/) {
                        $self->{output}->output_add(long_msg => "skipping file system '" . $fs_name . "': no matching filter.", debug => 1);
                        next;
                    }

                    my $total_space = $target->{size};
                    my $usable_space = $target->{freeSize};
                    $self->{fileservers}->{$name}->{filesystems}->{$fs_name} = {
                        name => $fs_name,
                        total_space => $total_space,
                        used_space => $total_space - $usable_space,
                        free_space => $usable_space,
                        prct_used_space => ($total_space - $usable_space) * 100 / $total_space,
                        prct_free_space => $usable_space * 100 / $total_space
                    };
                    last;
                }
            }
        }
    }
}

1;

__END__

=head1 MODE

Check file servers.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^space-usage$'

=item B<--filter-fileserver-name>

Filter file servers by name (can be a regexp).

=item B<--filter-filesystem-name>

Filter file systems by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage' (B), 'space-usage-free' (B), 'space-usage-prct' (%).

=back

=cut
