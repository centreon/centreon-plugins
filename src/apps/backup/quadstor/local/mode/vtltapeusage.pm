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

package apps::backup::quadstor::local::mode::vtltapeusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status : ' . $self->{result_values}->{status};
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        $label = 'free';
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label, unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my $msg = sprintf(
        "Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{prct_used} = $options{new_datas}->{$self->{instance} . '_used_prct'};

    $self->{result_values}->{used} = $self->{result_values}->{total} * $self->{result_values}->{prct_used} / 100;
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};

    return 0;
}

sub prefix_tape_output {
    my ($self, %options) = @_;

    return "Tape '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'tape', type => 1, cb_prefix_output => 'prefix_tape_output', message_multiple => 'All tapes are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'count', set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Number of tapes : %s',
                perfdatas => [
                    { label => 'count', template => '%s', unit => 'tapes', min => 0 }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{tape} = [
        { label => 'status', type => 2, critical_default => '%{status} !~ /active/i', set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'usage', set => {
                key_values => [ { name => 'total' }, { name => 'used_prct' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'vtl-name:s'    => { name => 'vtl_name' },
        'filter-name:s' => { name => 'filter_name' },
        'units:s'       => { name => 'units', default => '%' },
        'free'          => { name => 'free' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{vtl_name}) || $self->{option_results}->{vtl_name} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to set vtl-name option.");
        $self->{output}->option_exit();
    }

    $self->{option_results}->{vtl_name} = centreon::plugins::misc::sanitize_command_param(value => $self->{option_results}->{vtl_name});
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'vcconfig',
        command_options => '-l -v ' . $self->{option_results}->{vtl_name},
        command_path => '/quadstorvtl/bin'
    );

    $self->{global}->{count} = 0;
    $self->{tape} = {};
    #Pool    Label    Element Address Vtype       WORM Size  Used% Status
    #Default 701862L2 Unknown 0       LTO 2 200GB No   200   99    Vaulted
    #Default 701899L2 Slot    1180    LTO 2 200GB No   200   0     Active
    #Default 701900L2 Slot    1181    LTO 2 200GB No   200   0     Active
    #Default 701901L2 Slot    1182    LTO 2 200GB No   200   0     Active
    #Default 701902L2 Slot    1183    LTO 2 200GB No   200   0     Active
    #Default 701903L2 Slot    1184    LTO 2 200GB No   200   0     Active
    #Default 701904L2 Slot    1185    LTO 2 200GB No   200   0     Active
    
    my @lines = split /\n/, $stdout;
    shift @lines;
    foreach (@lines) {
        next if (! /([0-9\.]+)\s+([0-9\.]+)\s+(\S+)\s*$/);
        my ($size, $used_prct, $status) = ($1, $2, $3);
        next if (! /^\S+\s+(\S+)\s+\S+\s+(\S+)/);
        my $name = $1 . '.' . $2;
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' && 
            $name !~ /$self->{option_results}->{filter_name}/i) {
            $self->{output}->output_add(long_msg => "skipping vtl '" . $name . "':  no matching filter");
            next;
        }
        
        $self->{tape}->{$name} = {
            display => $name,
            total => $size * 1024 * 1024 * 1024,
            used_prct => $used_prct,
            status => $status
        };
        $self->{global}->{count}++;
    }

    if (scalar(keys %{$self->{tape}}) == 0) {
        $self->{output}->add_option_msg(short_msg => "No tape found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check vtl tape usage.

Command used: '/quadstorvtl/bin/vcconfig -l -v %(vtl-name)'

=over 8

=item B<--vtl-name>

Set VTL name (required).

=item B<--filter-name>

Filter tape name.

=item B<--units>

Units of thresholds (default: '%') ('%', 'absolute').

=item B<--free>

Thresholds are on free tape left.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /active/i').
You can use the following variables: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'count', 'usage'.

=back

=cut
