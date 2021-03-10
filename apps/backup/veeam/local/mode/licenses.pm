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

package apps::backup::veeam::local::mode::licenses;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::powershell::veeam::licenses;
use apps::backup::veeam::local::mode::resources::types qw($license_type $license_status);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc;
use JSON::XS;

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status};
}

sub custom_license_instances_output {
    my ($self, %options) = @_;

    return sprintf(
        'instances total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $self->{result_values}->{instances_total},
        $self->{result_values}->{instances_used},
        $self->{result_values}->{instances_prct_used},
        $self->{result_values}->{instances_free},
        $self->{result_values}->{instances_prct_free}
    );
}

sub prefix_license_output {
    my ($self, %options) = @_;

    return sprintf(
        "License '%s' [type: %s] ",
        $options{instance_value}->{to},
        $options{instance_value}->{type}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'licenses', type => 1, cb_prefix_output => 'prefix_license_output', message_multiple => 'All licenses are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'licenses.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Number of licenses: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{licenses} = [
        { label => 'status', type => 2, critical_default => '%{status} =~ /expired|invalid/i', set => {
                key_values => [ { name => 'to' }, { name => 'status' }, { name => 'type' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'expires-seconds', nlabel => 'license.expires.seconds', set => {
                key_values      => [ { name => 'expires_seconds' }, { name => 'expires_human' } ],
                output_template => 'expires in %s',
                output_use => 'expires_human',
                perfdatas => [
                    { template => '%d', min => 0, unit => 's', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'license-instances-usage', nlabel => 'license.instances.usage.count', set => {
                key_values => [ { name => 'instances_used' }, { name => 'instances_free' }, { name => 'instances_prct_used' }, { name => 'instances_prct_free' }, { name => 'instances_total' } ],
                closure_custom_output => $self->can('custom_license_instances_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'instances_total', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'license-instances-free', display_ok => 0, nlabel => 'license.instances.free.count', set => {
                key_values => [ { name => 'instances_free' }, { name => 'instances_used' }, { name => 'instances_prct_used' }, { name => 'instances_prct_free' }, { name => 'instances_total' } ],
                closure_custom_output => $self->can('custom_license_instances_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'instances_total', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'license-instances-usage-prct', display_ok => 0, nlabel => 'license.instances.usage.percentage', set => {
                key_values => [ { name => 'instances_prct_used' }, { name => 'instances_used' }, { name => 'instances_free' }, { name => 'instances_prct_free' }, { name => 'instances_total' } ],
                closure_custom_output => $self->can('custom_license_instances_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'timeout:s'         => { name => 'timeout', default => 50 },
        'command:s'         => { name => 'command', default => 'powershell.exe' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
        'no-ps'             => { name => 'no_ps' },
        'ps-exec-only'      => { name => 'ps_exec_only' },
        'ps-display'        => { name => 'ps_display' },
        'filter-to:s'       => { name => 'filter_to' },
        'filter-type:s'     => { name => 'filter_type' },
        'filter-status:s'   => { name => 'filter_status' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::veeam::licenses::get_powershell();
        if (defined($self->{option_results}->{ps_display})) {
            $self->{output}->output_add(
                severity => 'OK',
                short_msg => $ps
            );
            $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
            $self->{output}->exit();
        }

        $self->{option_results}->{command_options} .= " " . centreon::plugins::misc::powershell_encoded($ps);
    }

    my ($stdout) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options}
    );
    if (defined($self->{option_results}->{ps_exec_only})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $stdout
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($stdout);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    #[
    #  {"licensed_instances":7150,"expiration_time":"1632960000","type":0,"licensed_to":"Centreon Services","status":0,"used_instance":165}
    #]

    $self->{global} = { total => 0 };
    $self->{licenses} = {};
    my $current_time = time();
    foreach my $license (@$decoded) {
        if (defined($self->{option_results}->{filter_to}) && $self->{option_results}->{filter_to} ne '' &&
            $license->{licensed_to} !~ /$self->{option_results}->{filter_to}/) {
            $self->{output}->output_add(long_msg => "skipping license '" . $license->{licensed_to} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $license_type->{ $license->{type} } !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping license '" . $license->{licensed_to} . "': no matching filter type.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status} ne '' &&
            $license_status->{ $license->{status} } !~ /$self->{option_results}->{filter_status}/) {
            $self->{output}->output_add(long_msg => "skipping license '" . $license->{licensed_to} . "': no matching filter type.", debug => 1);
            next;
        }

        $self->{licenses}->{ $license->{licensed_to} } = {
            to => $license->{licensed_to},
            type => $license_type->{ $license->{type} },
            status => $license_status->{ $license->{status} }
        };
        if (defined($license_status->{expiration_time})) {
            $self->{licenses}->{ $license->{licensed_to} }->{expires_seconds} = $license_status->{expiration_time} - $current_time;
            $self->{licenses}->{ $license->{licensed_to} }->{expires_human} = centreon::plugins::misc::change_seconds(
                value => $self->{licenses}->{ $license->{licensed_to} }->{expires_seconds}
            );
        }
        if (defined($license->{licensed_instances}) && $license->{licensed_instances} > 0) {
            $self->{licenses}->{ $license->{licensed_to} }->{instances_total} = $license->{licensed_instances};
            $self->{licenses}->{ $license->{licensed_to} }->{instances_used} = $license->{used_instance};
            $self->{licenses}->{ $license->{licensed_to} }->{instances_free} = $license->{licensed_instances} - $license->{used_instance};
            $self->{licenses}->{ $license->{licensed_to} }->{instances_prct_used} = $license->{used_instance} * 100 / $license->{licensed_instances};
            $self->{licenses}->{ $license->{licensed_to} }->{instances_prct_free} = 100 - $self->{licenses}->{ $license->{licensed_to} }->{instances_prct_used};
        }

        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check licenses.

=over 8

=item B<--timeout>

Set timeout time for command execution (Default: 50 sec)

=item B<--no-ps>

Don't encode powershell. To be used with --command and 'type' command.

=item B<--command>

Command to get information (Default: 'powershell.exe').
Can be changed if you have output in a file. To be used with --no-ps option!!!

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-InputFormat none -NoLogo -EncodedCommand').

=item B<--ps-display>

Display powershell script.

=item B<--ps-exec-only>

Print powershell output.

=item B<--filter-to>

Filter licenses by person/organization (can be a regexp).

=item B<--filter-type>

Filter licenses by type (can be a regexp).

=item B<--filter-status>

Filter licenses by status (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{to}, %{status}, %{type}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /expired|invalid/i').
Can used special variables like: %{to}, %{status}, %{type}.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total', 'expires-seconds', 'license-instances-usage', 'license-instances-free', 'license-instances-usage-prct'.

=back

=cut
