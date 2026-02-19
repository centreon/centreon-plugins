#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package os::windows::wsman::mode::certificates;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc qw/json_decode/;
use centreon::common::powershell::windows::certificates;
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
        'ps-exec-only'        => { name => 'ps_exec_only' },
        'ps-display'          => { name => 'ps_display' },
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

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $ps = centreon::common::powershell::windows::certificates::get_powershell();
    if (defined($self->{option_results}->{ps_display})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $ps
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    my $result = $options{wsman}->execute_powershell_script(
        label => 'certificates',
        content => $ps
    );

    if (defined($self->{option_results}->{ps_exec_only})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $result->{certificates}->{stdout}
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    my $stderr = $result->{certificates}->{stderr} ?
        $self->{output}->decode($result->{certificates}->{stderr}) : '';

    my $decoded = json_decode($self->{output}->decode($result->{certificates}->{stdout}), no_exit => 1);

    $self->{output}->option_exit(short_msg => 'Cannot decode powershell output'.($stderr ? ": $stderr" : ''))
        unless ($decoded);

    $self->{output}->output_add(long_msg => "PowerShell stderr: $stderr", debug => 1)
        if $self->{output}->is_debug() && $stderr;

    $self->{global} = { detected => 0 };
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

Check Windows certificates.

=over 8

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
