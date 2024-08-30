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

package network::backbox::rest::mode::backup;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_backup_output {
    my ($self, %options) = @_;

    return "Backup '" . $options{instance_value}->{name} . "' - ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'backups', type => 1, cb_prefix_output => 'prefix_backup_output', message_multiple => 'All backups are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{backups} = [
        { label => 'total', nlabel => 'backups.total.count', set => {
            key_values      => [ { name => 'total' } ],
            output_template => 'total: %d',
            perfdatas       => [
                { value => 'total', template => '%d', min => 0, label_extra_instance => 1 }
            ]
        }
        },
        { label => 'success', nlabel => 'backups.success.count', set => {
            key_values      => [ { name => 'success' } ],
            output_template => 'success: %d',
            perfdatas       => [
                { value => 'success', template => '%d', min => 0, label_extra_instance => 1 }
            ]
        }
        },
        { label => 'suspect', nlabel => 'backups.suspect.count', set => {
            key_values      => [ { name => 'suspect' } ],
            output_template => 'suspect: %d',
            perfdatas       => [
                { value => 'suspect', template => '%d', min => 0, label_extra_instance => 1 }
            ]
        }
        },
        { label => 'failure', nlabel => 'backups.failure.count', set => {
            key_values      => [ { name => 'failure' } ],
            output_template => 'failure: %d',
            perfdatas       => [
                { value => 'failure', template => '%d', min => 0, label_extra_instance => 1 }
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
        'filter-type:s' => { name => 'filter_type' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $backups = $options{custom}->get_backup_jobs_status();
    for $backups (@$backups) {
        $self->{backups}->{$backups->{name}} = {
            name    => $backups->{name},
            total   => $backups->{totalDevices},
            success => $backups->{successDevices},
            suspect => $backups->{suspectDevices},
            failure => $backups->{failureDevices}
        };
    }
}
1;

__END__

=head1 MODE

Check Backbox backups.

=over 8

=item B<--filter-type>

Filter backups by type.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'failure', 'suspect', 'success', 'total'.

=back

=cut
