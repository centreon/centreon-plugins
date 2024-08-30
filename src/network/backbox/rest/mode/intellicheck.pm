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

package network::backbox::rest::mode::intellicheck;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_intellicheck_output {
    my ($self, %options) = @_;

    return "Intellicheck " . $options{instance_value}->{id} . " '" . $options{instance_value}->{name} . "' - ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'intellichecks', type => 1, cb_prefix_output => 'prefix_intellicheck_output', message_multiple => 'All intellichecks are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{intellichecks} = [
        { label => 'total', nlabel => 'intellicheck.total.count', set => {
            key_values      => [ { name => 'total' } ],
            output_template => 'total: %d',
            perfdatas       => [
                { value => 'total', template => '%d', min => 0, label_extra_instance => 1 }
            ]
        }
        },
        { label => 'success', nlabel => 'intellicheck.success.count', set => {
            key_values      => [ { name => 'success' } ],
            output_template => 'success: %d',
            perfdatas       => [
                { value => 'success', template => '%d', min => 0, label_extra_instance => 1 }
            ]
        }
        },
        { label => 'suspect', nlabel => 'intellicheck.suspect.count', set => {
            key_values      => [ { name => 'suspect' } ],
            output_template => 'suspect: %d',
            perfdatas       => [
                { value => 'suspect', template => '%d', min => 0, label_extra_instance => 1 }
            ]
        }
        },
        { label => 'failure', nlabel => 'intellicheck.failure.count', set => {
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
        'filter-type:s' => { name => 'filter_type' },
        'report-id:s'   => { name => 'report_id' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!centreon::plugins::misc::is_empty($self->{option_results}->{report_id}) && centreon::plugins::misc::is_empty($self->{option_results}->{filter_type})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --filter-type option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $intellichecks = $options{custom}->get_intelli_check_status();
    for $intellichecks (@$intellichecks) {
        $self->{intellichecks}->{$intellichecks->{name}} = {
            name    => $intellichecks->{name},
            id      => $intellichecks->{id},
            success => $intellichecks->{successDevices},
            suspect => $intellichecks->{suspectDevices},
            failure => $intellichecks->{failureDevices},
            total   => $intellichecks->{total_devices}
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
