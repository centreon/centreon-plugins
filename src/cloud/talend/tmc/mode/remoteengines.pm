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

package cloud::talend::tmc::mode::remoteengines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s [availability: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{availability}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of remote engines ';
}

sub prefix_engine_output {
    my ($self, %options) = @_;

    return sprintf(
        "remote engine '%s' ",
        $options{instance_value}->{name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'engines', type => 1, cb_prefix_output => 'prefix_engine_output', message_multiple => 'All remote engines are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'remote-engines-detected', display_ok => 0, nlabel => 'remote_engines.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'remote-engines-unpaired', display_ok => 0, nlabel => 'remote_engines.unpaired.count', set => {
                key_values => [ { name => 'unpaired' }, { name => 'detected' } ],
                output_template => 'unpaired: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'detected' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{engines} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{availability} !~ /retired/ and %{status} =~ /unpaired/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'availability' }, { name => 'name' }
                ],
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
        'filter-name:s'             => { name => 'filter_name' },
        'filter-environment-name:s' => { name => 'filter_environment_name' }
    });

    return $self;
}

my $map_availability = { AVAILABLE => 'available', NOT_AVAILABLE => 'notAvailable', RETIRED => 'retired' };
my $map_status = { PAIRED => 'paired', NOT_PAIRED => 'unpaired' };

sub manage_selection {
    my ($self, %options) = @_;

    my $engines = $options{custom}->get_remote_engines();

    $self->{global} = { detected => 0, unpaired => 0 };
    $self->{tasks} = {};
    foreach my $engine (@$engines) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $engine->{name} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_environment_name}) && $self->{option_results}->{filter_environment_name} ne '' &&
            $engine->{workspace}->{environment}->{name} !~ /$self->{option_results}->{filter_environment_name}/);

        $self->{engines}->{ $engine->{name} } = {
            name => $engine->{name},
            availability => $map_availability->{ $engine->{availability} },
            status => $map_status->{ $engine->{status} }
        };

        $self->{global}->{detected}++;
        $self->{global}->{unpaired}++ if ($engine->{status} eq 'NOT_PAIRED');
    }
}

1;

__END__

=head1 MODE

Check remote engines.

=over 8

=item B<--filter-name>

Remote engine name filter (can be a regexp).

=item B<--filter-environment-name>

Environment filter (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{availability}, %{name}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{availability}, %{name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{availability} !~ /retired/ and %{status} =~ /unpaired/i').
You can use the following variables: %{status}, %{availability}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'remote-engines-detected', 'remote-engines-unpaired'.

=back

=cut
