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

package storage::hp::3par::ssh::mode::afc;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_space_usage_output {
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

sub node_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking node '%s' afc",
        $options{instance_value}->{node_id}
    );
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return sprintf(
        "node '%s' afc ",
        $options{instance_value}->{node_id}
    );
}

sub volume_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking volume '%s' afc",
        $options{instance_value}->{volume_name}
    );
}

sub prefix_volume_output {
    my ($self, %options) = @_;

    return sprintf(
        "volume '%s' afc ",
        $options{instance_value}->{volume_name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'nodes', type => 3, cb_prefix_output => 'prefix_node_output', cb_long_output => 'node_long_output', indent_long_output => '    ', message_multiple => 'All nodes afc are ok',
            group => [
                { name => 'global', type => 0 },
                { name => 'space', type => 0 },
                { name => 'node_fmp', type => 0 }
            ]
        },
        {
            name => 'volumes', type => 3, cb_prefix_output => 'prefix_volume_output', cb_long_output => 'volume_long_output', indent_long_output => '    ', message_multiple => 'All volumes afc are ok',
            group => [
                { name => 'volume_fmp', type => 0 }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{status} !~ /normal/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'node_id' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{space} = [
        { label => 'flashcache-usage', nlabel => 'node.flashcache.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'flashcache-usage-free', nlabel => 'node.flashcache.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'flashcache-usage-prct', nlabel => 'node.flashcache.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{node_fmp} = [
        { label => 'flashcache-node-readhits', nlabel => 'node.flashcache.readhits.percentage', set => {
                key_values => [ { name => 'readhits' } ],
                output_template => 'read hits: %s%%',
                perfdatas => [
                    { template => '%s', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{volume_fmp} = [
        { label => 'flashcache-volume-readhits', nlabel => 'volume.flashcache.readhits.percentage', set => {
                key_values => [ { name => 'readhits' } ],
                output_template => 'read hits: %s%%',
                perfdatas => [
                    { template => '%s', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
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
        'filter-node-id:s'     => { name => 'filter_node_id' },
        'filter-volume-name:s' => { name => 'filter_volume_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($content) = $options{custom}->execute_command(
        commands => [
            'echo "===showflashcache==="',
            'showflashcache',
            'echo "===statcachenode==="',
            'statcache -iter 1 -d 1',
            'echo "===statcachevolume==="',
            'statcache -iter 1 -d 1 -v'
        ]
    );

    #Node Mode  State     Size Used%
    #   0 SSD   normal  393216    49
    #   1 SSD   normal  393216    49

    $self->{nodes} = {};
    if ($content =~ /===showflashcache===(.*?)(?====|\Z$)/msi) {
        my $entry = $1;
        while ($entry =~ /^\s*(\d+)\s+\S+\s+(\S+)\s+(\S+)\s+(\S+)/mg) {
            my ($node_id, $status, $size, $prct_used) = ($1, $2, $3 * 1024 * 1024, $4);

            next if (defined($self->{option_results}->{filter_node_id}) && $self->{option_results}->{filter_node_id} ne '' &&
                $node_id !~ /$self->{option_results}->{filter_node_id}/);
            
            $self->{nodes}->{'node' . $node_id} = {
                node_id => $node_id,
                global => {
                    node_id => $node_id,
                    status => $status
                },
                space => {
                    total => $size,
                    used => $prct_used * $size / 100,
                    free => $size - ($prct_used * $size / 100),
                    prct_used => $prct_used,
                    prct_free => 100 - $prct_used
                }
            };
        }
    }

    if ($content =~ /===statcachenode===(.*?)(?====|\Z$)/msi) {
        my $entry = $1;
        if ($entry =~ /CMP\s+FMP\s+Total(.*?)Internal\s+Flashcache\s+Activity/ms) {
            my $stat = $1;
            while ($stat =~ /^\s*(\d+)\s+Read\s+\d+\s+\d+\s+(\d+)/mg) {
                my ($node_id, $readhits) = ($1, $2);
                next if (!defined($self->{nodes}->{'node' . $node_id}));
                $self->{nodes}->{'node' . $node_id}->{node_fmp} = { readhits => $readhits };
            }
        }
    }

    $self->{volumes} = {};
    if ($content =~ /===statcachevolume===(.*?)(?====|\Z$)/msi) {
        my $entry = $1;
        if ($entry =~ /CMP\s+FMP\s+Total(.*?)Internal\s+Flashcache\s+Activity/ms) {
            my $stat = $1;
            while ($stat =~ /^\s*\d+\s+(\S+)\s+Read\s+\d+\s+\d+\s+(\d+)/mg) {
                my ($volume_name, $readhits) = ($1, $2);

                next if (defined($self->{option_results}->{filter_volume_name}) && $self->{option_results}->{filter_volume_name} ne '' &&
                    $volume_name !~ /$self->{option_results}->{filter_volume_name}/);

                $self->{volumes}->{$volume_name} = {
                    volume_name => $volume_name,
                    volume_fmp => { readhits => $readhits }
                };
            }
        }
    }

    if (scalar(keys %{$self->{nodes}}) <= 0 && scalar(keys %{$self->{volumes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Couldn't get afc information");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check adaptive flash cache.

=over 8

=item B<--filter-node-id>

Filter nodes by ID (can be a regexp).

=item B<--filter-volume-name>

Filter volumes by name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /normal/i')
You can use the following variables: %{status}, %{node_id}

=item B<--warning-*>

Define the WARNING thresholds for the following components:
'flashcache-usage', 'flashcache-usage-free', 'flashcache-usage-prct',
'flashcache-node-readhits', 'flashcache-volume-readhits'.

=item B<--critical-*>

Define the CRITICAL thresholds for the following components:
'flashcache-usage', 'flashcache-usage-free', 'flashcache-usage-prct',
'flashcache-node-readhits', 'flashcache-volume-readhits'.

=back

=cut
