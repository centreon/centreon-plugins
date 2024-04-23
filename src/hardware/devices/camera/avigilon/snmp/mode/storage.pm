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

package hardware::devices::camera::avigilon::snmp::mode::storage;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc qw(is_empty);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'storage', type => 0 }
    ];

    $self->{maps_counters}->{storage} = [
        { label            => 'status',
          type             => 2,
          unknown_default  => '%{storage_state} =~ /Unknown/i',
          warning_default  => '%{storage_state} =~ /insufficientMediaCapacity/i || %{storage_state} =~ /insufficientMediaSpeed/i',
          critical_default => '%{storage_state} =~ /mediaNotPresent/i || %{storage_state} =~ /error/i',
          set              => {
              key_values                     => [{ name => 'storage_state' }],
              output_template                => 'state of the SD card: %s',
              closure_custom_perfdata        => sub { return 0; },
              closure_custom_threshold_check => \&catalog_status_threshold_ng
          }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $storage_state_mapping = {
        1  => 'mediaNotPresent',
        2  => 'mediaDetected',
        3  => 'existingDataOnMediaDetected',
        4  => 'mediaFormatting',
        5  => 'scanningForRecordings',
        6  => 'readOnly',
        7  => 'readyToRecord',
        8  => 'recording',
        9  => 'errorFormatting',
        10 => 'errorWriting',
        11 => 'insufficientMediaCapacity',
        12 => 'insufficientMediaSpeed',
        13 => 'error'
    };

    my $oid_storage_state = '.1.3.6.1.4.1.46202.1.1.1.5.0'; #storageState
    my $snmp_result       = $options{snmp}->get_leef(
        oids         => [$oid_storage_state],
        nothing_quit => 1
    );

    if(centreon::plugins::misc::is_empty($storage_state_mapping->{$snmp_result->{$oid_storage_state}})==0){
        $self->{storage} = {
            storage_state => $storage_state_mapping->{$snmp_result->{$oid_storage_state}}
        };
    # If state is not in the mapping, return unkown
    }else{
        $self->{storage} = {
            storage_state => "Unknown"
        };
    }
}

1;

__END__

=head1 MODE

Check storage state of the SD card.

=over 8

=item B<--unknown-status>

Define the conditions to match to return a unknown status (default: "%{storage_state} =~ /Unknown/i").
The condition can be written using the following macros: %{storage_state}.

=item B<--warning-status>

Define the conditions to match to return a warning status (default: "%{storage_state} =~ /insufficientMediaCapacity/i || %{storage_state} =~ /insufficientMediaSpeed/i").
The condition can be written using the following macros: %{storage_state}.

=item B<--critical-status>

Define the conditions to match to return a critical status (default: "%{storage_state} =~ /mediaNotPresent/i || %{storage_state} =~ /error/i").
The condition can be written using the following macros: %{storage_state}.

=back

=cut
