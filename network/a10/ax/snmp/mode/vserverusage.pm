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

package network::a10::ax::snmp::mode::vserverusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'status : ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_axVirtualServerStatStatus'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vserver', type => 1, cb_prefix_output => 'prefix_vserver_output', message_multiple => 'All virtual servers are ok' }
    ];
    
    $self->{maps_counters}->{vserver} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'axVirtualServerStatStatus' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'current-con', nlabel => 'virtualserver.connections.current.count', set => {
                key_values => [ { name => 'axVirtualServerStatCurConns' }, { name => 'display' } ],
                output_template => 'Current Connections : %s',
                perfdatas => [
                    { label => 'current_connections', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'total-con', nlabel => 'virtualserver.connections.total.count', set => {
                key_values => [ { name => 'axVirtualServerStatTotConns', diff => 1 }, { name => 'display' } ],
                output_template => 'Total Connections : %s',
                perfdatas => [
                    { label => 'total_connections', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-in', nlabel => 'virtualserver.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'axVirtualServerStatBytesIn', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic In : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-out', nlabel => 'virtualserver.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'axVirtualServerStatBytesOut', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic Out : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_vserver_output {
    my ($self, %options) = @_;
    
    return "Virtual Server '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} =~ /down/i' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_status = (
    1 => 'up', 2 => 'down', 3 => 'disabled',
);
my $oid_axVirtualServerStatName = '.1.3.6.1.4.1.22610.2.4.3.4.2.1.1.2';
my $mapping = {
    axVirtualServerStatBytesIn  => { oid => '.1.3.6.1.4.1.22610.2.4.3.4.2.1.1.4' },
    axVirtualServerStatBytesOut => { oid => '.1.3.6.1.4.1.22610.2.4.3.4.2.1.1.6' },
    axVirtualServerStatTotConns => { oid => '.1.3.6.1.4.1.22610.2.4.3.4.2.1.1.8' },
    axVirtualServerStatCurConns => { oid => '.1.3.6.1.4.1.22610.2.4.3.4.2.1.1.9' },
    axVirtualServerStatStatus   => { oid => '.1.3.6.1.4.1.22610.2.4.3.4.2.1.1.10', map => \%map_status },
};

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $snmp_result = $options{snmp}->get_table(oid => $oid_axVirtualServerStatName, nothing_quit => 1);
    $self->{vserver} = {};
    foreach my $oid (keys %{$snmp_result}) {
        $oid =~ /^$oid_axVirtualServerStatName\.(.*)$/;
        my $instance = $1;
        $snmp_result->{$oid} =~ s/\\//g;
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping virtual server '" . $snmp_result->{$oid} . "'.", debug => 1);
            next;
        }
        
        $self->{vserver}->{$instance} = { display => $snmp_result->{$oid} };
    }
    
    $options{snmp}->load(oids => [$mapping->{axVirtualServerStatBytesIn}->{oid}, $mapping->{axVirtualServerStatBytesOut}->{oid},
        $mapping->{axVirtualServerStatTotConns}->{oid}, $mapping->{axVirtualServerStatCurConns}->{oid},
        $mapping->{axVirtualServerStatStatus}->{oid}
        ], 
        instances => [keys %{$self->{vserver}}], instance_regexp => '^(.*)$');
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach (keys %{$self->{vserver}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);        
        
        foreach my $name (('axVirtualServerStatBytesIn', 'axVirtualServerStatBytesOut')) {
            $result->{$name} *= 8;
        }
        
        foreach my $name (keys %$mapping) {
            $self->{vserver}->{$_}->{$name} = $result->{$name};
        }
    }
    
    if (scalar(keys %{$self->{vserver}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No virtual server found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "a10_ax_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check virtual server usage.

=over 8

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /down/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'current-con', 'total-con', 'traffic-in', 'traffic-out'.

=item B<--critical-*>

Threshold critical.
Can be: 'current-con', 'total-con', 'traffic-in', 'traffic-out'.

=item B<--filter-name>

Filter by virtual server name (can be a regexp).

=back

=cut
