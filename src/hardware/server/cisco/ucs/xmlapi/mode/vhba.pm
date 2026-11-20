#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package hardware::server::cisco::ucs::xmlapi::mode::vhba;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global_vhba', type => 0, cb_prefix_output => 'prefix_vhba_global' },
        { name => 'global_fcport', type => 0, cb_prefix_output => 'prefix_fcport_global' },
        { name => 'vhbas',    type => 1, cb_prefix_output => 'prefix_vhba',
          message_multiple => 'All vHBAs are ok' },
        { name => 'fcports',  type => 1, cb_prefix_output => 'prefix_fcport',
          message_multiple => 'All FC ports are ok' },
    ];

    $self->{maps_counters}->{global_vhba} = [
        { label => 'vhba-total', nlabel => 'vhba.total.count', set => {
            key_values      => [ { name => 'total' } ],
            output_template => 'Total vHBAs: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
        { label => 'vhba-up',    nlabel => 'vhba.up.count',    set => {
            key_values      => [ { name => 'up' } ],
            output_template => 'Up: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
        { label => 'vhba-down',  nlabel => 'vhba.down.count',  set => {
            key_values      => [ { name => 'down' } ],
            output_template => 'Down: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
    ];

    $self->{maps_counters}->{global_fcport} = [
        { label => 'fcport-total', nlabel => 'fcport.total.count', set => {
            key_values      => [ { name => 'total' } ],
            output_template => 'Total FC ports: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
        { label => 'fcport-up',   nlabel => 'fcport.up.count',   set => {
            key_values      => [ { name => 'up' } ],
            output_template => 'Up: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
        { label => 'fcport-down', nlabel => 'fcport.down.count', set => {
            key_values      => [ { name => 'down' } ],
            output_template => 'Down: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
    ];

    $self->{maps_counters}->{vhbas} = [
        { label => 'vhba-status', type => 2,
          set => {
            key_values => [
                { name => 'name' }, { name => 'oper_state' },
                { name => 'wwpn' }, { name => 'switch_id' }, { name => 'blade' },
            ],
            output_template => "vHBA '%s' [blade: %s] [switch: %s] [WWPN: %s] oper state is '%s'",
            output_use      => ['name', 'blade', 'switch_id', 'wwpn', 'oper_state'],
            closure_custom_perfdata        => sub { return 0; },
            closure_custom_threshold_check => \&_vhba_threshold_check,
          }
        },
    ];

    $self->{maps_counters}->{fcports} = [
        { label => 'fcport-status', type => 2,
          set => {
            key_values => [
                { name => 'display' }, { name => 'oper_state' }, { name => 'speed' },
            ],
            output_template => "FC port '%s' [speed: %s] oper state is '%s'",
            output_use      => ['display', 'speed', 'oper_state'],
            closure_custom_perfdata        => sub { return 0; },
            closure_custom_threshold_check => \&_fcport_threshold_check,
          }
        },
    ];
}

sub _vhba_threshold_check {
    my ($self, %options) = @_;
    my $oper = $self->{result_values}->{oper_state};
    if (defined($self->{instance_mode}->{option_results}->{critical_vhba})
        && $self->{instance_mode}->{option_results}->{critical_vhba} ne ''
        && $oper =~ /$self->{instance_mode}->{option_results}->{critical_vhba}/) {
        return 'CRITICAL';
    }
    if (defined($self->{instance_mode}->{option_results}->{warning_vhba})
        && $self->{instance_mode}->{option_results}->{warning_vhba} ne ''
        && $oper =~ /$self->{instance_mode}->{option_results}->{warning_vhba}/) {
        return 'WARNING';
    }
    return 'OK';
}

sub _fcport_threshold_check {
    my ($self, %options) = @_;
    my $oper = $self->{result_values}->{oper_state};
    if (defined($self->{instance_mode}->{option_results}->{critical_fcport})
        && $self->{instance_mode}->{option_results}->{critical_fcport} ne ''
        && $oper =~ /$self->{instance_mode}->{option_results}->{critical_fcport}/) {
        return 'CRITICAL';
    }
    if (defined($self->{instance_mode}->{option_results}->{warning_fcport})
        && $self->{instance_mode}->{option_results}->{warning_fcport} ne ''
        && $oper =~ /$self->{instance_mode}->{option_results}->{warning_fcport}/) {
        return 'WARNING';
    }
    return 'OK';
}

sub prefix_vhba_global  { return 'vHBA statistics — '; }
sub prefix_fcport_global { return 'FC port statistics — '; }
sub prefix_vhba   { my ($self, %options) = @_; return "vHBA '" . $options{instance_value}->{name} . "' "; }
sub prefix_fcport { my ($self, %options) = @_; return "FC port '" . $options{instance_value}->{display} . "' "; }

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-vhba:s'       => { name => 'filter_vhba' },
        'filter-fcport:s'     => { name => 'filter_fcport' },
        'no-fcport'           => { name => 'no_fcport' },
        'no-vhba'             => { name => 'no_vhba' },
        'warning-vhba:s'      => { name => 'warning_vhba',    default => '' },
        'critical-vhba:s'     => { name => 'critical_vhba',   default => '^(?!up)' },
        'warning-fcport:s'    => { name => 'warning_fcport',  default => '' },
        'critical-fcport:s'   => { name => 'critical_fcport', default => '^(?!up)' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global_vhba}   = { total => 0, up => 0, down => 0 };
    $self->{global_fcport} = { total => 0, up => 0, down => 0 };
    $self->{vhbas}   = {};
    $self->{fcports} = {};

    # --- vHBAs on blades (vnicFc) ---
    unless (defined $self->{option_results}->{no_vhba}) {
        my $vhbas = $options{custom}->request(class_id => 'vnicFc');
        for my $vhba (@{$vhbas}) {
            my $dn         = $vhba->{dn}        // '';
            my $name       = $vhba->{name}      // $dn;
            my $oper_state = $vhba->{operState} // 'unknown';
            my $wwpn       = $vhba->{addr}      // '';
            my $switch_id  = $vhba->{switchId}  // '';

            # Extract blade from DN: sys/chassis-1/blade-1/adaptor-1/host-fc-1
            (my $blade = $dn) =~ s{/adaptor-\d+/.*$}{};
            $blade =~ s{sys/}{};

            next if defined($self->{option_results}->{filter_vhba})
                && $self->{option_results}->{filter_vhba} ne ''
                && $name !~ /$self->{option_results}->{filter_vhba}/;

            $self->{global_vhba}->{total}++;
            $oper_state =~ /^up$/i ? $self->{global_vhba}->{up}++ : $self->{global_vhba}->{down}++;

            $self->{vhbas}->{$dn} = {
                name       => $name,
                oper_state => $oper_state,
                wwpn       => $wwpn,
                switch_id  => $switch_id,
                blade      => $blade,
            };
        }
    }

    # --- Physical FC ports on FI (fcPIo) ---
    unless (defined $self->{option_results}->{no_fcport}) {
        my $fcports = $options{custom}->request(class_id => 'fcPIo');
        for my $port (@{$fcports}) {
            my $dn         = $port->{dn}        // '';
            my $oper_state = $port->{operState} // 'unknown';
            my $speed      = $port->{operSpeed} // 'unknown';

            (my $display = $dn) =~ s{sys/switch-}{FI-};
            $display =~ s{/switch-fc}{};

            next if defined($self->{option_results}->{filter_fcport})
                && $self->{option_results}->{filter_fcport} ne ''
                && $display !~ /$self->{option_results}->{filter_fcport}/;

            # Skip ports with no SFP unless oper state is explicitly down
            next if $oper_state =~ /^sfpNotPresent|sfp-not-present$/i;

            $self->{global_fcport}->{total}++;
            $oper_state =~ /^up$/i ? $self->{global_fcport}->{up}++ : $self->{global_fcport}->{down}++;

            $self->{fcports}->{$dn} = {
                display    => $display,
                oper_state => $oper_state,
                speed      => $speed,
            };
        }
    }
}

1;

__END__

=head1 MODE

Check Cisco UCS vHBAs and physical FC ports via XML API.
Queries vnicFc (virtual HBAs on blades) and fcPIo (physical FC ports on FI).

=over 8

=item B<--filter-vhba>

Filter vHBAs by name (regexp).

=item B<--filter-fcport>

Filter FC ports by display name (regexp).

=item B<--no-vhba>

Skip vHBA checks.

=item B<--no-fcport>

Skip physical FC port checks.

=item B<--warning-vhba>

Warning threshold for vHBA oper state (regexp on state value).

=item B<--critical-vhba>

Critical threshold for vHBA oper state. Default: '^(?!up)' (anything not 'up').

=item B<--warning-fcport>

Warning threshold for FC port oper state.

=item B<--critical-fcport>

Critical threshold for FC port oper state. Default: '^(?!up)'.

=back

=cut
