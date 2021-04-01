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

package apps::vmware::connector::mode::snapshotvm;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Date::Parse;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'vm-hostname:s'         => { name => 'vm_hostname' },
        'filter'                => { name => 'filter' },
        'scope-datacenter:s'    => { name => 'scope_datacenter' },
        'scope-cluster:s'       => { name => 'scope_cluster' },
        'scope-host:s'          => { name => 'scope_host' },
        'filter-description:s'  => { name => 'filter_description' },
        'filter-os:s'           => { name => 'filter_os' },
        'filter-uuid:s'         => { name => 'filter_uuid' },
        'display-description'   => { name => 'display_description' },
        'check-consolidation'   => { name => 'check_consolidation' },
        'nopoweredon-skip'      => { name => 'nopoweredon_skip' },
        'warning:s'             => { name => 'warning' },
        'critical:s'            => { name => 'critical' },
        'disconnect-status:s'   => { name => 'disconnect_status', default => 'unknown' },
        'unit:s'                => { name => 'unit', default => 's' },
    });
    
    return $self;
}

my $unitdiv = { s => ['seconds', 1], w => ['weeks', 604800], d => ['days', 86400], h => ['hours', 3600], m => ['minutes', 60] };

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach my $label (('warning', 'critical')) {
        if (($self->{perfdata}->threshold_validate(label => $label, value => $self->{option_results}->{$label})) == 0) {
            my ($label_opt) = $label;
            $label_opt =~ tr/_/-/;
            $self->{output}->add_option_msg(short_msg => "Wrong " . $label_opt . " threshold '" . $self->{option_results}->{$label} . "'.");
            $self->{output}->option_exit();
        }
    }

    if ($self->{output}->is_litteral_status(status => $self->{option_results}->{disconnect_status}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong disconnect-status option '" . $self->{option_results}->{disconnect_status} . "'.");
        $self->{output}->option_exit();
    }

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }
}

sub run {
    my ($self, %options) = @_;

    my $response = $options{custom}->execute(params => $self->{option_results},
        command => 'snapshotvm');
    
    my $multiple = 0;
    my %vm_consolidate = ();
    my %vm_errors = (warning => {}, critical => {}); 
    if (scalar(keys %{$response->{data}}) > 1) {
        $multiple = 1;
    }
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                               short_msg => sprintf("All snapshots are ok"));
    } else {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf("Snapshot(s) OK"));
    }
    foreach my $vm_id (sort keys %{$response->{data}}) {
        my $vm_name = $response->{data}->{$vm_id}->{name};
        
        if ($options{custom}->entity_is_connected(state => $response->{data}->{$vm_id}->{connection_state}) == 0) {
            my $output = "VM '" . $vm_name . "' not connected. Current Connection State: '$response->{data}->{$vm_id}->{connection_state}'.";
            if ($multiple == 0 ||  
                !$self->{output}->is_status(value => $self->{option_results}->{disconnect_status}, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $self->{option_results}->{disconnect_status},
                                            short_msg => $output);
            }
            next;
        }
    
        next if (defined($self->{option_results}->{nopoweredon_skip}) && 
                 $options{custom}->vm_is_running(power => $response->{data}->{$vm_id}->{power_state}) == 0);
    
        if (defined($self->{check_consolidation}) && defined($response->{data}->{$vm_id}->{consolidation_needed}) && $response->{data}->{$vm_id}->{consolidation_needed} == 1) {
            $vm_consolidate{$response->{data}->{$vm_id}->{name}} = 1;
        }

        foreach (@{$response->{data}->{$vm_id}->{snapshosts}}) {
            my $create_time = Date::Parse::str2time($_->{create_time});
            if (!defined($create_time)) {
                $self->{output}->output_add(severity => 'UNKNOWN',
                                            short_msg => "Can't Parse date '" . $_->{create_time} . "' for vm '" . $vm_name . "'");
                next;
            }
            
            my $diff_time = time() - $create_time;
            my $days = int($diff_time / 60 / 60 / 24);
            my $exit = $self->{perfdata}->threshold_check(value => ($diff_time / $unitdiv->{$self->{option_results}->{unit}}->[1]), threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
            
            my $prefix_msg = "'$vm_name'";
            if (defined($self->{display_description}) && defined($response->{data}->{$vm_id}->{'config.annotation'}) &&
                $response->{data}->{$vm_id}->{'config.annotation'} ne '') {
                $prefix_msg .= ' [' . $options{custom}->strip_cr(value => $response->{data}->{$vm_id}->{'config.annotation'}) . ']';
            }
            my $suffix_msg = '';
            if (defined($_->{description}) && $_->{description} ne '') {
                $suffix_msg = ' [' . $options{custom}->strip_cr(value => $_->{description}) . ']';
            }
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $vm_errors{$exit}->{$vm_name} = 1;
                $self->{output}->output_add(long_msg => "$prefix_msg snapshot create time: " . $_->{create_time} . $suffix_msg);
            }
        }
    }

    $self->{output}->perfdata_add(
        label => 'num_warning',
        nlabel => 'vm.snapshots.warning.current.count',
        value => scalar(keys %{$vm_errors{warning}}),
        min => 0
    );
    $self->{output}->perfdata_add(
        label => 'num_critical',
        nlabel => 'vm.snapshots.critical.current.count',
        value => scalar(keys %{$vm_errors{critical}}),
        min => 0
    );
    if (scalar(keys %{$vm_errors{warning}}) > 0) {
        $self->{output}->output_add(
            severity => 'WARNING',
            short_msg => sprintf(
                'Snapshots for VM older than %d %s: [%s]',
                $self->{option_results}->{warning},
                $unitdiv->{$self->{option_results}->{unit}}->[0],
                join('] [', sort keys %{$vm_errors{warning}})
            )
        );
    }
    if (scalar(keys %{$vm_errors{critical}}) > 0) {
        $self->{output}->output_add(
            severity => 'CRITICAL',
            short_msg => sprintf(
                'Snapshots for VM older than %d %s: [%s]',
                $self->{option_results}->{critical}, 
                $unitdiv->{$self->{option_results}->{unit}}->[0],
                join('] [', sort keys %{$vm_errors{critical}})
            )
        );
    }
    if (scalar(keys %vm_consolidate) > 0) {
         $self->{output}->output_add(
            severity => 'CRITICAL',
            short_msg => sprintf(
                'VMs need consolidation: [%s]',
                join('] [', sort keys %vm_consolidate)
            )
        );
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check virtual machine snapshots.

=over 8

=item B<--vm-hostname>

VM hostname to check.
If not set, we check all VMs.

=item B<--filter>

VM hostname is a regexp.

=item B<--filter-description>

Filter also virtual machines description (can be a regexp).

=item B<--filter-os>

Filter also virtual machines OS name (can be a regexp).

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--scope-cluster>

Search in following cluster(s) (can be a regexp).

=item B<--scope-host>

Search in following host(s) (can be a regexp).

=item B<--display-description>

Display virtual machine description.

=item B<--check-consolidation>

Check if VM needs consolidation (since vsphere 5.0).

=item B<--disconnect-status>

Status if VM disconnected (default: 'unknown').

=item B<--nopoweredon-skip>

Skip check if VM is not poweredOn.

=item B<--unit>

Select the unit for performance data and thresholds. May be 's' for seconds, 'm' for minutes,
'h' for hours, 'd' for days, 'w' for weeks. Default is seconds

=item B<--warning>

Warning threshold for snapshot's age.

=item B<--critical>

Critical threshold for snapshot's age.

=back

=cut
