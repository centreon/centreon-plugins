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

package network::stormshield::api::mode::interfaces;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s (%s)',
        $self->{result_values}->{plugged},
        $self->{result_values}->{state}
    );
}

sub custom_traffic_perfdata {
    my ($self, %options) = @_;

    my ($warning, $critical);
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq 'percent_delta' && defined($self->{result_values}->{speed})) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} =~ /bps|counter/) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    }

    if ($self->{instance_mode}->{option_results}->{units_traffic} eq 'counter') {
        my $nlabel = $self->{nlabel};
        $nlabel =~ s/bitspersecond/bits/;
        $self->{output}->perfdata_add(
            nlabel => $nlabel,
            unit => 'b',
            instances => [$self->{result_values}->{user_name}, $self->{result_values}->{real_name}],
            value => $self->{result_values}->{traffic_counter},
            warning => $warning,
            critical => $critical,
            min => 0
        );
    } else {
        $self->{output}->perfdata_add(
            nlabel => $self->{nlabel},
            instances => [$self->{result_values}->{user_name}, $self->{result_values}->{real_name}],
            value => sprintf('%.2f', $self->{result_values}->{traffic_per_seconds}),
            warning => $warning,
            critical => $critical,
            min => 0,
            max => $self->{result_values}->{speed}
        );
    }
}

sub custom_traffic_threshold {
    my ($self, %options) = @_;

    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq 'percent_delta' && defined($self->{result_values}->{speed})) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'bps') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_per_seconds}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'counter') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_counter}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_traffic_output {
    my ($self, %options) = @_;

    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic_per_seconds}, network => 1);    
    return sprintf(
        'traffic %s: %s/s (%s)',
        $self->{result_values}->{label}, $traffic_value . $traffic_unit,
        defined($self->{result_values}->{traffic_prct}) ? sprintf('%.2f%%', $self->{result_values}->{traffic_prct}) : '-'
    );
}

sub custom_traffic_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{traffic_per_seconds} = ($options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} } - $options{old_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} }) / $options{delta_time};
    $self->{result_values}->{traffic_per_seconds} = sprintf('%d', $self->{result_values}->{traffic_per_seconds});

    if (defined($options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}}) &&
        $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}} ne '' && 
        $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}} > 0) {
        $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic_per_seconds} * 100 / $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}};
        $self->{result_values}->{speed} = $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}};
    }

    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{user_name} = $options{new_datas}->{ $self->{instance} . '_user_name' };
    $self->{result_values}->{real_name} = $options{new_datas}->{ $self->{instance} . '_real_name' };
    return 0;
}

##############
# Errors
sub custom_errors_perfdata {
    my ($self, %options) = @_;

    if ($self->{instance_mode}->{option_results}->{units_errors} =~ /percent/) {
        my $nlabel = $self->{nlabel};
        $nlabel =~ s/count$/percentage/;

        $self->{output}->perfdata_add(
            nlabel => $nlabel,
            unit => '%',
            instances => [$self->{result_values}->{user_name}, $self->{result_values}->{real_name}],
            value => sprintf('%.2f', $self->{result_values}->{prct}),
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
            min => 0,
            max => 100
        );
    } else {
        $self->{output}->perfdata_add(
            nlabel => $self->{nlabel},
            instances => [$self->{result_values}->{user_name}, $self->{result_values}->{real_name}],
            value => $self->{result_values}->{used},
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
            min => 0,
            max => $self->{result_values}->{total}
        );
    }
}

