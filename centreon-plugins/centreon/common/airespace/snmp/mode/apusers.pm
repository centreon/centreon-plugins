#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package centreon::common::airespace::snmp::mode::apusers;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {               
    '000_total'   => { set => {
                        key_values => [ { name => 'total' } ],
                        output_template => 'Total Users : %s',
                        perfdatas => [
                            { label => 'total', value => 'total_absolute', template => '%s', 
                              unit => 'users', min => 0 },
                        ],
                    }
               },
    '001_total-idle'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [ { name => 'total_idle' } ],
                        output_template => 'Total Idle Users : %s',
                        perfdatas => [
                            { label => 'total_idle', value => 'total_idle_absolute', template => '%s', 
                              unit => 'users', min => 0 },
                        ],
                    }
               },
     '002_total-aaapending'  => { set => {
                        key_values => [ { name => 'total_aaapending' } ],
                        output_template => 'Total AaaPending Users : %s',
                        perfdatas => [
                            { label => 'total_aaapending', value => 'total_aaapending_absolute', template => '%s', 
                              unit => 'users', min => 0 },
                        ],
                    }
               },
    '003_total-authenticated'   => { set => {
                        key_values => [ { name => 'total_authenticated' } ],
                        output_template => 'Total Authenticated Users : %s',
                        perfdatas => [
                            { label => 'total_authenticated', value => 'total_authenticated_absolute', template => '%s', 
                              unit => 'users', min => 0 },
                        ],
                    }
               },
    '004_total-associated'   => { set => {
                        key_values => [ { name => 'total_associated' } ],
                        output_template => 'Total Associated Users : %s',
                        perfdatas => [
                            { label => 'total_associated', value => 'total_associated_absolute', template => '%s', 
                              unit => 'users', min => 0 },
                        ],
                    }
               },
    '005_total-powersave'   => { set => {
                        key_values => [ { name => 'total_powersave' } ],
                        output_template => 'Total Powersave Users : %s',
                        perfdatas => [
                            { label => 'total_powersave', value => 'total_powersave_absolute', template => '%s', 
                              unit => 'users', min => 0 },
                        ],
                    }
               },
    '006_total-disassociated'   => { set => {
                        key_values => [ { name => 'total_disassociated' } ],
                        output_template => 'Total Disassociated Users : %s',
                        perfdatas => [
                            { label => 'total_disassociated', value => 'total_disassociated_absolute', template => '%s', 
                              unit => 'users', min => 0 },
                        ],
                    }
               },
    '007_total-tobedeleted'   => { set => {
                        key_values => [ { name => 'total_tobedeleted' } ],
                        output_template => 'Total ToBeDeleted Users : %s',
                        perfdatas => [
                            { label => 'total_tobedeleted', value => 'total_tobedeleted_absolute', template => '%s', 
                              unit => 'users', min => 0 },
                        ],
                    }
               },
    '008_total-probing'   => { set => {
                        key_values => [ { name => 'total_probing' } ],
                        output_template => 'Total Probing Users : %s',
                        perfdatas => [
                            { label => 'total_probing', value => 'total_probing_absolute', template => '%s', 
                              unit => 'users', min => 0 },
                        ],
                    }
               },
    '009_total-blacklisted'   => { set => {
                        key_values => [ { name => 'total_blacklisted' } ],
                        output_template => 'Total Blacklisted Users : %s',
                        perfdatas => [
                            { label => 'total_blacklisted', value => 'total_blacklisted_absolute', template => '%s', 
                              unit => 'users', min => 0 },
                        ],
                    }
               },
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-ssid:s"     => { name => 'filter_ssid' },
                                });

    foreach (keys %{$maps_counters}) {
        my ($id, $name) = split /_/;
        if (!defined($maps_counters->{$_}->{threshold}) || $maps_counters->{$_}->{threshold} != 0) {
            $options{options}->add_options(arguments => {
                                                        'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                        'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                           });
        }
        $maps_counters->{$_}->{obj} = centreon::plugins::values->new(output => $self->{output}, perfdata => $self->{perfdata},
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
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    $self->manage_selection();
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->set(instance => 'global');
    
        my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{global});

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
                                    short_msg => "$short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "$long_msg");
    }
     
    $self->{output}->display();
    $self->{output}->exit();
}

my %map_station_status = (
    0 => 'idle',
    1 => 'aaapending',
    2 => 'authenticated',
    3 => 'associated',
    4 => 'powersave',
    5 => 'disassociated',
    6 => 'tobedeleted',
    7 => 'probing',
    8 => 'blacklisted',
);
my $mapping = {
    bsnMobileStationStatus  => { oid => '.1.3.6.1.4.1.14179.2.1.4.1.9', map => \%map_station_status },
};
my $mapping2 = {
    bsnMobileStationSsid    => { oid => '.1.3.6.1.4.1.14179.2.1.4.1.7' },
};

my $oid_agentInventoryMachineModel = '.1.3.6.1.4.1.14179.1.1.1.3';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { total => 0, total_idle => 0, total_aaapending => 0, total_authenticated => 0,
                        total_associated => 0, total_powersave => 0, total_disassociated => 0,
                        total_tobedeleted => 0, total_probing => 0, total_blacklisted => 0};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [ { oid => $oid_agentInventoryMachineModel },
                                                                   { oid => $mapping->{bsnMobileStationStatus}->{oid} },
                                                                   { oid => $mapping2->{bsnMobileStationSsid}->{oid} },
                                                                 ],
                                                         nothing_quit => 1);
    $self->{output}->output_add(long_msg => "Model: " . $self->{results}->{$oid_agentInventoryMachineModel}->{$oid_agentInventoryMachineModel . '.0'});
    foreach my $oid (keys %{$self->{results}->{ $mapping->{bsnMobileStationStatus}->{oid} }}) {
        $oid =~ /^$mapping->{bsnMobileStationStatus}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $mapping->{bsnMobileStationStatus}->{oid} }, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{ $mapping2->{bsnMobileStationSsid}->{oid} }, instance => $instance);
        if (defined($self->{option_results}->{filter_ssid}) && $self->{option_results}->{filter_ssid} ne '' &&
            $result2->{bsnMobileStationSsid} !~ /$self->{option_results}->{filter_ssid}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result2->{bsnMobileStationSsid} . "': no matching filter.");
            next;
        }
        $self->{global}->{total}++;
        $self->{global}->{'total_' . $result->{bsnMobileStationStatus}}++;
    }
}

1;

__END__

=head1 MODE

Check total users connected and status on AP.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'total-idle', 'total-aaapending', 'total-authenticated',
'total-associated', 'total-powersave', 'total-disassociated', 'total-tobedeleted',
'total-probing', 'total-blacklisted'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'total-idle', 'total-aaapending', 'total-authenticated',
'total-associated', 'total-powersave', 'total-disassociated', 'total-tobedeleted',
'total-probing', 'total-blacklisted'.

=item B<--filter-ssid>

Filter by SSID (can be a regexp).

=back

=cut
