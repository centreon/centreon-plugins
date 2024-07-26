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
        "Disk #%s (%s/%s, serial: %s) located %s is %s",
        $self->{result_values}->{id},
        $self->{result_values}->{manufacturer},
        $self->{result_values}->{model},
        $self->{result_values}->{serial},
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
            unknown_default => '%{status} =~ /NOT_DOCUMENTED$/',
            set => {
                key_values => [ { name => 'status' }, { name => 'id' }, { name => 'manufacturer' }, { name => 'model' }, { name => 'serial' }, { name => 'position' } ],
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

    $options{options}->add_options(arguments => {
            'filter-id:s' => { name => 'filter_id' },
            'filter-manufacturer:s' => { name => 'filter_manufacturer' },
            'filter-model:s' => { name => 'filter_model' },
            'filter-position:s' => { name => 'filter_position' },
            'filter-serial:s' => { name => 'filter_serial' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $api_response = $options{custom}->request_api(
        endpoint => '/api/v1/disks'
    );

    my $disks = $api_response->{members};

    $self->{global} = {
        total    => 0,
        normal   => 0,
        degraded => 0,
        new      => 0,
        failed   => 0,
        unknown  => 0
    };



    for my $disk (@{$disks}) {

        my $disk_intro = "disk #" . $disk->{id} . " (" . $disk->{manufacturer} . "/" . $disk->{model}
                        . ", serial: " . $disk->{serialNumber} . ") located '" . $disk->{position};
        # skip if filtered by id
        if (defined($self->{option_results}->{filter_id})
                 and $self->{option_results}->{filter_id} ne ''
                 and $disk->{id} !~ /$self->{option_results}->{filter_id}/) {
            $self->{output}->output_add(long_msg => "Skipping $disk_intro because the id does not match the filter.", debug => 1);
            next;
        }
        # skip if filtered by manufacturer
        if (defined($self->{option_results}->{filter_manufacturer})
                 and $self->{option_results}->{filter_manufacturer} ne ''
                 and $disk->{manufacturer} !~ /$self->{option_results}->{filter_manufacturer}/) {
            $self->{output}->output_add(long_msg => "Skipping $disk_intro because the manufacturer does not match the filter.", debug => 1);
            next;
        }
        # skip if filtered by model
        if (defined($self->{option_results}->{filter_model})
                 and $self->{option_results}->{filter_model} ne ''
                 and $disk->{model} !~ /$self->{option_results}->{filter_model}/) {
            $self->{output}->output_add(long_msg => "Skipping $disk_intro because the model does not match the filter.", debug => 1);
            next;
        }
        # skip if filtered by position
        if (defined($self->{option_results}->{filter_position})
                 and $self->{option_results}->{filter_position} ne ''
                 and $disk->{position} !~ /$self->{option_results}->{filter_position}/) {
            $self->{output}->output_add(long_msg => "Skipping $disk_intro because the position does not match the filter.", debug => 1);
            next;
        }
        # skip if filtered by serial
        if (defined($self->{option_results}->{filter_serial})
                 and $self->{option_results}->{filter_serial} ne ''
                 and $disk->{serial} !~ /$self->{option_results}->{filter_serial}/) {
            $self->{output}->output_add(long_msg => "Skipping $disk_intro because the serial does not match the filter.", debug => 1);
            next;
        }

        my $state = defined($map_state{$disk->{state}}) ? $map_state{$disk->{state}} : 'NOT_DOCUMENTED';

        # increment adequate global counters
        $self->{global}->{total}  = $self->{global}->{total} + 1;
        $self->{global}->{$state} = $self->{global}->{$state} + 1;

        # add the instance
        $self->{disks}->{ $disk->{id} } = {
            status       => $state,
            position     => $disk->{position},
            id           => $disk->{id},
            manufacturer => $disk->{manufacturer},
            model        => $disk->{model},
            serial       => $disk->{serialNumber}
        };
    }
}

1;

__END__

=head1 MODE

Monitor the states of the physical disks.

=over 8

=item B<--filter-id>

Define which disks should be monitored based on their IDs.
This option will be treated as a regular expression.

=item B<--filter-manufacturer>

Define which volumes should be monitored based on the disk manufacturer.
This option will be treated as a regular expression.

=item B<--filter-model>

Define which volumes should be monitored based on the disk model.
This option will be treated as a regular expression.

=item B<--filter-serial>

Define which volumes should be monitored based on the disk serial number.
This option will be treated as a regular expression.

=item B<--filter-position>

Define which volumes should be monitored based on the disk position.
The position is composed of 3 integers, separated by colons:
- Cage number where the physical disk is in.
- Magazine number where the physical disk is in.
- For DC4 cages, disk position within the magazine. For non-DC4 cages, 0.
Example: 7:5:0
This option will be treated as a regular expression.

=item B<--warning-status>

Define the condition to match for the returned status to be WARNING.
Default: '%{status} =~ /^(new|degraded|unknown)$/'

=item B<--critical-status>

Define the condition to match for the returned status to be CRITICAL.
Default: '%{status} =~ /failed/'

=item B<--unknown-status>

Define the condition to match for the returned status to be UNKNOWN.
Default: '%{status} =~ /NOT_DOCUMENTED$/'

=item B<--warning-*> B<--critical-*>

Thresholds. '*' may stand for 'disks-total', 'disks-normal', 'disks-degraded', 'disks-new',
'disks-failed', 'disks-unknown'.

=back

=cut
