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

package apps::scalecomputing::restapi::mode::driveusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use JSON::PP;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "Drive %s %s (%s) is %s - scribe availability %s - scribe reachable: %s",
        $self->{result_values}->{uuid},
        $self->{result_values}->{type},
        $self->{result_values}->{serial},
        $self->{result_values}->{is_healthy} eq "true" ? "healthy" : "not healthy",
        $self->{result_values}->{scribe_availability},
        $self->{result_values}->{scribe_reachable}
    );
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel    => 'drive.space.usage.bytes',
        unit      => 'B',
        instances => $self->{result_values}->{uuid},
        value     => $self->{result_values}->{used},
        warning   => $self->{perfdata}->get_perfdata_for_output(
            label    => 'warning-' . $self->{thlabel},
            total    => $self->{result_values}->{total},
            cast_int => 1
        ),
        critical  => $self->{perfdata}->get_perfdata_for_output(
            label    => 'critical-' . $self->{thlabel},
            total    => $self->{result_values}->{total},
            cast_int => 1
        ),
        min       => 0,
        max       => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value     =>
            $self->{result_values}->{prct_used},
        threshold =>
            [
                { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' }
            ]
    );
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(
        value => $self->{result_values}->{total}
    );
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(
        value => $self->{result_values}->{used}
    );
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(
        value => $self->{result_values}->{free}
    );

    return sprintf(
        "Space used: %s of %s (%.2f%%) free: %s (%.2f%%)",
        $total_used_value . " " . $total_used_unit,
        $total_size_value . " " . $total_size_unit,
        $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit,
        $self->{result_values}->{prct_free}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'drives',
            type             => 1,
            message_multiple => 'All drives are ok',
            skipped_code     => { -10 => 1, -11 => 1 }
        },
    ];

    $self->{maps_counters}->{drives} = [
        {
            label            => 'drive-status',
            type             => 2,
            critical_default =>
                '%{is_healthy} eq "false" || %{current_disposition} !~ %{desired_disposition} || %{scribe_availability} !~ %{online} || %{scribe_reachable} eq "false"',
            set              =>
                {
                    key_values                     =>
                        [
                            { name => 'uuid' },
                            { name => 'type' },
                            { name => 'serial' },
                            { name => 'is_healthy' },
                            { name => 'temperature' },
                            { name => 'errors' },
                            { name => 'scribe_availability' },
                            { name => 'scribe_reachable' }
                        ],
                    closure_custom_output          => $self->can('custom_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
        },
        {
            label      => 'errors',
            nlabel     => 'drive.error.count',
            display_ok => 0,
            set        => {
                key_values      => [ { name => 'errors' } ],
                output_template => 'errors: %d',
                perfdatas       => [
                    { template => '%s', min => 0, cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        {
            label      => 'reallocated-sectors',
            nlabel     => 'drive.reallocatedsectors.count',
            display_ok => 0,
            set        => {
                key_values      => [ { name => 'reallocated_sectors' } ],
                output_template => 'reallocated-sectors: %d',
                perfdatas       => [
                    { template => '%s', min => 0, cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        {
            label      => 'temperature',
            nlabel     => 'drive.temperature.celsius',
            display_ok => 0,
            set        => {
                key_values      => [ { name => 'temperature' } ],
                output_template => 'temperature: %d C',
                perfdatas       => [
                    { template => '%d', min => 0, unit => 'C', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        {
            label => 'usage',
            set   => {
                key_values                     =>
                    [
                        { name => 'prct_used' },
                        { name => 'used' },
                        { name => 'free' },
                        { name => 'prct_free' },
                        { name => 'total' },
                        { name => 'uuid' },
                        { name => 'type' },
                        { name => 'serial' },
                        { name => 'uuid' }
                    ],
                closure_custom_output          =>
                    $self->can('custom_usage_output'),
                closure_custom_perfdata        =>
                    $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check =>
                    $self->can('custom_usage_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'uuid:s'             => { name => 'uuid' },
            'filter-node-uuid:s' => { name => 'filter_node_uuid' },
            'filter-type:s'      => { name => 'filter_type' },
            'filter-serial:s'    => { name => 'filter_serial' }
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{drives} = {};

    my $drives = $options{custom}->list_drives();
    foreach my $drive (@{$drives}) {
        if (defined($self->{option_results}->{uuid}) && $self->{option_results}->{uuid} ne '' &&
            $drive->{uuid} !~ /$self->{option_results}->{uuid}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $drive->{uuid} . "'.", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $drive->{type} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $drive->{type} . "'.", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_node_uuid}) && $self->{option_results}->{filter_node_uuid} ne '' &&
            $drive->{nodeUUID} !~ /$self->{option_results}->{filter_node_uuid}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $drive->{nodeUUID} . "'.", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_serial}) && $self->{option_results}->{filter_serial} ne '' &&
            $drive->{serial} !~ /$self->{option_results}->{filter_serial}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $drive->{serial} . "'.", debug => 1);
            next;
        }

        push @{$self->{filtered_drives}}, $drive;
    }

    for my $drive (@{$self->{filtered_drives}}) {
        my $total = $drive->{capacityBytes};
        my $used = $drive->{usedBytes};
        my $free = $total - $used;

        # add the instance
        $self->{drives}->{ $drive->{uuid} } = {
            uuid                => $drive->{uuid},
            type                => $drive->{type},
            serial              => $drive->{serialNumber},
            errors              => $drive->{errorCount},
            reallocated_sectors => $drive->{reallocatedSectors},
            temperature         => $drive->{temperature},
            desired_disposition => $drive->{desiredDisposition},
            current_disposition => $drive->{currentDisposition},
            is_healthy          => $drive->{isHealthy} == JSON::PP::true ? "true" : "false",
            total               => $total,
            used                => $used,
            free                => $free,
            prct_used           => $total > 0 ? $used * 100 / $total : 0,
            prct_free           => $total > 0 ? $free * 100 / $total : 0
        };

        if (defined($drive->{disks}) && defined($drive->{disks}->{scribe})) {
            $self->{drives}->{ $drive->{uuid} }->{scribe_availability} = $drive->{disks}->{scribe}->{availability};
            $self->{drives}->{ $drive->{uuid} }->{scribe_reachable} = $drive->{disks}->{scribe}->{isReachable} == JSON::PP::true ?
                "true" :
                "false";
        } else {
            $self->{drives}->{ $drive->{uuid} }->{scribe_availability} = "not present";
            $self->{drives}->{ $drive->{uuid} }->{scribe_reachable} = "not present";
        }
    }

    if (scalar(keys %{$self->{drives}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No drive found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check drive usage.

=over 8

=item B<--uuid>

cluster to check. If not set, we check all clusters.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (%), 'errors', 'reallocated-sectors', 'temperature' (C).

=item B<--unknown-drive-status>

Define the conditions to match for the drive status to be UNKNOWN (default: '').
You can use the following variables: %{is_healthy}, %{current_disposition}, %{desired_disposition}, %{scribe_availability}, %{scribe_reachable}, %{type}

=item B<--warning-drive-status>

Define the conditions to match for the drive status to be WARNING (default: '').
You can use the following variables: %{is_healthy}, %{current_disposition}, %{desired_disposition}, %{scribe_availability}, %{scribe_reachable}, %{type}

=item B<--critical-drive-status>

Define the conditions to match for the drive status to be CRITICAL (default: '%{is_healthy} eq "false" || %{current_disposition} !~ %{desired_disposition} || %{scribe_availability} !~ %{online} || %{scribe_reachable} eq "false"').
You can use the following variables: %{is_healthy}, %{current_disposition}, %{desired_disposition}, %{scribe_availability}, %{scribe_reachable}, %{type}

=back

=cut
