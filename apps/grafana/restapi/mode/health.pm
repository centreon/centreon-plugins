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

package apps::grafana::restapi::mode::health;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = "Database state is: '" . $self->{result_values}->{state} . "'";
    return $msg;
}

sub custom_version_output{
    my ($self, %options) = @_;

    my $msg = "Grafana version is: '" . $self->{result_values}->{version} . "'";
    return $msg;

}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'health', type => 0, cb_prefix_output => 'prefix_version_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{health} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'state' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
	{ label => 'version', threshold => 0, set => {
                key_values => [ { name => 'version' } ],
		closure_custom_calc => \&catalog_status_calc,
		closure_custom_output => $self->can('custom_version_output'),
		closure_custom_perfdata => sub { return 0; },
		closure_custom_threshold_check => \&catalog_status_threshold,
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{state} ne "ok"' },
    });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->query(url_path => '/api/health');

    $self->{health} = {};
    my $state = $result->{database};

    $self->{health} = {
        state => $state,
	version => $result->{version}
     };

    if (scalar(keys %{$self->{health}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No state found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check health state.

=over 8

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} ne "ok"').
Can used special variables like: %{state}

=back

=cut
