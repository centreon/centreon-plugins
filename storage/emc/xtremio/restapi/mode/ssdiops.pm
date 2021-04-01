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

package storage::emc::xtremio::restapi::mode::ssdiops;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'ssd', type => 1, cb_prefix_output => 'prefix_ssd_output', message_multiple => 'All SSDs usages are ok' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total : %s iops',
                perfdatas => [
                    { label => 'total', value => 'total', template => '%s',
                      min => 0, unit => 'iops' },
                ],
            }
        },
        { label => 'total-read', set => {
                key_values => [ { name => 'total_read' } ],
                output_template => 'Total read : %s iops',
                perfdatas => [
                    { label => 'total_read', value => 'total_read', template => '%s',
                      min => 0, unit => 'iops' },
                ],
            }
        },
        { label => 'total-write', set => {
                key_values => [ { name => 'total_write' } ],
                output_template => 'Total write : %s iops',
                perfdatas => [
                    { label => 'total_write', value => 'total_write', template => '%s',
                      min => 0, unit => 'iops' },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{ssd} = [
        { label => 'global', set => {
                key_values => [ { name => 'global_iops' }, { name => 'display' }, ],
                output_template => 'Global : %s iops',
                perfdatas => [
                    { label => 'global', value => 'global_iops', template => '%s',
                      min => 0, unit => 'iops', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'read', set => {
                key_values => [ { name => 'read_iops' }, { name => 'display' }, ],
                output_template => 'Read : %s iops',
                perfdatas => [
                    { label => 'read', value => 'read_iops', template => '%s',
                      min => 0, unit => 'iops', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write', set => {
                key_values => [ { name => 'write_iops' }, { name => 'display' }, ],
                output_template => 'Write : %s iopss',
                perfdatas => [
                    { label => 'write', value => 'write_iops', template => '%s',
                      min => 0, unit => 'iops', label_extra_instance => 1, instance_use => 'display' },
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
        "filter-name:s"       => { name => 'filter_name' },
    });

    return $self;
}

sub prefix_ssd_output {
    my ($self, %options) = @_;
    
    return "SSD '" . $options{instance_value}->{display} . "' Usage ";
}

sub manage_selection {
    my ($self, %options) = @_;

    my $urlbase = '/api/json/types/';
    my @items = $options{custom}->get_items(
        url => $urlbase,
        obj => 'ssds'
    );

    $self->{ssd} = {};
    $self->{global} = { total => 0, total_read => 0, total_write => 0 };
    foreach my $item (@items) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $item !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $item . "': no matching name.", debug => 1);
            next;
        }
        
        my $details = $options{custom}->get_details(
            url  => $urlbase,
            obj  => 'ssds',
            name => $item
        );

        $self->{global}->{total} += $details->{iops};
        $self->{global}->{total_read} += $details->{'rd-iops'};
        $self->{global}->{total_write} += $details->{'wr-iops'};
        $self->{ssd}->{$item} = {
            display => $item, 
            global_iops => $details->{iops},
            read_iops => $details->{'rd-iops'},
            write_iops => $details->{'wr-iops'},
        };
    }
    
    if (scalar(keys %{$self->{ssd}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check SSDs usage.

=over 8

=item B<--warning-*> B<--critical-*>

Threshold warning (number of iops)
Can be: 'total', 'total-read', 'total-write',
'global', 'read', 'write'.

=item B<--filter-name>

Filter SSD name (can be a regexp). (e.g --filter-name '.*' for all SSDs)

=back

=cut
