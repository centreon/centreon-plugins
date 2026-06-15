#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package cloud::openshift::api::mode::clusterversion;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc qw(exprintf is_not_empty int_to_bool bool_to_int value_of);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, use_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {   name => 'global', type => COUNTER_TYPE_GLOBAL }
    ];

    $self->{maps_counters}->{global} = [
        {   label => 'status', nlabel => 'clusterversion.status',
            type => COUNTER_KIND_TEXT, critical_default => '%{available} =~ /false/ || %{failing} =~ /true/',
            set => {
                key_values => [ { name => 'human_status' }, { name => 'current_version' }, { name => 'channel' }, { name => 'desired_version' },
                                { name => 'available' }, { name => 'progressing' }, { name => 'failing' }, { name => 'upgradeable' }, { name => 'retrievedupdates' },
                                { name => 'perf_available' }, { name => 'perf_progressing' }, { name => 'perf_failing' }, { name => 'perf_upgradeable' }, { name => 'perf_retrievedupdates' },
                                { name => 'updates_available' },
                              ],
                output_template => "OpenShift %{current_version} [%{channel}] - %{human_status}",
                perfdatas => [
                    { value => 'perf_available', label => 'available', template => '%s', min => 0, max => 1 },
                    { value => 'perf_progressing',  label => 'progressing', template => '%s', min => 0, max => 1 },
                    { value => 'perf_failing',  label => 'failing', template => '%s', min => 0, max => 1 },
                    { value => 'perf_upgradeable',  label => 'upgradeable', template => '%s', min => 0, max => 1 },
                    { value => 'perf_retrievedupdates',  label => 'retrievedupdates', template => '%s', min => 0, max => 1 },
                    { value => 'updates_available',  label => 'updates_available', template => '%s', min => 0 }
                ],
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {
        human_status => '',
        current_version => '-',
        desired_version => '-',
        channel => '-',
        perf_available => 0,
        perf_progressing => 0,
        perf_failing => 0,
        perf_upgradeable => 0,
        perf_retrievedupdates => 0,
        updates_available => 0,
        available => '',
        progressing => '',
        failing => '',
        upgradeable => '',
        retrievedupdates => '',
        failing_reason => '',
        failing_message => '',
        upgradeable_reason => '',
        upgradeable_message => '',
        retrieved_reason => '',
        retrieved_message => '',

    };

    my $results = $options{custom}->openshift_list_clusterversions();

    $self->{output}->option_exit(short_msg => 'Unable to retrieve clusterversion information') unless ref $results eq 'ARRAY' && @{$results} && ref $results->[0]->{status} eq 'HASH';

    my $cv = $results->[0];
    my $status = $cv->{status};
    my $g = $self->{global};

    $g->{current_version} = value_of($status, "->{history}->[0]->{version}", '-');
    $g->{desired_version} = value_of($status, "->{desired}->{version}", '-');
    $g->{channel} = $cv->{spec}->{channel} // '-';

    my %human_status = ();

    if (ref $status->{conditions} eq 'ARRAY') {
        foreach my $cond (@{$status->{conditions}}) {
            my $type = lc $cond->{type};
            my $cond_status = bool_to_int ($cond->{status});

            if ($type eq 'available') {
                $g->{perf_available} = $cond_status;
                $human_status{10} = $cond_status ? "Available" : "Not Available";
            } elsif ($type eq 'progressing') {
                $g->{perf_progressing} = $cond_status;
                $human_status{20} = exprintf("Progressing". ($g->{desired_version} && $g->{desired_version} ne $g->{current_version} ? " (%{current_version} -> %{desired_version})" : ''), $g) if $cond_status;
            } elsif ($type eq 'failing') {
                $g->{perf_failing} = $cond_status;
                $g->{failing_reason} = $cond->{reason} // '';
                $g->{failing_message} = $cond->{message} // '';

                $human_status{30} = exprintf("Failing" . ($g->{failing_reason} ne '' ? ' (%{failing_reason})' : ''), $g)
                    if $cond_status;
            } elsif ($type eq 'upgradeable') {
                $g->{perf_upgradeable} = $cond_status;
                unless ($cond_status) {
                    $g->{upgradeable_reason} = $cond->{reason} // '';
                    $g->{upgradeable_message} = $cond->{message} // '';
                    $human_status{40} = exprintf("Not Upgradeable" . ($g->{upgradeable_reason} ne '' ? ' (%{upgradeable_reason})' : ''), $g);
                }
            } elsif ($type eq 'retrievedupdates') {
                $self->{global}->{perf_retrievedupdates} = $cond_status;

                unless ($cond_status) {
                    $self->{global}->{retrieved_reason} = $cond->{reason} // '';
                    $self->{global}->{retrieved_message} = $cond->{message} // '';
                    $human_status{50} = exprintf("Unable to retrieve updates" . ($g->{retrieved_reason} ne '' ? ' (%{retrieved_reason})' : ''), $g);
                }
            }
        }
    }

    $self->{global}->{human_status} = join', ', map { $human_status{$_} } sort keys %human_status;

    my $available_updates = $status->{availableUpdates} // [];
    $g->{updates_available} = @{$available_updates};


    $g->{$_} = int_to_bool($g->{"perf_$_"})
        foreach qw/available progressing failing upgradeable retrievedupdates/;

    if ($self->{output}->is_verbose()) {
        my @detail = ( 'Cluster Version Details:' );
        push @detail, "  Current: " . $g->{current_version};
        push @detail, "  Desired: " . $g->{desired_version}
           if $g->{desired_version} && $g->{desired_version} ne $g->{current_version};
        push @detail, "  Channel: " . $g->{channel};
        push @detail, "  Available: " . $g->{available};
        push @detail, "  Progressing: " . $g->{progressing};
        push @detail, "  Failing: " . $g->{failing};
        push @detail, "    Reason: " . $g->{failing_reason}
            if is_not_empty($g->{failing_reason});
        push @detail, "    Message: " . $g->{failing_message}
            if is_not_empty($g->{failing_message});
        push @detail, "  Upgradeable: " . $g->{upgradeable};
        push @detail, "    Reason: " . $g->{upgradeable_reason}
            if is_not_empty($g->{upgradeable_reason});
        push @detail, "    Message: " . $g->{upgradeable_message}
            if is_not_empty($g->{upgradeable_message});
        push @detail, "  Updates retrieval: " . $g->{retrievedupdates};
        push @detail, "    Reason: " . $g->{retrieved_reason}
            if is_not_empty($g->{retrieved_reason});
        push @detail, "    Message: " . $g->{retrieved_message}
            if is_not_empty($g->{retrieved_message});

        push @detail, "  Updates Available: " . $g->{updates_available};

        $self->{output}->output_add(long_msg => join "\n", @detail);
    }
}

1;

__END__

=head1 MODE

Monitor OpenShift cluster version status, availability, upgrade readiness, and available updates.

=over 8

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{available} =~ /false/ || %{failing} =~ /true/').
You can use the following variables: %{human_status}, %{current_version}, %{channel}, %{desired_version}, %{available}, %{progressing}, %{failing}, %{upgradeable}, %{retrievedupdates}, %{updates_available}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{human_status}, %{current_version}, %{channel}, %{desired_version}, %{available}, %{progressing}, %{failing}, %{upgradeable}, %{retrievedupdates}, %{updates_available}

=back

=cut
