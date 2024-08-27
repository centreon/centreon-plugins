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

package storage::hp::p2000::xmlapi::mode::ntp;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use DateTime;
use POSIX;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_contact_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        unit => $self->{instance_mode}->{option_results}->{unit},
        value => floor($self->{result_values}->{contact_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_contact_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{contact_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf('status is %s', $self->{result_values}->{status});
}

sub license_long_output {
    my ($self, %options) = @_;

    return 'checking ntp';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'ntp', type => 3, cb_long_output => 'ntp_long_output', indent_long_output => '    ',
            group => [
                { name => 'status', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'contact', type => 0, display_short => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{status} = [
        { 
            label => 'status',
            type => 2,
            critical_default => '%{status} =~ /deactivated/i',
            set => {
                key_values => [ { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{contact} = [
        { label => 'contact-last-time', nlabel => 'ntp.contact.last.time', set => {
                key_values      => [ { name => 'contact_seconds' }, { name => 'contact_human' } ],
                output_template => 'last server contact: %s',
                output_use => 'contact_human',
                closure_custom_perfdata => $self->can('custom_contact_perfdata'),
                closure_custom_threshold_check => $self->can('custom_contact_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'unit:s'     => { name => 'unit', default => 's' },
        'timezone:s' => { name => 'timezone' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }
    $self->{option_results}->{timezone} = 'UTC' if (!defined($self->{option_results}->{timezone}) || $self->{option_results}->{timezone} eq '');
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($result) = $options{custom}->get_infos(
        cmd => 'show ntp-status', 
        base_type => 'ntp-status',
        properties_name => '^ntp-status|ntp-contact-time$'
    );

    if (!defined($result->[0])) {
        $self->{output}->add_option_msg(short_msg => 'cannot get informations');
        $self->{output}->option_exit();
    }

    $self->{output}->output_add(short_msg => 'ntp is ok');

    $self->{ntp} = {
        global => {
            status => { status => $result->[0]->{'ntp-status'} },
            contact => {}
        }
    };

    if ($result->[0]->{'ntp-contact-time'} =~ /^(\d+)-(\d+)-(\d+)\s+(\d+):(\d+):(\d+)$/) {
        my $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
        my $dt = DateTime->new(
            year => $1,
            month => $2,
            day => $3,
            hour => $4,
            minute => $5,
            second => $6,
            %$tz
        );
        $self->{ntp}->{global}->{contact}->{contact_seconds} = time() - $dt->epoch();
        $self->{ntp}->{global}->{contact}->{contact_human} = centreon::plugins::misc::change_seconds(
            value => $self->{ntp}->{global}->{contact}->{contact_seconds}
        );
    }
}

1;

__END__

=head1 MODE

Check ntp status.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
Can use special variables like: %{status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /deactivated/i').
Can use special variables like: %{status}

=item B<--timezone>

Set timezone for ntp contact time (default is 'UTC').

=item B<--unit>

Select the time unit for the performance data and thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'contact-last-time'.

=back

=cut
