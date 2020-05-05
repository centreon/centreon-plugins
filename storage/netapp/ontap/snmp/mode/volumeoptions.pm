#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package storage::netapp::ontap::snmp::mode::volumeoptions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_options_threshold {
    my ($self, %options) = @_;

    my $status = catalog_status_threshold($self, %options);
    if (!$self->{output}->is_status(value => $status, compare => 'ok', litteral => 1)) {
        $self->{instance_mode}->{global}->{failed}++;
    }
    return $status;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_options_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{options} = $options{new_datas}->{$self->{instance} . '_options'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'volumes', type => 1, cb_prefix_output => 'prefix_volume_output', message_multiple => 'All volumes are ok', skipped_code => { -10 => 1 } },
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{volumes} = [
         { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                output_template => "status is '%s'",
                output_use => 'status',
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'options', threshold => 0, set => {
                key_values => [ { name => 'options' }, { name => 'display' } ],
                output_template => "options: '%s'",
                output_use => 'options',
                closure_custom_calc => $self->can('custom_options_calc'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_options_threshold'),
            }
        },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'failed', display_ok => 0, set => {
                key_values => [ { name => 'failed' } ],
                output_template => 'Failed: %s',
                perfdatas => [
                    { label => 'failed', value => 'failed_absolute', template => '%s', min => 0 },
                ],
            }
        },
    ];
}

sub prefix_volume_output {
    my ($self, %options) = @_;

    return "Volume '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'      => { name => 'filter_name' },
        'filter-status:s'    => { name => 'filter_status' },
        'unknown-status:s'   => { name => 'unknown_status', default => '' },
        'warning-status:s'   => { name => 'warning_status', default => '' },
        'critical-status:s'  => { name => 'critical_status', default => '' },
        'unknown-options:s'  => { name => 'unknown_options', default => '' },
        'warning-options:s'  => { name => 'warning_options', default => '' },
        'critical-options:s' => { name => 'critical_options', default => '' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{test_option} = 0;
    foreach ('warning', 'unknown', 'critical') {
        $self->{test_option} = 1 if (defined($self->{option_results}->{$_ . '_options'}) && $self->{option_results}->{$_ . '_options'} ne '');
    }
    $self->change_macros(macros => ['warning_options', 'critical_options', 'unknown_options',
        'warning_status', 'critical_status', 'unknown_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_volName = '.1.3.6.1.4.1.789.1.5.8.1.2';    
    my $id_selected = [];
    my $snmp_result_name = $options{snmp}->get_table(oid => $oid_volName, nothing_quit => 1);
    foreach my $oid (keys %{$snmp_result_name}) {
        next if ($oid !~ /\.([0-9]+)$/);
        my $instance = $1;
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result_name->{oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $snmp_result_name->{oid} . "': no matching filter.", debug => 1);
            next;
        }
        push @{$id_selected}, $instance; 
    }

    if (scalar(@{$id_selected}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No volume found for name '" . $self->{option_results}->{filter_name} . "'.");
        $self->{output}->option_exit();
    }
    
    my $mapping = {
        volState     => { oid => '.1.3.6.1.4.1.789.1.5.8.1.5' },
        volOptions   => { oid => '.1.3.6.1.4.1.789.1.5.8.1.7' },
    };
    
    my $load_oids = [$mapping->{volState}->{oid}];
    push @$load_oids, $mapping->{volOptions}->{oid} if ($self->{test_option} == 1);
    $options{snmp}->load(oids => $load_oids, instances => $id_selected);
    my $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    $self->{global} = { failed => 0 };
    $self->{volumes} = {};
    foreach (@{$id_selected}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);
        if (defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status} ne '' &&
            $result->{volState} !~ /$self->{option_results}->{filter_status}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $snmp_result_name->{$oid_volName . '.' . $_} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{volumes}->{$_} = {
            display => $snmp_result_name->{$oid_volName . '.' . $_},
            status => $result->{volState},
            options => $result->{volOptions},
        };
    }
    
    if (scalar(keys %{$self->{volumes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No volume found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check options from volumes.

=over 8

=item B<--filter-name>

Filter on volume name (can be a regexp).

=item B<--filter-status>

Filter on volume status (can be a regexp).

=item B<--unknown-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--unknown-options>

Set warning threshold for status (Default: '').
Can used special variables like: %{options}, %{display}

=item B<--warning-options>

Set warning threshold for status (Default: '').
Can used special variables like: %{options}, %{display}

=item B<--critical-options>

Set critical threshold for status (Default: '').
Can used special variables like: %{options}, %{display}

=back

=cut
    
