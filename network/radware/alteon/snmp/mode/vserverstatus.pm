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

package network::radware::alteon::snmp::mode::vserverstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'state : ' . $self->{result_values}->{state};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vservers', type => 1, cb_prefix_output => 'prefix_vservers_output', message_multiple => 'All Virtual Servers are ok' }
    ];
    
    $self->{maps_counters}->{vservers} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'traffic', set => {
                key_values => [ { name => 'traffic', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic', template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'current-sessions', set => {
                key_values => [ { name => 'current_sessions' }, { name => 'display' } ],
                output_template => 'Current Sessions : %s',
                perfdatas => [
                    { label => 'current_sessions', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'total-sessions', set => {
                key_values => [ { name => 'total_sessions', diff => 1 }, { name => 'display' } ],
                output_template => 'Total Sessions : %s',
                perfdatas => [
                    { label => 'total_sessions', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub prefix_vservers_output {
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
        'critical-status:s' => { name => 'critical_status', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_state = (
    2 => 'enabled', 
    3 => 'disabled', 
);

my $mapping = {
    slbCurCfgVirtServerState    => { oid => '.1.3.6.1.4.1.1872.2.5.4.1.1.4.2.1.4', map => \%map_state },
    slbCurCfgVirtServerVname    => { oid => '.1.3.6.1.4.1.1872.2.5.4.1.1.4.2.1.10' },
    slbCurCfgVirtServerAvail    => { oid => '.1.3.6.1.4.1.1872.2.5.4.1.1.4.2.1.8' }, # can't get mapping for that. If someones has it, i'm interested :)   
};
my $mapping2 = {
    slbStatVServerCurrSessions    => { oid => '.1.3.6.1.4.1.1872.2.5.4.2.4.1.2' },
    slbStatVServerTotalSessions   => { oid => '.1.3.6.1.4.1.1872.2.5.4.2.4.1.3' },
    slbStatVServerHCOctetsLow32   => { oid => '.1.3.6.1.4.1.1872.2.5.4.2.4.1.5' },
    slbStatVServerHCOctetsHigh32  => { oid => '.1.3.6.1.4.1.1872.2.5.4.2.4.1.6' },
    slbStatVServerHCOctets        => { oid => '.1.3.6.1.4.1.1872.2.5.4.2.4.1.13' },
};

sub manage_selection {
    my ($self, %options) = @_;
 
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
                                                            { oid => $mapping->{slbCurCfgVirtServerState}->{oid} },
                                                            { oid => $mapping->{slbCurCfgVirtServerVname}->{oid} },
                                                         ], return_type => 1, nothing_quit => 1);
    $self->{vservers} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{slbCurCfgVirtServerVname}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        if (!defined($result->{slbCurCfgVirtServerVname}) || $result->{slbCurCfgVirtServerVname} eq '') {
            $self->{output}->output_add(long_msg => "skipping Virtual Server '$instance': cannot get a name. please set it.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{slbCurCfgVirtServerVname} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping Virtual Server '" . $result->{slbCurCfgVirtServerVname} . "'.", debug => 1);
            next;
        }
        
        $self->{vservers}->{$instance} = { display => $result->{slbCurCfgVirtServerVname}, state => $result->{slbCurCfgVirtServerState} };
    }
    
    $options{snmp}->load(oids => [$mapping2->{slbStatVServerCurrSessions}->{oid}, $mapping2->{slbStatVServerTotalSessions}->{oid},
        $mapping2->{slbStatVServerHCOctetsLow32}->{oid}, $mapping2->{slbStatVServerHCOctetsHigh32}->{oid},
        $mapping2->{slbStatVServerHCOctets}->{oid}
        ], 
        instances => [keys %{$self->{vservers}}], instance_regexp => '^(.*)$');
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach (keys %{$self->{vservers}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => $_);        
        
        $self->{vservers}->{$_}->{traffic} = (defined($result->{slbStatVServerHCOctets}) ? $result->{slbStatVServerHCOctets} * 8 :
            (($result->{slbStatVServerHCOctetsHigh32} << 32) + $result->{slbStatVServerHCOctetsLow32})) * 8;
        $self->{vservers}->{$_}->{current_sessions} = $result->{slbStatVServerCurrSessions};
        $self->{vservers}->{$_}->{total_sessions} = $result->{slbStatVServerTotalSessions};
    }
    
    if (scalar(keys %{$self->{vservers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No virtual server found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "alteon_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check vservers status.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'traffic', 'total-sessions', 'current-sessions'.

=item B<--critical-*>

Threshold critical.
Can be: 'traffic', 'total-sessions', 'current-sessions'.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{state}, %{display}

=item B<--critical-status>

Set critical threshold for status.
Can used special variables like: %{state}, %{display}

=item B<--filter-name>

Filter by virtual server name (can be a regexp).

=back

=cut
