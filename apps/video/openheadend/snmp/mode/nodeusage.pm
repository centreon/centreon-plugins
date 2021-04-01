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

package apps::video::openheadend::snmp::mode::nodeusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'dependancy status : ' . $self->{result_values}->{dep_status};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{dep_status} = $options{new_datas}->{$self->{instance} . '_nodeDepStatus'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'node', type => 1, cb_prefix_output => 'prefix_node_output', message_multiple => 'All nodes are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{node} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'nodeDepStatus' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'bitrate', set => {
                key_values => [ { name => 'nodeBitrate' }, { name => 'display' } ],
                output_template => 'bitRate : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'bitrate', value => 'nodeBitrate', template => '%d',
                      unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
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
                                  "filter-name:s"       => { name => 'filter_name' },
                                  "warning-status:s"    => { name => 'warning_status', default => '' },
                                  "critical-status:s"   => { name => 'critical_status', default => '%{dep_status} =~ /false/i' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_node_output {
    my ($self, %options) = @_;
    
    return "Node '" . $options{instance_value}->{display} . "' ";
}

my %map_type = (1 => 'net', 2 => 'dvb', 3 => 'file', 4 => 'circular-file',
    5 => 'directory', 6 => 'asi-rx', 7 => 'rtsp', 8 => 'jpeg',
    9 => 'video', 10 => 'audio', 11 => 'video-rx', 12 => 'extract'
);
my %map_status = (1 => 'true', 2 => 'false');
my $mapping = {
    nodeType        => { oid => '.1.3.6.1.4.1.35902.1.4.1.1.3', map => \%map_type },
    nodeDepStatus   => { oid => '.1.3.6.1.4.1.35902.1.4.1.1.5', map => \%map_status },
    nodeName        => { oid => '.1.3.6.1.4.1.35902.1.4.1.1.7' },
    nodeBitrate     => { oid => '.1.3.6.1.4.1.35902.1.4.2.1.9' },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{node} = {};
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [ 
            { oid => $mapping->{nodeType}->{oid} },
            { oid => $mapping->{nodeDepStatus}->{oid} },
            { oid => $mapping->{nodeName}->{oid} },
            { oid => $mapping->{nodeBitrate}->{oid} },
        ],
        return_type => 1, nothing_quit => 1);

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{nodeName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{nodeName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{nodeName} . "': no matching filter.", debug => 1);
            next;
        }
        
        $result->{nodeBitrate} = !defined($result->{nodeBitrate}) || $result->{nodeBitrate} == 0 ? undef : $result->{nodeBitrate};
        $self->{node}->{$instance} = { 
            display => $result->{nodeName},
            %$result
        };
    }
    
    if (scalar(keys %{$self->{node}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No node found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check node usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--filter-name>

Filter node name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{dep_status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{dep_status} =~ /false/i').
Can used special variables like: %{dep_status}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'bitrate'.

=item B<--critical-*>

Threshold critical.
Can be: 'bitrate'.

=back

=cut
