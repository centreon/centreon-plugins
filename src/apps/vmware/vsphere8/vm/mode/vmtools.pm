#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::vmware::vsphere8::vm::mode::vmtools;

use base qw(apps::vmware::vsphere8::vm::mode);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my %version_status_explanation = (
    NOT_INSTALLED       => 'VMware Tools has never been installed.',
    CURRENT             => 'VMware Tools is installed, and the version is current.',
    UNMANAGED           => 'VMware Tools is installed, but it is not managed by VMware. This includes open-vm-tools or OSPs which should be managed by the guest operating system.',
    TOO_OLD_UNSUPPORTED => 'VMware Tools is installed, but the version is too old.',
    SUPPORTED_OLD       => 'VMware Tools is installed, supported, but a newer version is available.',
    SUPPORTED_NEW       => 'VMware Tools is installed, supported, and newer than the version available on the host.',
    TOO_NEW             => 'VMware Tools is installed, and the version is known to be too new to work correctly with this virtual machine.',
    BLACKLISTED         => 'VMware Tools is installed, but the installed version is known to have a grave bug and should be immediately upgraded.'
);

sub prefix_vm_output {
    my ($self, %options) = @_;

    return $options{instance_value}->{id} . ' ';
}

sub custom_install_attempts_output {
    my ($self, %options) = @_;

    my $desc = 'had ' . $self->{result_values}->{install_attempt_count} . ' install attempts';
    $desc .= ' (error messages available in long output with --verbose option)' if ($self->{result_values}->{has_errors});
    return $desc;
}

sub custom_upgrade_policy_output {
    my ($self, %options) = @_;

    my $msg = 'updates are ' . $self->{result_values}->{upgrade_policy} . ' (auto-updates ';
    $msg .= 'not ' if ($self->{result_values}->{auto_update_supported} eq 'false');
    return $msg . 'allowed)';
}

sub custom_version_status_output {
    my ($self, %options) = @_;

    return 'version is ' . $self->{result_values}->{version_status} . ' (v' . $self->{result_values}->{version} . ')';
}

