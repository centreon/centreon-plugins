#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package network::juniper::ggsn::mode::globalstats;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;
use centreon::plugins::statefile;

my $maps_counters = {
    '000_traffic-in'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'ggsnUplinkBytes', diff => 1 },
                                      ],
                        per_second => 1, output_change_bytes => 2,
                        output_template => 'Traffic In : %s %s/s',
                        perfdatas => [
                            { label => 'traffic_in', value => 'ggsnUplinkBytes_per_second', template => '%s',
                              unit => 'b/s', min => 0, cast_int => 1 },
                        ],
                    }
               },
    '001_traffic-out'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'ggsnDownlinkBytes', diff => 1 },
                                      ],
                        per_second => 1,  output_change_bytes => 2,
                        output_template => 'Traffic Out : %s %s/s',
                        perfdatas => [
                            { label => 'traffic_out', value => 'ggsnDownlinkBytes_per_second', template => '%s',
                              unit => 'b/s', min => 0, cast_int => 1 },
                        ],
                    }
               },
    '004_drop-in'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'ggsnUplinkDrops', diff => 1 }, { name => 'ggsnUplinkPackets', diff => 1 },
                                      ],
                        output_template => 'Drop In Packets : %.2f %%', threshold_use => 'drop_prct', output_use => 'drop_prct',
                        closure_custom_calc => \&custom_drop_in_calc,
                        perfdatas => [
                            { label => 'drop_in', value => 'ggsnUplinkDrops_absolute', template => '%s',
                              min => 0, max => 'ggsnUplinkPackets_absolute' },
                        ],
                    }
               },
    '005_drop-out'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'ggsnDownlinkDrops', diff => 1 }, { name => 'ggsnDownlinkPackets', diff => 1 },
                                      ],
                        output_template => 'Drop Out Packets : %.2f %%', threshold_use => 'drop_prct', output_use => 'drop_prct',
                        closure_custom_calc => \&custom_drop_out_calc,
                        perfdatas => [
                            { label => 'drop_out', value => 'ggsnDownlinkDrops_absolute', template => '%s',
                              min => 0, max => 'ggsnDownlinkPackets_absolute' },
                        ],
                    }
               },
    '006_active-pdp'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'ggsnNbrOfActivePdpContexts' },
                                      ],
                        output_template => 'Active Pdp : %s',
                        perfdatas => [
                            { label => 'active_pdp', value => 'ggsnNbrOfActivePdpContexts_absolute', template => '%s', min => 0 },
                        ],
                    }
               },
    '007_attempted-activation-pdp'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'ggsnAttemptedActivation', diff => 1 },
                                      ],
                        output_template => 'Attempted Activation Pdp : %s',
                        perfdatas => [
                            { label => 'attempted_activation_pdp', value => 'ggsnAttemptedActivation_absolute', template => '%s', min => 0 },
                        ],
                    }
               },
    '008_attempted-deactivation-pdp'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'ggsnAttemptedDeactivation', diff => 1 },
                                      ],
                        output_template => 'Attempted Deactivation Pdp : %s',
                        perfdatas => [
                            { label => 'attempted_deactivation_pdp', value => 'ggsnAttemptedDeactivation_absolute', template => '%s', min => 0 },
                        ],
                    }
               },
    '009_attempted-self-deactivation-pdp'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'ggsnAttemptedSelfDeactivation', diff => 1 },
                                      ],
                        output_template => 'Attempted Self Deactivation Pdp : %s',
                        perfdatas => [
                            { label => 'attempted_self_deactivation_pdp', value => 'ggsnAttemptedSelfDeactivation_absolute', template => '%s', min => 0 },
                        ],
                    }
               },
    '010_attempted-update-pdp'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'ggsnAttemptedUpdate', diff => 1 },
                                      ],
                        output_template => 'Attempted Update Pdp : %s',
                        perfdatas => [
                            { label => 'attempted_update_pdp', value => 'ggsnAttemptedUpdate_absolute', template => '%s', min => 0 },
                        ],
                    }
               },    
    '011_completed-activation-pdp'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'ggsnCompletedActivation', diff => 1 },
                                      ],
                        output_template => 'Completed Activation Pdp : %s',
                        perfdatas => [
                            { label => 'completed_activation_pdp', value => 'ggsnCompletedActivation_absolute', template => '%s', min => 0 },
                        ],
                    }
               },
    '012_completed-deactivation-pdp'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'ggsnCompletedDeactivation', diff => 1 },
                                      ],
                        output_template => 'Completed Deactivation Pdp : %s',
                        perfdatas => [
                            { label => 'completed_deactivation_pdp', value => 'ggsnCompletedDeactivation_absolute', template => '%s', min => 0 },
                        ],
                    }
               },
    '013_completed-self-deactivation-pdp'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'ggsnCompletedSelfDeactivation', diff => 1 },
                                      ],
                        output_template => 'Completed Self Deactivation Pdp : %s',
                        perfdatas => [
                            { label => 'completed_self_deactivation_pdp', value => 'ggsnCompletedSelfDeactivation_absolute', template => '%s', min => 0 },
                        ],
                    }
               },
    '014_completed-update-pdp'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'ggsnCompletedUpdate', diff => 1 },
                                      ],
                        output_template => 'Completed Update Pdp : %s',
                        perfdatas => [
                            { label => 'completed_update_pdp', value => 'ggsnCompletedUpdate_absolute', template => '%s', min => 0 },
                        ],
                    }
               },
};

