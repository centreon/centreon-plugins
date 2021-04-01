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

package storage::netapp::ontap::snmp::mode::snapmirrorlag;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'snapmirror', type => 1, cb_prefix_output => 'prefix_snapmirror_output', message_multiple => 'All snapmirrors lags are ok' },
    ];

    $self->{maps_counters}->{snapmirror} = [
         { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                output_template => "state is '%s'",
                output_use => 'state',
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'lag', set => {
                key_values => [ { name => 'lag' }, { name => 'display' } ],
                output_template => 'lag: %s seconds',
                perfdatas => [
                    { label => 'lag', value => 'lag', template => '%s', min => 0, unit => 's',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_snapmirror_output {
    my ($self, %options) = @_;

    return "Snapmirror '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'filter-status:s'   => { name => 'filter_status' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '%{state} =~ /quiesced/i' },
        'critical-status:s' => { name => 'critical_status', default => '%{state} =~ /unknown|brokenOff|uninitialized/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

sub check_snapmirror {
    my ($self, %options) = @_;

    my $oid_snapmirrorOn = '.1.3.6.1.4.1.789.1.9.1.0';
    my $oid_snapmirrorSrc = '.1.3.6.1.4.1.789.1.9.20.1.2';

    my $snmp_result = $options{snmp}->get_leef(oids => [$oid_snapmirrorOn]);
    return if (!defined($snmp_result->{$oid_snapmirrorOn}));

    if ($snmp_result->{$oid_snapmirrorOn} != 2) {
        $self->{output}->add_option_msg(short_msg => "snapmirror is not turned on.");
        $self->{output}->option_exit();
    }
    
    my $id_selected = [];
    my $snmp_result_name = $options{snmp}->get_table(oid => $oid_snapmirrorSrc);
    foreach my $oid (keys %$snmp_result_name) {
        next if ($oid !~ /\.([0-9]+)$/);
        my $instance = $1;

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result_name->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $snmp_result_name->{$oid} . "': no matching filter.", debug => 1);
            next;
        }

        push @$id_selected, $instance;
    }

    return if (scalar(@$id_selected) <= 0);

    my $map_state = {
        1 => 'uninitialized', 2 => 'snapmirrored', 
        3 => 'brokenOff', 4 => 'quiesced',
        5 => 'source', 6 => 'unknown',
    };
    my $mapping = {
        snapmirrorState => { oid => '.1.3.6.1.4.1.789.1.9.20.1.5', map => $map_state },
        snapmirrorLag   => { oid => '.1.3.6.1.4.1.789.1.9.20.1.6' },
    };

    $options{snmp}->load(oids => [$mapping->{snapmirrorState}->{oid}, $mapping->{snapmirrorLag}->{oid}], instances => $id_selected);
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    $self->{snapmirror} = {};
    foreach (@$id_selected) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);
        if (defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status} ne '' &&
            $result->{snapmirrorState} !~ /$self->{option_results}->{filter_status}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $snmp_result_name->{$oid_snapmirrorSrc . '.' . $_} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{snapmirror}->{$_} = {
            display => $snmp_result_name->{$oid_snapmirrorSrc . '.' . $_},
            state => $result->{snapmirrorState},
            lag => int($result->{snapmirrorLag} / 100),
        };
    }
}

sub check_sm {
    my ($self, %options) = @_;

    return if (scalar(keys %{$self->{snapmirror}}) > 0);

    my $oid_snapmirrorRelSrcPath = '.1.3.6.1.4.1.789.1.29.1.1.2';

    my $id_selected = [];
    my $snmp_result_name = $options{snmp}->get_table(oid => $oid_snapmirrorRelSrcPath, nothing_quit => 1);
    foreach my $oid (keys %$snmp_result_name) {
        next if ($oid !~ /\.([0-9]+)$/);
        my $instance = $1;

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result_name->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $snmp_result_name->{$oid} . "': no matching filter.", debug => 1);
            next;
        }

        push @$id_selected, $instance;
    }

    if (scalar(@$id_selected) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No snapmirrors found for filter '" . $self->{option_results}->{filter_name} . "'.");
        $self->{output}->option_exit();
    }
    
    my $map_state = {
        0 => 'uninitialized', 1 => 'snapmirrored', 2 => 'brokenOff',
    };
    my $mapping = {
        snapmirrorRelState => { oid => '.1.3.6.1.4.1.789.1.29.1.1.6', map => $map_state },
        snapmirrorRelLag   => { oid => '.1.3.6.1.4.1.789.1.29.1.1.7' },
    };

    $options{snmp}->load(oids => [$mapping->{snapmirrorRelState}->{oid}, $mapping->{snapmirrorRelLag}->{oid}], instances => $id_selected);
    my $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    $self->{snapmirror} = {};
    foreach (@$id_selected) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);
        if (defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status} ne '' &&
            $result->{snapmirrorState} !~ /$self->{option_results}->{filter_status}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $snmp_result_name->{$oid_snapmirrorRelSrcPath . '.' . $_} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{snapmirror}->{$_} = {
            display => $snmp_result_name->{$oid_snapmirrorRelSrcPath . '.' . $_},
            state => $result->{snapmirrorRelState},
            lag => int($result->{snapmirrorRelLag} / 100),
        };
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->check_snapmirror(%options);
    $self->check_sm(%options);

    if (scalar(keys %{$self->{snapmirror}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No snapmirrors found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check snapmirrors status and lag.

=over 8

=item B<--filter-name>

Filter the snapmirror name (can be a regexp).

=item B<--filter-status>

Filter on status (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--unknown-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '%{state} =~ /quiesced/i').
Can used special variables like: %{state}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} =~ /unknown|brokenOff|uninitialized/i').
Can used special variables like: %{state}, %{display}

=item B<--warning-lag>

Threshold warning.

=item B<--critical-lag>

Threshold critical.

=back

=cut
    
