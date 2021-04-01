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

package network::citrix::netscaler::snmp::mode::vserverstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vservers', type => 1, cb_prefix_output => 'prefix_vservers_output', message_multiple => 'All Virtual Servers are ok' }
    ];
    
    $self->{maps_counters}->{vservers} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'state' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_threshold_output')
            }
        },
        { label => 'health', nlabel => 'vserver.health.percentage', set => {
                key_values => [ { name => 'health' }, { name => 'display' } ],
                output_template => 'Health: %.2f %%', output_error_template => 'Health: %s',
                perfdatas => [
                    { label => 'health', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'in-traffic', nlabel => 'vserver.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'in', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic In: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'out-traffic', nlabel => 'vserver.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'out', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic Out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'clients', nlabel => 'vserver.connections.client.count', set => {
                key_values => [ { name => 'clients', diff => 1 }, { name => 'display' } ],
                output_template => 'Total Client Connections : %s',
                perfdatas => [
                    { label => 'clients', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'servers', nlabel => 'vserver.connections.server.count', set => {
                key_values => [ { name => 'servers', diff => 1 }, { name => 'display' } ],
                output_template => 'Total Server Connections : %s',
                perfdatas => [
                    { label => 'servers', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub prefix_vservers_output {
    my ($self, %options) = @_;
    
    return "Virtual Server '" . $options{instance_value}->{display} . "' ";
}

my $overload_th = {};

my $thresholds = {
    vs => [
        ['unknown', 'UNKNOWN'],
        ['down|outOfService|transitionToOutOfService|transitionToOutOfServiceDown', 'CRITICAL'],
        ['up', 'OK'],
    ],
};

sub get_severity {
    my (%options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($overload_th->{$options{section}})) {
        foreach (@{$overload_th->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

sub custom_threshold_output {
    my ($self, %options) = @_;
    
    return get_severity(section => 'vs', value => $self->{result_values}->{state});
}

sub custom_status_output {
    my ($self, %options) = @_;

    return 'State : ' . $self->{result_values}->{state};
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'         => { name => 'filter_name' },
        'filter-type:s'         => { name => 'filter_type' },
        'force-counters64'      => { name => 'force_counters64' },
        'threshold-overload:s@' => { name => 'threshold_overload' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ('vs', $1, $2);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $overload_th->{$section} = [] if (!defined($overload_th->{$section}));
        push @{$overload_th->{$section}}, {filter => $filter, status => $status};
    }
}

my %map_vs_type = (
    0 => 'unknown', 
    1 => 'loadbalancing', 
    2 => 'loadbalancinggroup', 
    3 => 'sslvpn', 
    4 => 'contentswitching', 
    5 => 'cacheredirection',
);

my %map_vs_status = (
    1 => 'down', 
    2 => 'unknown', 
    3 => 'busy', 
    4 => 'outOfService', 
    5 => 'transitionToOutOfService', 
    7 => 'up',
    8 => 'transitionToOutOfServiceDown',
);

my $mapping = {
    vsvrState                   => { oid => '.1.3.6.1.4.1.5951.4.1.3.1.1.5', map => \%map_vs_status },
    vsvrFullName                => { oid => '.1.3.6.1.4.1.5951.4.1.3.1.1.59' },
    vsvrEntityType              => { oid => '.1.3.6.1.4.1.5951.4.1.3.1.1.64', map => \%map_vs_type },   
};
my $mapping2 = {
    vsvrTotalRequestBytesLow    => { oid => '.1.3.6.1.4.1.5951.4.1.3.1.1.13' },
    vsvrTotalRequestBytesHigh   => { oid => '.1.3.6.1.4.1.5951.4.1.3.1.1.14' },
    vsvrTotalResponseBytesLow   => { oid => '.1.3.6.1.4.1.5951.4.1.3.1.1.17' },
    vsvrTotalResponseBytesHigh  => { oid => '.1.3.6.1.4.1.5951.4.1.3.1.1.18' },
    vsvrTotalRequestBytes       => { oid => '.1.3.6.1.4.1.5951.4.1.3.1.1.31' },
    vsvrTotalResponseBytes      => { oid => '.1.3.6.1.4.1.5951.4.1.3.1.1.33' },
    vsvrTotalClients            => { oid => '.1.3.6.1.4.1.5951.4.1.3.1.1.56' },
    vsvrHealth                  => { oid => '.1.3.6.1.4.1.5951.4.1.3.1.1.62' },
    vsvrTotalServers            => { oid => '.1.3.6.1.4.1.5951.4.1.3.1.1.65' },
};

sub manage_selection {
    my ($self, %options) = @_;
 
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping->{vsvrFullName}->{oid} },
            { oid => $mapping->{vsvrState}->{oid} },
            { oid => $mapping->{vsvrEntityType}->{oid} }
        ],
        return_type => 1,
        nothing_quit => 1
    );

    $self->{vservers} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{vsvrFullName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $result->{vsvrEntityType} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping Virtual Server '" . $result->{vsvrFullName} . "'.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{vsvrFullName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping Virtual Server '" . $result->{vsvrFullName} . "'.", debug => 1);
            next;
        }
        
        $self->{vservers}->{$instance} = { display => $result->{vsvrFullName}, state => $result->{vsvrState} };
    }

    if (scalar(keys %{$self->{vservers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No virtual server found.");
        $self->{output}->option_exit();
    }
    
    $options{snmp}->load(
        oids => defined($self->{option_results}->{force_counters64}) ? [
            $mapping2->{vsvrTotalRequestBytes}->{oid}, $mapping2->{vsvrTotalResponseBytes}->{oid},
            $mapping2->{vsvrTotalClients}->{oid}, $mapping2->{vsvrHealth}->{oid}, $mapping2->{vsvrTotalServers}->{oid}
        ] : [
            $mapping2->{vsvrTotalRequestBytesLow}->{oid}, $mapping2->{vsvrTotalRequestBytesHigh}->{oid},
            $mapping2->{vsvrTotalResponseBytesLow}->{oid}, $mapping2->{vsvrTotalResponseBytesHigh}->{oid},
            $mapping2->{vsvrTotalRequestBytes}->{oid}, $mapping2->{vsvrTotalResponseBytes}->{oid},
            $mapping2->{vsvrTotalClients}->{oid}, $mapping2->{vsvrHealth}->{oid}, $mapping2->{vsvrTotalServers}->{oid}
        ],
        instances => [keys %{$self->{vservers}}], instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{vservers}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => $_);        
        
        $self->{vservers}->{$_}->{out} = defined($result->{vsvrTotalResponseBytes}) ? $result->{vsvrTotalResponseBytes} * 8 :
            (($result->{vsvrTotalResponseBytesHigh} << 32) + $result->{vsvrTotalResponseBytesLow}) * 8;
        $self->{vservers}->{$_}->{in} = defined($result->{vsvrTotalRequestBytes}) ? $result->{vsvrTotalRequestBytes} * 8 :
            (($result->{vsvrTotalRequestBytesHigh} << 32) + $result->{vsvrTotalRequestBytesLow}) * 8;
        $self->{vservers}->{$_}->{health} = $result->{vsvrHealth};
        $self->{vservers}->{$_}->{clients} = $result->{vsvrTotalClients};
        $self->{vservers}->{$_}->{servers} = $result->{vsvrTotalServers};
    }

    $self->{cache_name} = "citrix_netscaler_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_type}) ? md5_hex($self->{option_results}->{filter_type}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check vservers status and health.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'in-traffic', 'out-traffic', 'health' (%),
'clients', 'servers'.

=item B<--critical-*>

Threshold critical.
Can be: 'in-traffic', 'out-traffic', 'health' (%),
'clients', 'servers'.

=item B<--filter-name>

Filter by virtual server name (can be a regexp).

=item B<--filter-type>

Filter which type of vserver (can be a regexp).

=item B<--force-counters64>

Force to use 64 bits counters only. Can be used to improve performance,
or to solve a missing counters bug.

=item B<--threshold-overload>

Set to overload default threshold values (syntax: status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='CRITICAL,^(?!(green)$)'

=back

=cut
