################################################################################
# Copyright 2005-2014 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package snmp_standard::mode::anycast;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::values;

my $maps_counters = {
    'status' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'opstatus' }, { name => 'admstatus' },
                                      ],
                        closure_custom_calc => \&custom_status_calc,
                        closure_custom_output => \&custom_status_output,
                        closure_custom_perfdata => sub { return 0; },
                        closure_custom_threshold_check => \&custom_threshold_output,
                    }
               },
    'in-ucast' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'iucast', diff => 1 }, { name => 'imcast', diff => 1 }, { name => 'ibcast', diff => 1 }, { name => 'display' }, { name => 'mode' }, { name => 'opstatus' }, { name => 'admstatus' }
                                      ],
                        closure_custom_calc => \&custom_cast_calc, closure_custom_calc_extra_options => { label_ref => 'iucast', total_ref1 => 'ibcast', total_ref2 => 'imcast' },
                        output_template => 'In Ucast : %.2f %%', output_error_template => 'In Ucast : %s',
                        output_use => 'iucast_prct',  threshold_use => 'iucast_prct',
                        perfdatas => [
                            { value => 'iucast_prct', template => '%.2f',
                              unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                        ],
                    }
               },
    'in-bcast' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'iucast', diff => 1 }, { name => 'imcast', diff => 1 }, { name => 'ibcast', diff => 1 }, { name => 'display' }, { name => 'mode' }, { name => 'opstatus' }, { name => 'admstatus' }
                                      ],
                        closure_custom_calc => \&custom_cast_calc, closure_custom_calc_extra_options => { label_ref => 'ibcast', total_ref1 => 'iucast', total_ref2 => 'imcast' },
                        output_template => 'In Bcast : %.2f %%', output_error_template => 'In Bcast : %s',
                        output_use => 'ibcast_prct',  threshold_use => 'ibcast_prct',
                        perfdatas => [
                            { value => 'ibcast_prct', template => '%.2f',
                              unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                        ],
                    }
               },
    'in-mcast' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'iucast', diff => 1 }, { name => 'imcast', diff => 1 }, { name => 'ibcast', diff => 1 }, { name => 'display' }, { name => 'mode' }, { name => 'opstatus' }, { name => 'admstatus' }
                                      ],
                        closure_custom_calc => \&custom_cast_calc, closure_custom_calc_extra_options => { label_ref => 'imcast', total_ref1 => 'iucast', total_ref2 => 'ibcast' },
                        output_template => 'In Mcast : %.2f %%', output_error_template => 'In Mcast : %s',
                        output_use => 'imcast_prct',  threshold_use => 'imcast_prct',
                        perfdatas => [
                            { value => 'imcast_prct', template => '%.2f',
                              unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                        ],
                    }
               },
    'out-ucast' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'oucast', diff => 1 }, { name => 'omcast', diff => 1 }, { name => 'obcast', diff => 1 }, { name => 'display' }, { name => 'mode' }, { name => 'opstatus' }, { name => 'admstatus' }
                                      ],
                        closure_custom_calc => \&custom_cast_calc, closure_custom_calc_extra_options => { label_ref => 'oucast', total_ref1 => 'omcast', total_ref2 => 'obcast' },
                        output_template => 'Out Ucast : %.2f %%', output_error_template => 'Out Ucast : %s',
                        output_use => 'oucast_prct',  threshold_use => 'oucast_prct',
                        perfdatas => [
                            { value => 'oucast_prct', template => '%.2f',
                              unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                        ],
                    }
               },
    'out-bcast' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'oucast', diff => 1 }, { name => 'omcast', diff => 1 }, { name => 'obcast', diff => 1 }, { name => 'display' }, { name => 'mode' }, { name => 'opstatus' }, { name => 'admstatus' }
                                      ],
                        closure_custom_calc => \&custom_cast_calc, closure_custom_calc_extra_options => { label_ref => 'obcast', total_ref1 => 'omcast', total_ref2 => 'oucast' },
                        output_template => 'Out Bcast : %.2f %%', output_error_template => 'Out Bcast : %s',
                        output_use => 'obcast_prct',  threshold_use => 'obcast_prct',
                        perfdatas => [
                            { value => 'obcast_prct', template => '%.2f',
                              unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                        ],
                    }
               },
    'out-mcast' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'oucast', diff => 1 }, { name => 'omcast', diff => 1 }, { name => 'obcast', diff => 1 }, { name => 'display' }, { name => 'mode' }, { name => 'opstatus' }, { name => 'admstatus' }
                                      ],
                        closure_custom_calc => \&custom_cast_calc, closure_custom_calc_extra_options => { label_ref => 'omcast', total_ref1 => 'oucast', total_ref2 => 'obcast' },
                        output_template => 'Out Mcast : %.2f %%', output_error_template => 'Out Mcast : %s',
                        output_use => 'omcast_prct',  threshold_use => 'omcast_prct',
                        perfdatas => [
                            { value => 'omcast_prct', template => '%.2f',
                              unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                        ],
                    }
               },
};

