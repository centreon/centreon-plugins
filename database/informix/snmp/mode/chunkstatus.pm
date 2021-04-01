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

package database::informix::snmp::mode::chunkstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("status is '%s'", $self->{result_values}->{status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'chunk', type => 1, cb_prefix_output => 'prefix_chunk_output', message_multiple => 'All chunks are ok' }
    ];
    
    $self->{maps_counters}->{chunk} = [
        { label => 'status', set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_chunk_output {
    my ($self, %options) = @_;
    
    return "Chunk '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s"     => { name => 'filter_name' },
        "unknown-status:s"  => { name => 'unknown_status' },
        "warning-status:s"  => { name => 'warning_status' },
        "critical-status:s" => { name => 'critical_status', default => '%{status} =~ /inconsistent/' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

my %mapping_status = (
    1 => 'offline', 2 => 'online', 3 => 'recovering', 4 => 'inconsistent', 5 => 'dropped',
);

my $mapping = {
    onChunkFileName     => { oid => '.1.3.6.1.4.1.893.1.1.1.7.1.2' },
    onChunkStatus       => { oid => '.1.3.6.1.4.1.893.1.1.1.7.1.7', map => \%mapping_status },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_applName = '.1.3.6.1.2.1.27.1.1.2';
    my $oid_onDbspaceName = '.1.3.6.1.4.1.893.1.1.1.6.1.2';
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
            { oid => $oid_applName },
            { oid => $oid_onDbspaceName },
            { oid => $mapping->{onChunkFileName}->{oid} },
            { oid => $mapping->{onChunkStatus}->{oid} },
        ], return_type => 1, nothing_quit => 1
    );

    $self->{chunk} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{onChunkFileName}->{oid}\.(.*?)\.(.*?)\.(.*)/);
        my ($applIndex, $dbSpaceIndex, $chunkIndex) = ($1, $2, $3);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $applIndex . '.' . $dbSpaceIndex . '.' . $chunkIndex);
        
        my $name = 'default';
        $name = $snmp_result->{$oid_applName . '.' . $applIndex} 
            if (defined($snmp_result->{$oid_applName . '.' . $applIndex}));
        $name .= '.' . $snmp_result->{$oid_onDbspaceName . '.' . $applIndex. '.' . $dbSpaceIndex};
        $name .= '.' . $result->{onChunkFileName};
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{chunk}->{$name} = { 
            display => $name, 
            status => $result->{onChunkStatus},
        };
    }
    
    if (scalar(keys %{$self->{chunk}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No chunk found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check chunk status.

=over 8

=item B<--filter-name>

Filter chunk name (can be a regexp).

=item B<--unknown-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /inconsistent/').
Can used special variables like: %{status}, %{display}

=back

=cut
