#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package network::atto::fibrebridge::snmp::mode::fcportusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output { 
    my ($self, %options) = @_;

    my $msg = 'status : ' . $self->{result_values}->{status} . ' [admin: ' . $self->{result_values}->{admin} . ']';
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_fcPortOperationalState'};
    $self->{result_values}->{admin} = $options{new_datas}->{$self->{instance} . '_fcPortAdminState'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'fc', type => 1, cb_prefix_output => 'prefix_fc_output', message_multiple => 'All fc ports are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{fc} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'fcPortOperationalState' }, { name => 'fcPortAdminState' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'traffic-in', nlabel => 'fc.port.traffic.in.wordspersecond', set => {
                key_values => [ { name => 'fcStatsRxWords', diff => 1 }, { name => 'display' } ],
                per_second => 1,
                output_template => 'traffic in : %.2f words/s',
                perfdatas => [
                    { label => 'traffic_in',  template => '%.2f', value => 'fcStatsRxWords_per_second',
                      unit => 'words/s', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'traffic-out', nlabel => 'fc.port.traffic.out.wordspersecond', set => {
                key_values => [ { name => 'fcStatsTxWords', diff => 1 }, { name => 'display' } ],
                per_second => 1,
                output_template => 'traffic out : %.2f words/s',
                perfdatas => [
                    { label => 'traffic_out',  template => '%.2f', value => 'fcStatsTxWords_per_second',
                      unit => 'words/s', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'invalid-crc', nlabel => 'fc.port.invalid.crc.count', set => {
                key_values => [ { name => 'fcStatsErrInvalidCRC', diff => 1 }, { name => 'display' } ],
                output_template => 'number of invalid CRC : %s',
                perfdatas => [
                    { label => 'invalid_crc', value => 'fcStatsErrInvalidCRC_absolute', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'signal-loss', nlabel => 'fc.port.signal.loss.count', set => {
                key_values => [ { name => 'fcStatsErrSignalLoss', diff => 1 }, { name => 'display' } ],
                output_template => 'number of signal loss : %s',
                perfdatas => [
                    { label => 'signal_loss', value => 'fcStatsErrSignalLoss_absolute', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub prefix_fc_output {
    my ($self, %options) = @_;

    return "fc port '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "filter-name:s"     => { name => 'filter_name' },
        "warning-status:s"  => { name => 'warning_status', default => '' },
        "critical-status:s" => { name => 'critical_status', default => '%{admin} =~ /enabled/ and %{status} !~ /online/' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my $map_oper_state = { -1 => 'unknown', 1 => 'online', 2 => 'offline' };
my $map_admin_state = { -1 => 'unknown', 1 => 'disabled', 2 => 'enabled' };

my $mapping = {
    fcPortOperationalState  => { oid => '.1.3.6.1.4.1.4547.2.3.3.1.1.3', map => $map_oper_state },
    fcPortAdminState        => { oid => '.1.3.6.1.4.1.4547.2.3.3.1.1.4', map => $map_admin_state },
    
    fcStatsTxWords          => { oid => '.1.3.6.1.4.1.4547.2.3.3.2.1.2' },
    fcStatsRxWords          => { oid => '.1.3.6.1.4.1.4547.2.3.3.2.1.3' },
    fcStatsErrInvalidCRC    => { oid => '.1.3.6.1.4.1.4547.2.3.3.2.1.7' },
    fcStatsErrSignalLoss    => { oid => '.1.3.6.1.4.1.4547.2.3.3.2.1.11' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_fcSFPSerialNum = '.1.3.6.1.4.1.4547.2.3.2.12.1.3';
    
    $self->{fc} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_fcSFPSerialNum, nothing_quit => 1);
    foreach my $oid (keys %{$snmp_result}) {
        $oid =~ /^$oid_fcSFPSerialNum\.(.*)$/;
        my $instance = $1;
        my $name = centreon::plugins::misc::trim($snmp_result->{$oid_fcSFPSerialNum . '.' . $instance});

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping fc port '" . $name . "'.", debug => 1);
            next;
        }

        $self->{fc}->{$instance} = { display => $name };
    }

    if (scalar(keys %{$self->{fc}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
    
    $options{snmp}->load(oids => [
            map($_->{oid}, values(%$mapping)) 
        ],
        instances => [keys %{$self->{fc}}], instance_regexp => '^(.*)$');
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach (keys %{$self->{fc}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);
        $self->{fc}->{$_} = { %{$self->{fc}->{$_}}, %$result };
    }
    
    $self->{cache_name} = "atto_fiberbridge_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check fc port usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'traffic-in', 'traffic-out', 'invalid-crc', 'signal-loss'.

=item B<--filter-name>

Filter name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{admin}, %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{admin} =~ /enabled/ and %{status} !~ /online/').
Can used special variables like: %{admin}, %{status}, %{display}

=back

=cut
