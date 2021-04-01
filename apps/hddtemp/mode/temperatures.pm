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

package apps::hddtemp::mode::temperatures;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
         $self->{result_values}->{status},
    );
}

sub custom_temperature_output { 
    my ($self, %options) = @_;

    return sprintf('temperature: %s %s',
        $self->{result_values}->{temperature},
        $self->{result_values}->{temperature_unit}
    );
}

sub custom_temperature_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'drive.temperature.' . ($self->{result_values}->{temperature_unit} eq 'C' ? 'celsius' : 'fahrenheit'),
        instances => $self->{result_values}->{display},
        unit => $self->{result_values}->{temperature_unit},
        value => $self->{result_values}->{temperature},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
    );
}

sub prefix_drive_output {
    my ($self, %options) = @_;

    return "Drive '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'drives', type => 1, cb_prefix_output => 'prefix_drive_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{drives} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'temperature', set => {
                key_values => [ { name => 'temperature' }, { name => 'temperature_unit' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_temperature_output'),
                closure_custom_perfdata => $self->can('custom_temperature_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} !~ /ok/i' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->get_drives_information();

    $self->{drives} = {};
    foreach (keys %$results) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_ !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping drive '" . $_ . "': no matching filter.", debug => 1);
            next;
        }

        $self->{drives}->{$_} = {
            display => $_,
            %{$results->{$_}}
        };
    }
}

1;

__END__

=head1 MODE

Check drive temperatures.

=over 8

=item B<--filter-name>

Filter drive name (Can use regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /ok/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'temperature'.

=back

=cut
