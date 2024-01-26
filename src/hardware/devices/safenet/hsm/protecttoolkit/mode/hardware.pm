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

package hardware::devices::safenet::hsm::protecttoolkit::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|memory)$';
    
    $self->{cb_hook2} = 'cmd_execute';
    
    $self->{thresholds} = {
        hwstatus => [
            ['BATTERY OK', 'OK'],
            ['.*', 'CRITICAL']
        ]
    };
    
    $self->{components_path} = 'hardware::devices::safenet::hsm::protecttoolkit::mode::components';
    $self->{components_module} = ['hwstatus', 'temperature', 'memory'];
}

sub cmd_execute {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'ctconf',
        command_options => '-v'
    );

    $self->{stdout} =~ s/\r//msg;
    my ($model, $firmware, $fm_status, $transport_mode, $security_mode) = ('unknown', 'unknown', 'unknown', 'unknown', 'unknown');
    $model = $1 if ($self->{stdout} =~ /^Model\s+:\s+(.*?)\s*\n/msi);
    $firmware = $1 if ($self->{stdout} =~ /^Firmware Version\s+:\s+(.*?)\s*\n/msi);
    $fm_status = $1 if ($self->{stdout} =~ /^FM Status\s+:\s+(.*?)\s*\n/msi);
    $transport_mode = $1 if ($self->{stdout} =~ /^Transport Mode\s+:\s+(.*?)\s*\n/msi);
    $security_mode = $1 if ($self->{stdout} =~ /^Security Mode\s+:\s+(.*?)\s*\n/msi);
    $self->{output}->output_add(
        long_msg => sprintf(
            "model: %s, firmware version: %s",
            $model,
            $firmware
        )
    );
    $self->{output}->output_add(
        long_msg => sprintf(
            "fm status: '%s', transport mode: '%s', security mode: '%s'", 
            $fm_status, $transport_mode, $security_mode
        )
    );
}

sub display {
    my ($self, %options) = @_;

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => sprintf("Hardware status is OK")
    );
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check HSM hardware status.

Command used: 'ctconf -v'

=over 8

=item B<--component>

Which component to check.
Can be: 'hwstatus', 'temperature', 'memory'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=temperature).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,status,regexp).
Example: --threshold-overload='hwstats,CRITICAL,^(?!(OK)$)'

=item B<--warning>

Set warning threshold for 'temperature', 'memory' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,50'

=item B<--critical>

Set critical threshold for 'temperature', 'memory' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,60'

=back

=cut
