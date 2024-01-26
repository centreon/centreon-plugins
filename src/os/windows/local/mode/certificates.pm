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

package os::windows::local::mode::certificates;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::powershell::windows::certificates;
use centreon::plugins::misc;
use JSON::XS;
use POSIX;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_expires_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        unit => $self->{instance_mode}->{option_results}->{unit},
        instances => $self->{result_values}->{subject},
        value => floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_expires_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub custom_expires_output {
    my ($self, %options) = @_;

    my $msg = 'expires in ' . $self->{result_values}->{expires_human};
    if ($self->{result_values}->{expires_seconds} == 0) {
        $msg = 'expired';
    }

    return $msg;
}

sub prefix_certificate_output {
    my ($self, %options) = @_;

    return sprintf(
        "Certificate '%s' [path: %s] ",
        $options{instance_value}->{subject},
        $options{instance_value}->{path}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'certificates', type => 1, cb_prefix_output => 'prefix_certificate_output', message_multiple => 'All certificates are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'certificates-detected', nlabel => 'certificates.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'number of certificates: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{certificates} = [
        { label => 'certificate-expires', nlabel => 'certificate.expires', set => {
                key_values      => [ { name => 'expires_seconds' }, { name => 'expires_human' }, { name => 'subject' } ],
                closure_custom_output => $self->can('custom_expires_output'),
                closure_custom_perfdata => $self->can('custom_expires_perfdata'),
                closure_custom_threshold_check => $self->can('custom_expires_threshold')
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
        'command:s'         => { name => 'command' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options' },
        'no-ps'             => { name => 'no_ps' },
        'ps-exec-only'      => { name => 'ps_exec_only' },
        'ps-display'        => { name => 'ps_display' },
        'filter-thumbprint:s' => { name => 'filter_thumbprint' },
        'filter-subject:s'    => { name => 'filter_subject' },
        'filter-path:s'       => { name => 'filter_path' },
        'unit:s'              => { name => 'unit', default => 's' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    centreon::plugins::misc::check_security_command(
        output => $self->{output},
        command => $self->{option_results}->{command},
        command_options => $self->{option_results}->{command_options},
        command_path => $self->{option_results}->{command_path}
    );

    $self->{option_results}->{command} = 'powershell.exe'
        if (!defined($self->{option_results}->{command}) || $self->{option_results}->{command} eq '');
    $self->{option_results}->{command_options} = '-InputFormat none -NoLogo -EncodedCommand'
        if (!defined($self->{option_results}->{command_options}) || $self->{option_results}->{command_options} eq '');

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::windows::certificates::get_powershell();
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
    #  {"subject":"CN=Microsoft Development Root Certificate Authority 2014, O=Microsoft Corporation, L=Redmond, S=Washington, C=US","PSParentPath":"Microsoft.PowerShell.Security\\Certificate::LocalMachine\\FlightRoot","thumbprint":"F8DB7E1C16F1FFD4AAAD4AAD8DFF0F2445184AEB","archived":false,"notAfter":"2190214308"},
    #  {"subject":"CN=Microsoft ECC Development Root Certificate Authority 2018, O=Microsoft Corporation, L=Redmond, S=Washington, C=US","PSParentPath":"Microsoft.PowerShell.Security\\Certificate::LocalMachine\\FlightRoot","thumbprint":"6CA22E5501CC80885FF281DD8B3338E89398EE18","archived":false,"notAfter":"2308682336"}
    #  ...
    #]

    $self->{global} = { total => 0 };
    $self->{certificates} = {};
    my $current_time = time();
    foreach my $cert (@$decoded) {
        next if ($cert->{archived} =~ /true|1/i);

        next if (defined($self->{option_results}->{filter_thumbprint}) && $self->{option_results}->{filter_thumbprint} ne '' &&
            $cert->{thumbprint} !~ /$self->{option_results}->{filter_thumbprint}/);
        next if (defined($self->{option_results}->{filter_subject}) && $self->{option_results}->{filter_subject} ne '' &&
            $cert->{subject} !~ /$self->{option_results}->{filter_subject}/);
        next if (defined($self->{option_results}->{filter_path}) && $self->{option_results}->{filter_path} ne '' &&
            $cert->{PSParentPath} !~ /$self->{option_results}->{filter_path}/);

        $self->{certificates}->{ $cert->{thumbprint} } = {
            subject => $cert->{subject},
            path => $cert->{PSParentPath}
        };
        if (defined($cert->{notAfter})) {
            my $expires_in = $cert->{notAfter} - $current_time;
            $expires_in = 0 if ($expires_in < 0);
            $self->{certificates}->{ $cert->{thumbprint} }->{expires_seconds} = $expires_in;
            $self->{certificates}->{ $cert->{thumbprint} }->{expires_human} = centreon::plugins::misc::change_seconds(
                value => $expires_in
            );
        }

        $self->{global}->{detected}++;
    }
}

1;

__END__

=head1 MODE

Check local certificates.

=over 8

=item B<--timeout>

Set timeout time for command execution (default: 50 sec)

=item B<--no-ps>

Don't encode powershell. To be used with --command and 'type' command.

=item B<--command>

Command to get information (default: 'powershell.exe').
Can be changed if you have output in a file. To be used with --no-ps option!!!

=item B<--command-path>

Command path (default: none).

=item B<--command-options>

Command options (default: '-InputFormat none -NoLogo -EncodedCommand').

=item B<--ps-display>

Display powershell script.

=item B<--ps-exec-only>

Print powershell output.

=item B<--filter-thumbprint>

Filter certificate by thumbprint (can be a regexp).

=item B<--filter-subject>

Filter certificate by subject (can be a regexp).

=item B<--filter-path>

Filter certificate by path (can be a regexp).

=item B<--unit>

Select the time unit for the expiration thresholds. May be 's' for seconds,'m' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'certificates-detected', 'certificate-expires'.

=back

=cut
