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

package apps::video::openheadend::snmp::mode::operationstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'status : ' . $self->{result_values}->{dep_status};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_operationOpStatus'};
    $self->{result_values}->{dep_status} = $options{new_datas}->{$self->{instance} . '_operationDepStatus'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'operation', type => 1, cb_prefix_output => 'prefix_operation_output', message_multiple => 'All operations are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{operation} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'operationOpStatus' }, { name => 'operationDepStatus' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-id:s"         => { name => 'filter_id' },
                                  "warning-status:s"    => { name => 'warning_status', default => '' },
                                  "critical-status:s"   => { name => 'critical_status', default => '%{status} =~ /false/i' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_operation_output {
    my ($self, %options) = @_;
    
    return "Operation '" . $options{instance_value}->{display} . "' ";
}

my %map_type = (1 => 'demux', 2 => 'monitor-pid', 3 => 'monitor-type',
    4 => 'playout-file', 5 => 'playout-circular-file', 6 => 'monitor-sid',
    7 => 'playout-directory', 8 => 'hint', 9 => 'transcode-avc', 10 => 'transcode-mp2',
    11 => 'transcode-aac', 12 => 'transmit-input', 13 => 'transmit-output',
    14 => 'transcode-a52', 15 => 'grid-input', 16 => 'grid-acquire-mono',
    17 => 'grid-acquire-stereo', 18 => 'acquire-mono', 19 => 'acquire-stereo',
    20 => 'mux-input', 21 => 'remap-pid', 22 => 'remap-sid',
    23 => 'mosaic', 24 => 'hint-scte35',
);
my %map_status = (1 => 'true', 2 => 'false');
my $mapping = {
    operationType       => { oid => '.1.3.6.1.4.1.35902.1.6.1.1.3', map => \%map_type },
    operationDepStatus  => { oid => '.1.3.6.1.4.1.35902.1.6.1.1.5', map => \%map_status },
    operationOpStatus   => { oid => '.1.3.6.1.4.1.35902.1.6.1.1.7', map => \%map_status },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{operation} = {};
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [ 
            { oid => $mapping->{operationType}->{oid} },
            { oid => $mapping->{operationDepStatus}->{oid} },
            { oid => $mapping->{operationOpStatus}->{oid} },
        ],
        return_type => 1, nothing_quit => 1);

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{operationOpStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $instance !~ /$self->{option_results}->{filter_id}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $instance . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $result->{operationType} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{operationType} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{operation}->{$instance} = { 
            display => $instance,
            %$result
        };
    }
    
    if (scalar(keys %{$self->{operation}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No operation found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check operation status.

=over 8

=item B<--filter-id>

Filter by operation ID (can be a regexp).

=item B<--filter-type>

Filter by operation type (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{dep_status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{dep_status} =~ /false/i').
Can used special variables like: %{status}, %{dep_status}, %{display}

=back

=cut
