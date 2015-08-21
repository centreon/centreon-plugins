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

package network::alcatel::isam::snmp::mode::vlantraffic;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my $maps_counters = {
    vlan => { 
        '000_cac-usage'   => {
            set => {
                key_values => [ { name => 'display' }, { name => 'cacUsed' }, { name => 'cacAllowed' } ],
                closure_custom_calc => \&custom_cac_usage_calc,
                closure_custom_calc_extra_options => { label_output => 'External Communication', label_perf => 'cac' },
                closure_custom_output => \&custom_usage_output,
                closure_custom_perfdata => \&custom_usage_perfdata,
                closure_custom_threshold_check => \&custom_usage_threshold,
            },
        },
        '001_conference-usage'   => {
            set => {
                key_values => [ { name => 'display' }, { name => 'confBusy' }, { name => 'confAvailable' } ],
                closure_custom_calc => \&custom_conference_usage_calc,
                closure_custom_calc_extra_options => { label_output => 'Conference circuits', label_perf => 'conference' },
                closure_custom_output => \&custom_usage_output,
                closure_custom_perfdata => \&custom_usage_perfdata,
                closure_custom_threshold_check => \&custom_usage_threshold,
            },
        },
    }
};

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    my $extra_label = '';
    if (!defined($options{extra_instance}) || $options{extra_instance} != 0) {
        $extra_label .= '_' . $self->{result_values}->{display};
    }
    $self->{output}->perfdata_add(label => $self->{result_values}->{label_perf} . '_used' . $extra_label,
                                  value => $self->{result_values}->{used},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  min => 0, max => $self->{result_values}->{total});
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct_used}, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my $msg = sprintf("%s Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                      $self->{result_values}->{label_output},
                      $self->{result_values}->{total},
                      $self->{result_values}->{used}, $self->{result_values}->{prct_used},
                      $self->{result_values}->{free}, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_cac_usage_calc {
    my ($self, %options) = @_;

    if ($options{new_datas}->{$self->{instance} . '_cacAllowed'} <= 0) {
        $self->{error_msg} = "skipped (no allowed)";
        return -2;
    }
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_cacAllowed'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_cacUsed'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{label_perf} = $options{extra_options}->{label_perf};
    $self->{result_values}->{label_output} = $options{extra_options}->{label_output};
    return 0;
}

sub custom_conference_usage_calc {
    my ($self, %options) = @_;

    if ($options{new_datas}->{$self->{instance} . '_confAvailable'} <= 0) {
        $self->{error_msg} = "skipped (no available)";
        return -2;
    }
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_confAvailable'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_confBusy'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{label_perf} = $options{extra_options}->{label_perf};
    $self->{result_values}->{label_output} = $options{extra_options}->{label_output};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "no-component:s"          => { name => 'no_component' },
                                  "filter-interface:s"      => { name => 'filter_interface' },
                                  "filter-vlan:s"           => { name => 'filter_vlan' },
                                  "show-cache"              => { name => 'show_cache' },
                                  "reload-cache-time:s"     => { name => 'reload_cache_time', default => 180 },
                                });
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    
    foreach my $key (('vlan')) {
        foreach (keys %{$maps_counters->{$key}}) {
            my ($id, $name) = split /_/;
            if (!defined($maps_counters->{$key}->{$_}->{threshold}) || $maps_counters->{$key}->{$_}->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                            'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                            'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                               });
            }
            $maps_counters->{$key}->{$_}->{obj} = centreon::plugins::values->new(statefile => $self->{statefile_value},
                                                      output => $self->{output}, perfdata => $self->{perfdata},
                                                      label => $name);
            $maps_counters->{$key}->{$_}->{obj}->set(%{$maps_counters->{$key}->{$_}->{set}});
        }
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach my $key (('vlan')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }

    if (defined($self->{option_results}->{no_component})) {
        if ($self->{option_results}->{no_component} ne '') {
            $self->{no_components} = $self->{option_results}->{no_component};
        } else {
            $self->{no_components} = 'critical';
        }
    }
    
    $self->{statefile_cache}->check_options(%options);
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();

    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{vlan}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All VLAN usages are ok');
    }
    
    foreach my $id (sort keys %{$self->{vlan}}) {
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (sort keys %{$maps_counters->{vlan}}) {
            my $obj = $maps_counters->{vlan}->{$_}->{obj};
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(values => $self->{vlan}->{$id});

            if ($value_check != 0) {
                $long_msg .= $long_msg_append . $obj->output_error();
                $long_msg_append = ', ';
                next;
            }
            my $exit2 = $obj->threshold_check();
            push @exits, $exit2;

            my $output = $obj->output();
            $long_msg .= $long_msg_append . $output;
            $long_msg_append = ', ';
            
            if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                $short_msg .= $short_msg_append . $output;
                $short_msg_append = ', ';
            }
            
            $obj->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "VLAN '$self->{vlan}->{$id}->{display}' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "VLAN '$self->{vlan}->{$id}->{display}' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "VLAN '$self->{vlan}->{$id}->{display}' $long_msg");
        }
    }
     
    $self->{output}->display();
    $self->{output}->exit();
}

my $oid_extendVlanStaticName = '.1.3.6.1.4.1.5003.9.10.8.2';
my $oid_extendPortVlanVlanIndex = '.1.3.6.1.4.1.637.61.1.31.2.12.1.1';
my $oid_dot1dBasePortIfIndex = '.1.3.6.1.2.1.17.1.4.1.2';
my $oid_ifDescr = '.1.3.6.1.2.1.2.2.1.2';
my $oid_extendPortVlanCurrent1DayUpFwdByteCounter = '.1.3.6.1.4.1.637.61.1.31.9.3.1.5';
my $oid_extendPortVlanCurrent1DayDnFwdByteCounter = '.1.3.6.1.4.1.637.61.1.31.9.3.1.7';