sub custom_errors_threshold {
    my ($self, %options) = @_;

    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{units_errors} =~ /percent/) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } else {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{used}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_errors_output {
    my ($self, %options) = @_;

    return sprintf(
        'packets %s: %.2f%% (%s on %s)',
        $self->{result_values}->{label},
        $self->{result_values}->{prct},
        $self->{result_values}->{used},
        $self->{result_values}->{total}
    );
}

sub custom_errors_calc {
    my ($self, %options) = @_;

    my $errors = $options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} };
    my $errors_diff = $options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} } -  $options{old_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} };
    my $total = $options{new_datas}->{$self->{instance} . '_total_packets'};
    my $total_diff = $options{new_datas}->{$self->{instance} . '_total_packets'} - $options{old_datas}->{$self->{instance} . '_total_packets'};

    $self->{result_values}->{prct} = 0;
    $self->{result_values}->{used} = $errors_diff;
    $self->{result_values}->{total} = $total_diff;
    if ($self->{instance_mode}->{option_results}->{units_errors} eq 'percent_delta') {
        $self->{result_values}->{prct} = $errors_diff * 100 / $total_diff if ($total_diff > 0);
    } elsif ($self->{instance_mode}->{option_results}->{units_errors} eq 'percent') {
        $self->{result_values}->{prct} = $errors * 100 / $total if ($total > 0);
        $self->{result_values}->{used} = $errors;
        $self->{result_values}->{total} = $total;
    } elsif ($self->{instance_mode}->{option_results}->{units_errors} eq 'delta') {
        $self->{result_values}->{prct} = $errors_diff * 100 / $total_diff if ($total_diff > 0);
        $self->{result_values}->{used} = $errors_diff;
    } else {
        $self->{result_values}->{prct} = $errors * 100 / $total if ($total > 0);
        $self->{result_values}->{used} = $errors;
        $self->{result_values}->{total} = $total;
    }

    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{user_name} = $options{new_datas}->{ $self->{instance} . '_user_name' };
    $self->{result_values}->{real_name} = $options{new_datas}->{ $self->{instance} . '_real_name' };
    return 0;
}

sub prefix_interface_output {
    my ($self, %options) = @_;

    return sprintf(
        "Interface '%s' [%s] ",
        $options{instance_value}->{real_name},
        $options{instance_value}->{user_name}
    );
}

