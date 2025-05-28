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

package network::backbox::restapi::mode::devicebackup;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Device [id: %s] [name: %s] [status: %s] [status reason: %s]",
                      $self->{result_values}->{device_id},
                      $self->{result_values}->{device_name},
                      $self->{result_values}->{status},
                      $self->{result_values}->{status_reason});
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'backup', type => 0 },
    ];

    $self->{maps_counters}->{backup} = [
        { label            => 'status',
          type             => 2,
          warning_default  => '%{status} =~ /SUSPECT/i',
          critical_default => '%{status} =~ /FAILURE/i',
          set              => {
              key_values                     => [ { name => 'device_id' },
                                                  { name => 'device_name' },
                                                  { name => 'status' },
                                                  { name => 'status_reason' }
              ],
              closure_custom_output          => $self->can('custom_status_output'),
              closure_custom_perfdata        => sub { return 0; },
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
        'device-id:s'   => { name => 'device_id' },
        'device-name:s' => { name => 'device_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (centreon::plugins::misc::is_empty($self->{option_results}->{device_id}) && centreon::plugins::misc::is_empty($self->{option_results}->{device_name})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --device-id or --device-name option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $device_id = $self->{option_results}->{device_id};
    my $device_name = $self->{option_results}->{device_name} || '';
    if (centreon::plugins::misc::is_empty($device_id)) {
        $device_id = $options{custom}->get_device_id_from_name(device_name => $device_name);
    }

    my $backup = $options{custom}->get_device_backup_status(device_id => $device_id);
    if (centreon::plugins::misc::is_empty($backup)) {
        $self->{output}->add_option_msg(short_msg => "No backup found for device id '" . $device_id . "'.");
        $self->{output}->option_exit();
    }

    $self->{backup} = { device_id     => $device_id,
                        device_name   => $device_name,
                        status        => $backup->{historyStatus},
                        status_reason => $backup->{statusReason}
    };
}

1;

__END__

=head1 MODE

Check a device backup on BackBox.

=over 8

=item B<--device-id>

ID of the device (if you prefer to use the ID instead of the name).
ID or name is mandatory.

=item B<--device-name>

Name of the device (if you prefer to use the name instead of the ID).
ID or name is mandatory. If you specify both, the ID will be used.

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /SUSPECT/i').
You can use the following variables: %{status}, %{status_reason}, %{device_name}, %{device_id}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /FAILURE/i').
You can use the following variables: %{status}, %{status_reason}, %{device_name}, %{device_id}.

=back

=cut