sub reload_cache {
    my ($self) = @_;
    my $datas = {};
    
    my $result = $self->{snmp}->get_multiple_table(oids => [ 
            { oid => $oid_extendVlanStaticName },
            { oid => $oid_extendPortVlanVlanIndex },
            { oid => $oid_dot1dBasePortIfIndex },
            { oid => $oid_ifDescr },
        ], nothing_quit => 1);
    $result->{last_timestamp} = time();
    
    if (scalar(keys %{$result->{$oid_extendVlanStaticName}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't construct cache...");
        $self->{output}->option_exit();
    }
    
    $self->{statefile_cache}->write(data => $result);
}

sub manage_selection {
    my ($self, %options) = @_;
 
    # init cache file
    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_snmpstandard_' . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    if (defined($self->{option_results}->{show_cache})) {
        $self->{output}->add_option_msg(long_msg => $self->{statefile_cache}->get_string_content());
        $self->{output}->option_exit();
    }

    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');    
    if ($has_cache_file == 0 || 
        !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60))) {
        $self->reload_cache();
        $self->{statefile_cache}->read();
    }
    
    $self->{vlan} = {};
    my $value = $self->{statefile_cache}->get(name => $oid_extendVlanStaticName);
    my $port_vlan_result = $self->{statefile_cache}->get(name => $oid_extendPortVlanVlanIndex);
    my $dot1base_result = $self->{statefile_cache}->get(name => $oid_dot1dBasePortIfIndex);
    my $ifdescr_result = $self->{statefile_cache}->get(name => $oid_ifDescr);
    foreach ($self->{snmp}->oid_lex_sort(keys %{$value})) {
        /^$oid_extendVlanStaticName\.(.*)$/;
        my $vlan_index = $1;
        my $vlan_name = $value->{$_};
        if (defined($self->{option_results}->{filter_vlan}) && $self->{option_results}->{filter_vlan} ne '' &&
            $vlan_name !~ /$self->{option_results}->{filter_vlan}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $vlan_name . "': no matching filter.", debug => 1);
            next;
        }
        # we look for the interface description
        #extendPortVlanVlanIndex.(dot1dBasePort).(VlanIndex)        
        foreach ($self->{snmp}->oid_lex_sort(keys %{$port_vlan_result})) {
            next if ($_ !~ /^$oid_extendPortVlanVlanIndex\.(\d+)\.$vlan_index$/);
            my $dot1dBasePort = $1;
            next if (!defined($dot1base_result->{$oid_dot1dBasePortIfIndex . '.' . $dot1dBasePort}));
            my $ifIndex = $dot1base_result->{$oid_dot1dBasePortIfIndex . '.' . $dot1dBasePort};
            next if (!defined($ifdescr_result->{$oid_ifDescr . '.' . $ifIndex}));
            
            my $ifDescr = $ifdescr_result->{$oid_ifDescr . '.' . $ifIndex};
            if (defined($self->{option_results}->{filter_interface}) && $self->{option_results}->{filter_interface} ne '' &&
                $ifDescr !~ /$self->{option_results}->{filter_interface}/) {
                $self->{output}->output_add(long_msg => "Skipping  '" . $ifDescr . "': no matching filter.", debug => 1);
                next;
            }
            
            $self->{snmp}->load(oids => [$oid_extendPortVlanCurrent1DayUpFwdByteCounter, $oid_extendPortVlanCurrent1DayDnFwdByteCounter],
                                instances => $dot1dBasePort . '.' . $vlan_index);
        }
        
        $self->{vlan}->{$vlan_index} = { display => $vlan_name, in => 0, out => 0 };
    }
    
    $self->{results} = $self->{snmp}->get_leef();
 
    foreach (keys %{$self->{results}}) {
        next if ($_ !~ /^$oid_extendPortVlanCurrent1DayUpFwdByteCounter\.(\d+)\.(\+d)$/);
        my $vlan_index = $2;
        
        my $in = unpack('b*', $self->{results}->{$oid_extendPortVlanCurrent1DayDnFwdByteCounter . '.' . $1 . '.' . $vlan_index});
        my $out = unpack('b*', $self->{results}->{$_});

        $self->{vlan}->{$vlan_index}->{in} += $in;
        $self->{vlan}->{$vlan_index}->{in} += $out;
    }
    
    use Data::Dumper;
    print Data::Dumper::Dumper($self->{vlan});
    exit(1);
    
    if (scalar(keys %{$self->{vlan}}) <= 0) {
        $self->{output}->output_add(severity => defined($self->{no_components}) ? $self->{no_components} : 'unknown',
                                    short_msg => 'No components are checked.');
    }
}

1;

__END__

=head1 MODE

Check traffic by VLAN.

=over 8

=item B<--filter-vlan>

Filter by vlan name (regexp can be used).

=item B<--filter-interface>

Filter by interface description (regexp can be used).

=item B<--warning-*>

Threshold warning.
Can be: 'cac-usage' (%), 'conference-usage' (%).

=item B<--critical-*>

Threshold critical.
Can be: 'cac-usage' (%), 'conference-usage' (%).

=item B<--no-component>

Set the threshold where no components (Default: 'unknown' returns).

=item B<--reload-cache-time>

Time in minutes before reloading cache file (default: 180).

=item B<--show-cache>

Display cache datas.

=back

=cut