sub skip_counters {
    my ($self, %options) = @_;

    return (defined($self->{option_results}->{$options{filter}})) ? 0 : 1;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'interfaces', type => 1, cb_prefix_output => 'prefix_interface_output', message_multiple => 'All interfaces are ok', cb_init_counters => 'skip_counters', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{interfaces} = [
        {
            label => 'status',
            type => 2,
            filter => 'add_status',
            critical_default => "%{state} eq 'down'", set => {
                key_values => [ { name => 'state' }, { name => 'plugged' }, { name => 'real_name' }, { name => 'user_name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'in-traffic', filter => 'add_traffic', nlabel => 'interface.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'in', diff => 1 }, { name => 'speed_in' }, { name => 'real_name' }, { name => 'user_name' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'traffic in: %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'out-traffic', filter => 'add_traffic', nlabel => 'interface.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'out', diff => 1 }, { name => 'speed_out' }, { name => 'real_name' }, { name => 'user_name' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'traffic out: %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'packets-accepted', filter => 'add_errors', nlabel => 'interface.packets.accepted.count', set => {
                key_values => [ { name => 'accepted', diff => 1 }, { name => 'total_packets', diff => 1 }, , { name => 'real_name' }, { name => 'user_name' } ],
                closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref => 'accepted' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'packets blocked: %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        },
        { label => 'packets-blocked', filter => 'add_errors', nlabel => 'interface.packets.blocked.count', set => {
                key_values => [ { name => 'blocked', diff => 1 }, { name => 'total_packets', diff => 1 }, , { name => 'real_name' }, { name => 'user_name' } ],
                closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref => 'blocked' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'packets blocked: %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-user-name:s' => { name => 'filter_user_name' },
        'filter-real-name:s' => { name => 'filter_real_name' },
        'add-status'         => { name => 'add_status' },
        'add-traffic'        => { name => 'add_traffic' },
        'add-errors'         => { name => 'add_errors' },
        'units-traffic:s'    => { name => 'units_traffic', default => 'percent_delta' },
        'speed:s'            => { name => 'speed' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    # If no options, we set add-status
    if (!defined($self->{option_results}->{add_traffic}) &&
        !defined($self->{option_results}->{add_errors}) &&
        !defined($self->{option_results}->{add_status})) {
        $self->{option_results}->{add_status} = 1;
    }

    if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
        if ($self->{option_results}->{speed} !~ /^[0-9]+(\.[0-9]+){0,1}$/) {
            $self->{output}->add_option_msg(short_msg => "Speed must be a positive number '" . $self->{option_results}->{speed} . "' (can be a float also).");
            $self->{output}->option_exit();
        } else {
            $self->{option_results}->{speed} *= 1000000;
        }
    }

    if (defined($self->{option_results}->{add_traffic})) {
        $self->{option_results}->{units_traffic} = 'percent_delta'
            if (!defined($self->{option_results}->{units_traffic}) ||
                $self->{option_results}->{units_traffic} eq '' ||
                $self->{option_results}->{units_traffic} eq '%');
        if ($self->{option_results}->{units_traffic} !~ /^(?:percent|percent_delta|bps|counter)$/) {
            $self->{output}->add_option_msg(short_msg => 'Wrong option --units-traffic.');
            $self->{output}->option_exit();
        }
    }

    if (defined($self->{option_results}->{add_errors})) {
        $self->{option_results}->{units_errors} = 'percent_delta'
            if (!defined($self->{option_results}->{units_errors}) ||
                $self->{option_results}->{units_errors} eq '' ||
                $self->{option_results}->{units_errors} eq '%');
        if ($self->{option_results}->{units_errors} !~ /^(?:percent|percent_delta|delta|counter)$/) {
            $self->{output}->add_option_msg(short_msg => 'Wrong option --units-errors.');
            $self->{output}->option_exit();
        }
    }

    $self->{checking} = '';
    foreach ('add_status', 'add_errors', 'add_traffic') {
        if (defined($self->{option_results}->{$_})) {
            $self->{checking} .= $_;
        }
    }
}

my $map_state = { 0 => 'down', 1 => 'up' };
my $map_plugged = { 0 => 'passive', 1 => 'active' };

sub manage_selection {
    my ($self, %options) = @_;

    my $interfaces = $options{custom}->request(command => 'monitor interface');

    $self->{interfaces} = {};
    foreach my $interface (@{$interfaces->{Result}}) {
        my ($user_name, $real_name) = split(/,/, $interface->{name});
        next if (defined($self->{option_results}->{filter_user_name}) && $self->{option_results}->{filter_user_name} ne '' &&
            $user_name !~ /$self->{option_results}->{filter_user_name}/);
        next if (defined($self->{option_results}->{filter_real_name}) && $self->{option_results}->{filter_real_name} ne '' &&
            $real_name !~ /$self->{option_results}->{filter_real_name}/);

        my ($traffic_out) = split(/,/, $interface->{byte_out});
        my ($traffic_in) = split(/,/, $interface->{byte});

        my ($accepted, $blocked) = split(/,/, $interface->{packet});

        $self->{interfaces}->{$real_name} = {
            real_name => $real_name,
            user_name => $user_name,
            state => $map_state->{ $interface->{state} },
            plugged => $map_plugged->{ $interface->{plugged} },
            speed_in => defined($self->{option_results}->{speed}) ? $self->{option_results}->{speed} : '',
            speed_out => defined($self->{option_results}->{speed}) ? $self->{option_results}->{speed} : '',
            in => $traffic_in,
            out => $traffic_out,
            accepted => $accepted,
            blocked => $blocked,
            total_packets => $accepted + $blocked
        };
    }
    
    if (scalar(keys %{$self->{interfaces}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No interface found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = 'stormshield_' . $options{custom}->get_connection_info() . '_' . $self->{mode} . '_' .
        md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{filter_real_name}) ? $self->{option_results}->{filter_real_name} : '') . '_' .
            (defined($self->{option_results}->{filter_user_name}) ? $self->{option_results}->{filter_user_name} : '') . '_' .
            $self->{checking}
        );
}

1;

__END__

=head1 MODE

Check interfaces.

=over 8

=item B<--filter-real-name>

Filter interfaces by real name (regexp can be used).

=item B<--filter-user-name>

Filter interfaces by user name (regexp can be used).

=item B<--add-status>

Check interface status.

=item B<--add-traffic>

Check interface traffic.

=item B<--add-errors>

Check interface errors.

=item B<--units-traffic>

Units of thresholds for the traffic (default: 'percent_delta') ('percent_delta', 'bps', 'counter').

=item B<--units-traffic>

Units of thresholds for the traffic (default: 'percent_delta') ('percent_delta', 'bps', 'counter').

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{plugged}, %{user_name}, %{real_name}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{plugged}, %{user_name}, %{real_name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: "%{state} eq 'down'")
You can use the following variables: %{state}, %{plugged}, %{user_name}, %{real_name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'in-traffic', 'out-traffic', 'packets-accepted', 'packets-blocked',

=item B<--speed>

Set interface speed (in Mb).

=back

=cut