sub custom_run_state_output {
    my ($self, %options) = @_;

    return 'tools are ' . $self->{result_values}->{run_state};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'vm',
            type             => 0,
            display_ok => 1,
            cb_prefix_output => 'prefix_vm_output',
            message_separator        => ' - ',
            message_multiple => 'All VMs are ok'
        }
    ];

    $self->{maps_counters}->{vm} = [
        {
            label => 'install-attempts',
            nlabel => 'tools.install.attempts.count',
            type  => 1,
            display_ok => 1,
            set   => {
                key_values            => [ { name => 'install_attempt_count' }, { name => 'has_errors' } ],
                closure_custom_output => $self->can('custom_install_attempts_output'),
                perfdatas => [
                    { label => 'install-attempts', template => '%d', min => 0 }
                ]
            }
        },
        {
            # Cf https://developer.broadcom.com/xapis/vsphere-automation-api/9.0/data-structures/Vcenter%20Vm%20Tools%20VersionStatus/index.html?scrollString=VersionStatus
            # The Vcenter Vm Tools VersionStatus enumerated type defines the version status types of VMware Tools installed in the guest operating system.
            label => 'version-status',
            type  => 2,
            display_ok => 1,
            warning_default => '%{version_status} =~ /^(SUPPORTED_OLD|TOO_NEW)$/i',
            critical_default => '%{version_status} =~ /^(NOT_INSTALLED|TOO_OLD_UNSUPPORTED|BLACKLISTED)$/i',
            set   => {
                key_values            => [ { name => 'version_status' }, { name => 'version' } ],
                closure_custom_output => $self->can('custom_version_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            # Cf https://developer.broadcom.com/xapis/vsphere-automation-api/9.0/data-structures/Vcenter%20Vm%20Tools%20UpgradePolicy/index.html?scrollString=Vcenter%20Vm%20Tools%20UpgradePolicy
            # Possible values:
            # MANUAL: No auto-upgrades for Tools will be performed for this virtual machine. Users must manually invoke the POST /vcenter/vm/{vm}/tools?action=upgrade operation to update Tools.
            # UPGRADE_AT_POWER_CYCLE: When the virtual machine is power-cycled, the system checks for a newer version of Tools when the virtual machine is powered on. If it is available, a Tools upgrade is automatically performed on the virtual machine and it is rebooted if necessary.
            label => 'upgrade-policy',
            type => 2,
            display_ok => 1,
            set              => {
                key_values                     => [ { name => 'auto_update_supported' }, { name => 'upgrade_policy' } ],
                closure_custom_output          => $self->can('custom_upgrade_policy_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'run-state',
            type => 2,
            display_ok => 1,
            warning_default => '%{run_state} =~ /^NOT_RUNNING$/i',
            set              => {
                key_values                     => [ { name => 'run_state' } ],
                closure_custom_output          => $self->can('custom_run_state_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub parse_tools_version {
    my ($version_int) = @_;

    # According to (this page)[https://developer.broadcom.com/xapis/vsphere-automation-api/latest/api/vcenter/vm/vm/tools/get/]
    # This property will be missing or null if VMWare Tools is not installed.
    # This is an integer constructed as follows:
    # (((MJR) << 10) + ((MNR) << 5) + (REV))
    # Where MJR is tha major verson, MNR is the minor version and REV is the revision.
    # Tools version = T
    # Tools Version Major = MJR = (T / 1024)
    # Tools Version Minor = MNR = ((T % 1024) / 32)
    # Tools Version Revision = BASE = ((T % 1024) % 32)
    # Tools actual version = MJR.MNR.REV

    my @version_str = (
        int($version_int / 1024),       # major
        int($version_int % 1024 / 32),  # minor
        ($version_int % 1024 % 32)      # revision
    );

    return join('.', @version_str);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $tools = $self->get_vm_tools(%options);
    # Example of API response:
    # {
    #   "auto_update_supported": false,
    #   "upgrade_policy": "MANUAL",
    #   "install_attempt_count": 1,
    #   "version_status": "UNMANAGED",
    #   "version_number": 12352,
    #   "run_state": "RUNNING",
    #   "version": "12352",
    #   "error": {},
    #   "install_type": "OPEN_VM_TOOLS"
    # }

    $self->{vm} = {
        id                    => $self->{vm_id} // '',
        name                  => $self->{vm_name} // '',
        auto_update_supported => $tools->{auto_update_supported},
        install_attempt_count => $tools->{install_attempt_count} // 0,
        error                 => $tools->{error} // {},
        upgrade_policy        => $tools->{upgrade_policy},
        version_status        => $tools->{version_status} // '',
        install_type          => $tools->{install_type} // '',
        run_state             => $tools->{run_state},
        has_errors            => 0
    };

    $self->{vm}->{version} = parse_tools_version($tools->{version_number})
        if ( !centreon::plugins::misc::is_empty($tools->{version_number}) && $tools->{version_number} != 0);

    $self->{output}->output_add(long_msg => 'Version status: ' . $tools->{version_status} . ' - Explanation: ' . $version_status_explanation{$tools->{version_status}})
        if ( !centreon::plugins::misc::is_empty($tools->{version_status}));

    # Example of "error" object:
    # {
    #   "error_type": "ERROR",
    #   "messages": [
    #     {
    #       "args": [],
    #       "default_message": "An error has occurred while invoking the operation.",
    #       "id": "com.vmware.api.vcenter.error"
    #     },
    #     {
    #       "args": [],
    #       "default_message": "Error upgrading VMware Tools.",
    #       "id": "vmsg.VmToolsUpgradeFault.summary"
    #     }
    #   ]
    # }
    if (defined($self->{vm}->{error}->{messages})) {
        # flag the presence of error messages
        $self->{vm}->{has_errors} = 1;
        # display error messages in long output
        foreach my $err (@{ $self->{vm}->{error}->{messages} }) {
            my $args = '';
            $args = ' Args: '. join(', ', @{ $err->{args} }) if (@{ $err->{args} } > 0);
            $self->{output}->output_add(long_msg => 'Error: [' . $err->{id} . '] ' . $err->{default_message} . $args);
        }
    }
    
    return 1;
}

1;

__END__

=head1 MODE

Monitor the status of VMware Tools on VMs through vSphere 8 REST API.

=over 8

=item B<--warning-install-attempts>

Threshold based on the number of attempts that have been made to install or upgrade the version of Tools installed on
this virtual machine. In case of failed attempts, adding the C<--verbose> option will display the error messages in the
long output.

=item B<--critical-install-attempts>

Threshold based on the number of attempts that have been made to install or upgrade the version of Tools installed on
this virtual machine. In case of failed attempts, adding the C<--verbose> option will display the error messages in the
long output.

=item B<--warning-run-state>

Define the conditions to match for the status to be WARNING based on the Current run state of VMware Tools in the guest
operating system. You can use the following variables: C<%{run_state}> (can be "NOT_RUNNING", "RUNNING"
or "EXECUTING_SCRIPTS").

Default: C<%{run_state} =~ /^NOT_RUNNING$/i>

=item B<--critical-run-state>

Define the conditions to match for the status to be CRITICAL based on the Current run state of VMware Tools in the guest
operating system. You can use the following variables: C<%{run_state}> (can be "NOT_RUNNING", "RUNNING"
or "EXECUTING_SCRIPTS").

=item B<--warning-upgrade-policy>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{auto_update_supported}> (can be "true" or "false"),
C<%{upgrade_policy}> (can be "MANUAL" or "UPGRADE_AT_POWER_CYCLE").

=item B<--critical-upgrade-policy>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: C<%{auto_update_supported}> (can be "true" or "false"),
C<%{upgrade_policy}> (can be "MANUAL" or "UPGRADE_AT_POWER_CYCLE").

=item B<--warning-version-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: C<%{version_status}> (can be "NOT_INSTALLED", "CURRENT", "UNMANAGED",
"TOO_OLD_UNSUPPORTED", "SUPPORTED_OLD", "SUPPORTED_NEW", "TOO_NEW" or "BLACKLISTED") and
C<%{version}> (example: "v12.3.0").

Default: C<%{version_status} =~ /^(SUPPORTED_OLD|TOO_NEW)$/i>

=item B<--critical-version-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: C<%{version_status}> (can be "NOT_INSTALLED", "CURRENT", "UNMANAGED",
"TOO_OLD_UNSUPPORTED", "SUPPORTED_OLD", "SUPPORTED_NEW", "TOO_NEW" or "BLACKLISTED") and
C<%{version}> (example: "v12.3.0").

Default: C<%{version_status} =~ /^(NOT_INSTALLED|TOO_OLD_UNSUPPORTED|BLACKLISTED)$/i>

=back

=cut