my $skip_option;
my @operstatus = ("up", "down", "testing", "unknown", "dormant", "notPresent", "lowerLayerDown");

sub custom_threshold_output {
    my ($self, %options) = @_;
    my $status = 'ok';
    
    if ($operstatus[$self->{result_values}->{opstatus} - 1] ne "up") {
        if (defined($skip_option)) {
            return $status;
        }
        if (!defined($self->{result_values}->{admstatus}) || $operstatus[$self->{result_values}->{admstatus}  - 1] eq 'up') {
            $status = 'critical';
        }
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = 'Status : ';
    
    if ($operstatus[$self->{result_values}->{opstatus} - 1] ne "up") {
        if (defined($skip_option)) {
            $msg .= 'skipped';
            return $msg;
        }
        if (!defined($self->{result_values}->{admstatus}) || $operstatus[$self->{result_values}->{admstatus}  - 1] eq 'up') {
            $msg .= 'not ready (' . $operstatus[$self->{result_values}->{admstatus} - 1] . ')';
        } else {
            $msg .= 'not ready (normal state)';
        }
    } else {
        $msg .= 'up';
    }

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{opstatus} = $options{new_datas}->{$self->{instance} . '_opstatus'};
    $self->{result_values}->{admstatus} = $options{new_datas}->{$self->{instance} . '_admstatus'};
    return 0;
}

sub custom_cast_calc {
    my ($self, %options) = @_;
    
    if ($operstatus[$options{new_datas}->{$self->{instance} . '_opstatus'} - 1] ne "up") {
        $self->{error_msg} = "skipped";
        return -2;
    }
    
    my $diff_cast = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}});
    my $total = $diff_cast
                + ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{total_ref1}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{total_ref1}}) 
                + ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{total_ref2}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{total_ref2}});
    if ($options{new_datas}->{$self->{instance} . '_mode'} ne $options{old_datas}->{$self->{instance} . '_mode'}) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }
    if ($total == 0) {
        $self->{error_msg} = "skipped";
        return -2;
    }
    
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{$options{extra_options}->{label_ref} . '_prct'} = $diff_cast * 100 / $total;
    return 0;
}

my %oids_iftable = (
    'ifdesc' => '.1.3.6.1.2.1.2.2.1.2',
    'ifalias' => '.1.3.6.1.2.1.31.1.1.1.18',
    'ifname' => '.1.3.6.1.2.1.31.1.1.1.1'
);

my $oid_ifAdminStatus = '.1.3.6.1.2.1.2.2.1.7';
my $oid_ifOperStatus = '.1.3.6.1.2.1.2.2.1.8';

my $oid_ifXEntry = '.1.3.6.1.2.1.31.1.1.1';

# 32bits
my $oid_ifInUcastPkts = '.1.3.6.1.2.1.2.2.1.11';
my $oid_ifInBroadcastPkts = '.1.3.6.1.2.1.31.1.1.1.3';
my $oid_ifInMulticastPkts = '.1.3.6.1.2.1.31.1.1.1.2';
my $oid_ifOutUcastPkts = '.1.3.6.1.2.1.2.2.1.17';
my $oid_ifOutMulticastPkts = '.1.3.6.1.2.1.31.1.1.1.4';
my $oid_ifOutBroadcastPkts = '.1.3.6.1.2.1.31.1.1.1.5';
    
