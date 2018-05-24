#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package network::riverbed::steelhead::snmp::mode::servicestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my $instance_mode;

sub custom_status_threshold {
    my ($self, %options) = @_;
    my $status = 'ok';
    my $message;
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        if (defined($instance_mode->{option_results}->{critical_status}) && $instance_mode->{option_results}->{critical_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) && $instance_mode->{option_results}->{warning_status} ne '' &&
            eval "$instance_mode->{option_results}->{warning_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = "Optimization service state: '" . $self->{result_values}->{state} . "' ";
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'opt_service', type => 0 },
    ];
    $self->{maps_counters}->{opt_service} = [
        { label => 'status', threshold => 0,  set => {
                key_values => [ { name => 'state' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning-status:s"    => { name => 'warning_status', default => '' },
                                  "critical-status:s"   => { name => 'critical_status', default => '%{state} !~ /running/' },
                                });

    return $self;
}

sub change_macros {
    my ($self, %options) = @_;

    foreach ('warning_status', 'critical_status') {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $instance_mode = $self;
    $self->change_macros();
}

my %map_status = (
    0 => 'none',
    1 => 'unmanaged',
    2 => 'running',
    3 => 'sentCom1',
    4 => 'sentTerm1',
    5 => 'sentTerm2',
    6 => 'sentTerm3',
    7 => 'pending',
    8 => 'stopped',
);

sub manage_selection {
    my ($self, %options) = @_;

    $self->{opt_service} = {};

    # STEELHEAD-MIB
    my $oid_optServiceStatus = '.1.3.6.1.4.1.17163.1.1.2.8.0';
    # STEELHEAD-EX-MIB
    my $oid_ex_optServiceStatus = '.1.3.6.1.4.1.17163.1.51.2.8.0';

    my $result = $options{snmp}->get_leef(oids => [ $oid_optServiceStatus, $oid_ex_optServiceStatus ], nothing_quit => 1);
    my $status = defined($result->{$oid_optServiceStatus}) ? $result->{$oid_optServiceStatus} : $result->{$oid_ex_optServiceStatus} ;

    $self->{opt_service} = { state => $map_status{$status} };
}

1;

__END__

=head1 MODE

Check the current status of the optimization service (STEELHEAD-MIB and STEELHEAD-EX-MIB).

=over 8

=item B<--warning-status>

Set warning threshold for status (Default: '').
Special var is %{state}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} !~ /running/').
Special var is %{state}

=back

=cut
