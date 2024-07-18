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

package storage::hp::primera::restapi::mode::diskstatus;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

use strict;
use warnings;

my %map_state = (
        1  => 'normal',
        2  => 'degraded',
        3  => 'new',
        4  => 'failed',
        99 => 'unknown'
);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "Disk %s (position %s) is %s",
        $self->{result_values}->{name},
        $self->{result_values}->{position},
        $self->{result_values}->{status}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Disks ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', cb_prefix_output => 'prefix_global_output', type => 0 },
        { name => 'disks', type => 1, message_multiple => 'All disks are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'disks-total', nlabel => 'disks.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'disks-normal', nlabel => 'disks.normal.count', set => {
                key_values => [ { name => 'normal' }, { name => 'total' } ],
                output_template => 'normal: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'disks-degraded', nlabel => 'disks.degraded.count', set => {
                key_values => [ { name => 'degraded' }, { name => 'total' } ],
                output_template => 'degraded: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'disks-new', nlabel => 'disks.new.count', set => {
                key_values => [ { name => 'new' }, { name => 'total' } ],
                output_template => 'new: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'disks-failed', nlabel => 'disks.failed.count', set => {
                key_values => [ { name => 'failed' }, { name => 'total' } ],
                output_template => 'failed: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'disks-unknown', nlabel => 'disks.unknown.count', set => {
                key_values => [ { name => 'unknown' }, { name => 'total' } ],
                output_template => 'unknown: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];
    $self->{maps_counters}->{disks} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{status} =~ /^(new|degraded|unknown)$/',
            critical_default => '%{status} =~ /failed/',
            set => {
                key_values => [ { name => 'status' }, { name => 'name' }, { name => 'position' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $api_response = $options{custom}->request_api(
        endpoint => '/api/v1/disks'
    );

    $self->{global} = {
        total    => $api_response->{total},
        normal   => 0,
        degraded => 0,
        new      => 0,
        failed   => 0,
        unknown => 0
    };
    my $disks = $api_response->{members};

    for my $disk (@{$disks}) {
        my $state = $map_state{$disk->{state}};

        # increment adequate global counter
        $self->{global}->{$state} = $self->{global}->{$state} + 1;

        # add the instance
        my $instance = $disk->{manufacturer} . '-' . $disk->{model} . '-' . $disk->{serialNumber};
        $self->{disks}->{$instance} = { name => $instance, status => $state, position => $disk->{position} };
    }
}

1;

__END__

=head1 MODE

Monitor the states of the physical disks.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds. '*' may stand for 'disks-total', 'disks-normal', 'disks-degraded', 'disks-new',
'disks-failed', 'disks-unknown'.

=item B<--warning-status>

Define the condition to match for the returned status to be WARNING.
Default: '%{status} =~ /^(new|degraded|unknown)$/'

=item B<--critical-status>

Define the condition to match for the returned status to be CRITICAL.
Default: '%{status} =~ /failed/'

=item B<--unknown-status>

Define the condition to match for the returned status to be UNKNOWN.

=back

=cut
