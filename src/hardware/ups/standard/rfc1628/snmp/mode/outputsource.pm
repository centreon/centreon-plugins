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

package hardware::ups::standard::rfc1628::snmp::mode::outputsource;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("Output source status is '%s'", $self->{result_values}->{status});
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'source-status',
            type => 2,
            unknown_default => '%{status} =~ /other/',
            warning_default => '%{status} =~ /bypass|battery|booster|reducer/',
            critical_default => '%{status} =~ /none/',
            set => {
                key_values => [ { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $map_status = {
        1 => 'other', 2 => 'none',
        3 => 'normal', 4 => 'bypass', 5 => 'battery',
        6 => 'booster', 7 => 'reducer'
    };

    my $oid_upsOutputSource = '.1.3.6.1.2.1.33.1.4.1.0';
    my $snmp_result = $options{snmp}->get_leef(oids => [$oid_upsOutputSource], nothing_quit => 1);

    $self->{global} = { status => $map_status->{ $snmp_result->{$oid_upsOutputSource} } };
}

1;

__END__

=head1 MODE

Check output source status.

=over 8

=item B<--unknown-source-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{status} =~ /other/')
You can use the following variables: %{status}

=item B<--warning-source-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /bypass|battery|booster|reducer/')
You can use the following variables: %{status}

=item B<--critical-source-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /none/')
You can use the following variables: %{status}

=back

=cut