# 64 bits
my $oid_ifHCInUcastPkts = '.1.3.6.1.2.1.31.1.1.1.7';
my $oid_ifHCInMulticastPkts = '.1.3.6.1.2.1.31.1.1.1.8';
my $oid_ifHCInBroadcastPkts = '.1.3.6.1.2.1.31.1.1.1.9';
my $oid_ifHCOutUcastPkts = '.1.3.6.1.2.1.31.1.1.1.11';
my $oid_ifHCOutMulticastPkts = '.1.3.6.1.2.1.31.1.1.1.12';
my $oid_ifHCOutBroadcastPkts = '.1.3.6.1.2.1.31.1.1.1.13';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "name"                    => { name => 'use_name' },
                                  "interface:s"             => { name => 'interface' },
                                  "skip"                    => { name => 'skip' },
                                  "regexp"                  => { name => 'use_regexp' },
                                  "regexp-isensitive"       => { name => 'use_regexpi' },
                                  "oid-filter:s"            => { name => 'oid_filter', default => 'ifname'},
                                  "oid-display:s"           => { name => 'oid_display', default => 'ifname'},
                                  "display-transform-src:s" => { name => 'display_transform_src' },
                                  "display-transform-dst:s" => { name => 'display_transform_dst' },
                                });

    $self->{interface_selected} = {};
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);                           
     
    foreach (keys %{$maps_counters}) {
        $options{options}->add_options(arguments => {
                                                     'warning-' . $_ . ':s'    => { name => 'warning-' . $_ },
                                                     'critical-' . $_ . ':s'    => { name => 'critical-' . $_ },
                                      });
        my $class = $maps_counters->{$_}->{class};
        $maps_counters->{$_}->{obj} = $class->new(statefile => $self->{statefile_value},
                                                  output => $self->{output}, perfdata => $self->{perfdata},
                                                  label => $_);
        $maps_counters->{$_}->{obj}->set(%{$maps_counters->{$_}->{set}});
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    $self->{option_results}->{oid_filter} = lc($self->{option_results}->{oid_filter});
    if ($self->{option_results}->{oid_filter} !~ /^(ifdesc|ifalias|ifname)$/) {
        $self->{output}->add_option_msg(short_msg => "Unsupported --oid-filter option.");
        $self->{output}->option_exit();
    }
    $self->{option_results}->{oid_display} = lc($self->{option_results}->{oid_display});
    if ($self->{option_results}->{oid_display} !~ /^(ifdesc|ifalias|ifname)$/) {
        $self->{output}->add_option_msg(short_msg => "Unsupported --oid-display option.");
        $self->{output}->option_exit();
    }
    
    foreach (keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->init(option_results => $self->{option_results});
    }
    
    $skip_option = $self->{option_results}->{skip};
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();

    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{interface_selected}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All interfaces are ok.');
    }
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => "snmpstandard_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode} . '_' . (defined($self->{option_results}->{interface}) ? md5_hex($self->{option_results}->{interface}) : md5_hex('all')));
    $self->{new_datas}->{last_timestamp} = time();
    
    foreach my $id (sort keys %{$self->{interface_selected}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits;
        foreach (sort keys %{$maps_counters}) {
            $maps_counters->{$_}->{obj}->set(instance => $id);
        
            my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{interface_selected}->{$id},
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
            
            $maps_counters->{$_}->{obj}->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "Interface '" . $self->{interface_selected}->{$id}->{display} . "' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Interface '" . $self->{interface_selected}->{$id}->{display} . "' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "Interface '" . $self->{interface_selected}->{$id}->{display} . "' $long_msg");
        }
    }
    
    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

sub get_display_value {
    my ($self, %options) = @_;
    my $value = $options{value};

    if (defined($self->{option_results}->{display_transform_src})) {
        $self->{option_results}->{display_transform_dst} = '' if (!defined($self->{option_results}->{display_transform_dst}));
        eval "\$value =~ s{$self->{option_results}->{display_transform_src}}{$self->{option_results}->{display_transform_dst}}";
    }
    return $value;
}

sub add_result {
    my ($self, %options) = @_;
    
    $self->{interface_selected}->{$options{instance}} = {};
    $self->{interface_selected}->{$options{instance}}->{display} = $self->get_display_value(value => $self->{results}->{$oids_iftable{$self->{option_results}->{oid_display}}}->{$oids_iftable{$self->{option_results}->{oid_display}} . '.' . $options{instance}});
    
    $self->{interface_selected}->{$options{instance}}->{opstatus} = $self->{results}->{$oid_ifOperStatus}->{$oid_ifOperStatus . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{admstatus} = $self->{results}->{$oid_ifAdminStatus}->{$oid_ifAdminStatus . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{mode} = 32;
    $self->{interface_selected}->{$options{instance}}->{iucast} = $self->{results}->{$oid_ifInUcastPkts}->{$oid_ifInUcastPkts . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{ibcast} = defined($self->{results}->{$oid_ifXEntry}->{$oid_ifInBroadcastPkts . '.' . $options{instance}}) ? $self->{results}->{$oid_ifXEntry}->{$oid_ifInBroadcastPkts . '.' . $options{instance}} : 0;
    $self->{interface_selected}->{$options{instance}}->{imcast} = defined($self->{results}->{$oid_ifXEntry}->{$oid_ifInMulticastPkts . '.' . $options{instance}}) ? $self->{results}->{$oid_ifXEntry}->{$oid_ifInMulticastPkts . '.' . $options{instance}} : 0;
    $self->{interface_selected}->{$options{instance}}->{oucast} = $self->{results}->{$oid_ifOutUcastPkts}->{$oid_ifOutUcastPkts . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{omcast} = defined($self->{results}->{$oid_ifXEntry}->{$oid_ifOutMulticastPkts . '.' . $options{instance}}) ? $self->{results}->{$oid_ifXEntry}->{$oid_ifOutMulticastPkts . '.' . $options{instance}} : 0;
    $self->{interface_selected}->{$options{instance}}->{obcast} = defined($self->{results}->{$oid_ifXEntry}->{$oid_ifOutBroadcastPkts . '.' . $options{instance}}) ? $self->{results}->{$oid_ifXEntry}->{$oid_ifOutBroadcastPkts . '.' . $options{instance}} : 0;
    if (!$self->{snmp}->is_snmpv1()) {
        my $iucast = $self->{results}->{$oid_ifXEntry}->{"${oid_ifHCInUcastPkts}.$options{instance}"};
        if (defined($iucast) && $iucast =~ /[1-9]/) {
            $self->{interface_selected}->{$options{instance}}->{iucast} = $iucast;
            $self->{interface_selected}->{$options{instance}}->{imcast} = defined($self->{results}->{$oid_ifXEntry}->{$oid_ifHCInMulticastPkts . '.' . $options{instance}}) ? $self->{results}->{$oid_ifXEntry}->{$oid_ifHCInMulticastPkts . '.' . $options{instance}} : 0;
            $self->{interface_selected}->{$options{instance}}->{ibcast} = defined($self->{results}->{$oid_ifXEntry}->{$oid_ifHCInBroadcastPkts . '.' . $options{instance}}) ? $self->{results}->{$oid_ifXEntry}->{$oid_ifHCInBroadcastPkts . '.' . $options{instance}} : 0;
            $self->{interface_selected}->{$options{instance}}->{oucast} = $self->{results}->{$oid_ifXEntry}->{$oid_ifHCOutUcastPkts . '.' . $options{instance}};
            $self->{interface_selected}->{$options{instance}}->{omcast} = defined($self->{results}->{$oid_ifXEntry}->{$oid_ifHCOutMulticastPkts . '.' . $options{instance}}) ? $self->{results}->{$oid_ifXEntry}->{$oid_ifHCOutMulticastPkts . '.' . $options{instance}} : 0;
            $self->{interface_selected}->{$options{instance}}->{obcast} = defined($self->{results}->{$oid_ifXEntry}->{$oid_ifHCOutBroadcastPkts . '.' . $options{instance}}) ? $self->{results}->{$oid_ifXEntry}->{$oid_ifHCOutBroadcastPkts . '.' . $options{instance}} : 0;
            $self->{interface_selected}->{$options{instance}}->{mode} = 64;
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my @extra_names = ();
    my $start_xtable = $oid_ifInMulticastPkts;
    my $end_xtable = $oid_ifOutBroadcastPkts;
    if (!$self->{snmp}->is_snmpv1()) {
        $end_xtable = $oid_ifHCOutBroadcastPkts;
    }
    if ($self->{option_results}->{oid_filter} eq 'ifname' || $self->{option_results}->{oid_display} eq 'ifname') {
        push @extra_names, { oid => $oids_iftable{ifname} };
    }
    if ($self->{option_results}->{oid_filter} eq 'ifalias' || $self->{option_results}->{oid_display} eq 'ifalias') {
        push @extra_names, { oid => $oids_iftable{ifalias} };
    }
    if ($self->{option_results}->{oid_filter} eq 'ifdesc' || $self->{option_results}->{oid_display} eq 'ifdesc') {
        push @extra_names, { oid => $oids_iftable{ifdesc} };
    }
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_ifXEntry, start => $start_xtable, end => , $end_xtable},
                                                            { oid => $oid_ifAdminStatus },
                                                            { oid => $oid_ifOperStatus },
                                                            { oid => $oid_ifInUcastPkts },
                                                            { oid => $oid_ifOutUcastPkts },
                                                            @extra_names
                                                         ],
                                                         , nothing_quit => 1);
 
    if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{interface})) {
        if (!defined($self->{results}->{$oids_iftable{$self->{option_results}->{oid_display}}}->{$oids_iftable{$self->{option_results}->{oid_display}} . '.' . $self->{option_results}->{interface}})) {
            $self->{output}->add_option_msg(short_msg => "No interface found for id '" . $self->{option_results}->{interface} . "'.");
            $self->{output}->option_exit();
        }
        $self->add_result(instance => $self->{option_results}->{interface});
    } else {
        foreach my $oid (keys %{$self->{results}->{$oids_iftable{$self->{option_results}->{oid_filter}}}}) {
            $oid =~ /\.(\d+)$/;
            my $instance = $1;
            my $filter_name = $self->{results}->{$oids_iftable{$self->{option_results}->{oid_filter}}}->{$oid}; 
            if (!defined($self->{option_results}->{interface})) {
                $self->add_result(instance => $instance);
                next;
            }
            if (defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{interface}/i) {
                $self->add_result(instance => $instance);
            }
            if (defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{interface}/) {
                $self->add_result(instance => $instance);
            }
            if (!defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name eq $self->{option_results}->{interface}) {
                $self->add_result(instance => $instance);
            }
        }
        
        if (scalar(keys %{$self->{interface_selected}}) <= 0) {
            if (defined($self->{option_results}->{interface})) {
                $self->{output}->add_option_msg(short_msg => "No interface found for name '" . $self->{option_results}->{interface} . "'.");
            } else {
                $self->{output}->add_option_msg(short_msg => "No interface found.");
            }
            $self->{output}->option_exit();
        }
    }
}

1;

__END__

=head1 MODE

Check interface unicast, broadcast and multicast usage.

=over 8

=item B<--warning-*>

Threshold warning (in percent).
Can be: 'in-ucast', 'in-bcast', 'in-mcast', 'out-ucast', 'out-bcast', 'out-mcast'.

=item B<--critical-*>

Threshold critical (in percent).
Can be: 'in-ucast', 'in-bcast', 'in-mcast', 'out-ucast', 'out-bcast', 'out-mcast'.

=item B<--interface>

Set the interface (number expected) ex: 1, 2,... (empty means 'check all interface').

=item B<--name>

Allows to use interface name with option --interface instead of interface oid index.

=item B<--regexp>

Allows to use regexp to filter interfaces (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=item B<--skip>

Skip errors on interface status.

=item B<--oid-filter>

Choose OID used to filter interface (default: ifName) (values: ifDesc, ifAlias, ifName).

=item B<--oid-display>

Choose OID used to display interface (default: ifName) (values: ifDesc, ifAlias, ifName).

=item B<--display-transform-src>

Regexp src to transform display value. (security risk!!!)

=item B<--display-transform-dst>

Regexp dst to transform display value. (security risk!!!)

=back

=cut