sub custom_drop_in_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{ggsnUplinkDrops_absolute} = $options{new_datas}->{$self->{instance} . '_ggsnUplinkDrops'} - $options{old_datas}->{$self->{instance} . '_ggsnUplinkDrops'};
    $self->{result_values}->{ggsnUplinkPackets_absolute} = $options{new_datas}->{$self->{instance} . '_ggsnUplinkPackets'} - $options{old_datas}->{$self->{instance} . '_ggsnUplinkPackets'};
    if ($self->{result_values}->{ggsnUplinkPackets_absolute} == 0) {
        $self->{result_values}->{drop_prct} = 0;
    } else {
        $self->{result_values}->{drop_prct} = $self->{result_values}->{ggsnUplinkDrops_absolute} * 100 / $self->{result_values}->{ggsnUplinkPackets_absolute};
    }
    return 0;
}

sub custom_drop_out_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{ggsnDownlinkDrops_absolute} = $options{new_datas}->{$self->{instance} . '_ggsnDownlinkDrops'} - $options{old_datas}->{$self->{instance} . '_ggsnDownlinkDrops'};
    $self->{result_values}->{ggsnDownlinkPackets_absolute} = $options{new_datas}->{$self->{instance} . '_ggsnDownlinkPackets'} - $options{old_datas}->{$self->{instance} . '_ggsnDownlinkPackets'};
    if ($self->{result_values}->{ggsnDownlinkPackets_absolute} == 0) {
        $self->{result_values}->{drop_prct} = 0;
    } else {
        $self->{result_values}->{drop_prct} = $self->{result_values}->{ggsnDownlinkDrops_absolute} * 100 / $self->{result_values}->{ggsnDownlinkPackets_absolute};
    }
    return 0;
}


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                });                         
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);

    foreach (keys %{$maps_counters}) {
        my ($id, $name) = split /_/;
        if (!defined($maps_counters->{$_}->{threshold}) || $maps_counters->{$_}->{threshold} != 0) {
            $options{options}->add_options(arguments => {
                                                        'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                        'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                           });
        }
        my $class = $maps_counters->{$_}->{class};
        $maps_counters->{$_}->{obj} = $class->new(statefile => $self->{statefile_value},
                                                  output => $self->{output}, perfdata => $self->{perfdata},
                                                  label => $name);
        $maps_counters->{$_}->{obj}->set(%{$maps_counters->{$_}->{set}});
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach (keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->init(option_results => $self->{option_results});
    }
    
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();

    if ($self->{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }    
    
    $self->manage_selection();
    
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => "juniper_ggsn_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    $self->{new_datas}->{last_timestamp} = time();
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->set(instance => 'global');
    
        my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{global},
                                                                 new_datas => $self->{new_datas});

        if ($value_check != 0) {
            $long_msg .= $long_msg_append . $maps_counters->{$_}->{obj}->output_error();
            $long_msg_append = ', ';
            next;
        }
        my $exit2 = $maps_counters->{$_}->{obj}->threshold_check();
        push @exits, $exit2;

        my $output = $maps_counters->{$_}->{obj}->output();
        $long_msg .= $long_msg_append . $output;
        $long_msg_append = ', ';
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
            $short_msg .= $short_msg_append . $output;
            $short_msg_append = ', ';
        }
        
        $maps_counters->{$_}->{obj}->perfdata();
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "Global Stats $short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "Global Stats $long_msg");
    }
     
    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

my $mapping = {
    ggsnNbrOfActivePdpContexts      => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.2' },
    ggsnAttemptedActivation         => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.3.1' },
    ggsnAttemptedDeactivation       => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.3.2' },
    ggsnAttemptedSelfDeactivation   => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.3.3' },
    ggsnAttemptedUpdate             => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.3.4' },
    ggsnCompletedActivation         => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.4.1' },
    ggsnCompletedDeactivation       => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.4.2' },
    ggsnCompletedSelfDeactivation   => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.4.3' },
    ggsnCompletedUpdate             => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.4.4' },
    ggsnUplinkPackets               => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.11.1' },
    ggsnUplinkBytes                 => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.11.2' },
    ggsnUplinkDrops                 => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.11.3' },
    ggsnDownlinkPackets             => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.12.1' },
    ggsnDownlinkBytes               => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.12.2' },
    ggsnDownlinkDrops               => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.12.3' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_ggsnGlobalStats = '.1.3.6.1.4.1.10923.1.1.1.1.1.3';
    $self->{results} = $self->{snmp}->get_table(oid => $oid_ggsnGlobalStats,
                                                nothing_quit => 1);
    $self->{global} = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => '0');
    $self->{global}->{ggsnDownlinkBytes} *= 8 if (defined($self->{global}->{ggsnDownlinkBytes}));
    $self->{global}->{ggsnUplinkBytes} *= 8 if (defined($self->{global}->{ggsnUplinkBytes}));
}

1;

__END__

=head1 MODE

Check global statistics.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'traffic-in' (bps), 'traffic-out' (bps), 'drop-in' (%), 'drop-out' (%), 
'active-pdp', 'attempted-activation-pdp', 'attempted-update-pdp', 'attempted-deactivation-pdp',
'attempted-self-deactivation-pdp', 'completed-activation-pdp', 'completed-update-pdp',
'completed-deactivation-pdp', 'completed-self-deactivation-pdp'.

=item B<--critical-*>

Threshold critical.
Can be: 'traffic-in' (bps), 'traffic-out' (bps), 'drop-in' (%), 'drop-out' (%), 
'active-pdp', 'attempted-activation-pdp', 'attempted-update-pdp', 'attempted-deactivation-pdp',
'attempted-self-deactivation-pdp', 'completed-activation-pdp', 'completed-update-pdp',
'completed-deactivation-pdp', 'completed-self-deactivation-pdp'.

=back

=cut
