################################################################################
# Copyright 2005-2013 MERETHIS
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

package snmp_standard::mode::traffic;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my @operstatus = ("up", "down", "testing", "unknown", "dormant", "notPresent", "lowerLayerDown");
my %oids_iftable = (
    'ifdesc' => '.1.3.6.1.2.1.2.2.1.2',
    'ifalias' => '.1.3.6.1.2.1.31.1.1.1.18',
    'ifname' => '.1.3.6.1.2.1.31.1.1.1.1'
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning-in:s"            => { name => 'warning_in' },
                                  "critical-in:s"           => { name => 'critical_in' },
                                  "warning-out:s"           => { name => 'warning_out' },
                                  "critical-out:s"          => { name => 'critical_out' },
                                  "reload-cache-time:s"     => { name => 'reload_cache_time', default => 180 },
                                  "name"                    => { name => 'use_name' },
                                  "interface:s"             => { name => 'interface' },
                                  "speed:s"                 => { name => 'speed' },
                                  "speed-in:s"              => { name => 'speed_in' },
                                  "speed-out:s"             => { name => 'speed_out' },
                                  "skip"                    => { name => 'skip' },
                                  "skip-speed0"             => { name => 'skip_speed0' },
                                  "regexp"                  => { name => 'use_regexp' },
                                  "regexp-isensitive"       => { name => 'use_regexpi' },
                                  "oid-filter:s"            => { name => 'oid_filter', default => 'ifname'},
                                  "oid-display:s"           => { name => 'oid_display', default => 'ifname'},
                                  "display-transform-src:s" => { name => 'display_transform_src' },
                                  "display-transform-dst:s" => { name => 'display_transform_dst' },
                                  "show-cache"              => { name => 'show_cache' },
                                });

    $self->{interface_id_selected} = [];
    $self->{get_speed} = 0;
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning-in', value => $self->{option_results}->{warning_in})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning 'in' threshold '" . $self->{option_results}->{warning_in} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-in', value => $self->{option_results}->{critical_in})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical 'in' threshold '" . $self->{option_results}->{critical_in} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-out', value => $self->{option_results}->{warning_out})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning 'out' threshold '" . $self->{option_results}->{warning_out} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-out', value => $self->{option_results}->{critical_out})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical 'out' threshold '" . $self->{option_results}->{critical_out} . "'.");
        $self->{output}->option_exit();
    }
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
    if ((!defined($self->{option_results}->{speed}) || $self->{option_results}->{speed} eq '') &&
        ((!defined($self->{option_results}->{speed_in}) || $self->{option_results}->{speed_in} eq '') ||
        (!defined($self->{option_results}->{speed_out}) || $self->{option_results}->{speed_out} eq ''))) {
        $self->{get_speed} = 1;
    }
    
    $self->{statefile_cache}->check_options(%options);
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();

    $self->manage_selection();
    
    my $oid_adminstatus = '.1.3.6.1.2.1.2.2.1.7';
    my $oid_operstatus = '.1.3.6.1.2.1.2.2.1.8';
    my $oid_speed32 = '.1.3.6.1.2.1.2.2.1.5'; # in b/s
    my $oid_in32 = '.1.3.6.1.2.1.2.2.1.10'; # in B
    my $oid_out32 = '.1.3.6.1.2.1.2.2.1.16'; # in B
    my $oid_speed64 = '.1.3.6.1.2.1.31.1.1.1.15'; # need multiple by '1000000'
    my $oid_in64 = '.1.3.6.1.2.1.31.1.1.1.6'; # in B
    my $oid_out64 = '.1.3.6.1.2.1.31.1.1.1.10'; # in B

    my $new_datas = {};
    $self->{statefile_value}->read(statefile => "snmpstandard_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode} . '_' . (defined($self->{option_results}->{interface}) ? md5_hex($self->{option_results}->{interface}) : md5_hex('all')));
    
    foreach (@{$self->{interface_id_selected}}) {
        $self->{snmp}->load(oids => [$oid_adminstatus . "." . $_, $oid_operstatus . "." . $_, $oid_in32 . "." . $_, $oid_out32 . "." . $_]);
        if ($self->{get_speed} == 1) {
            $self->{snmp}->load(oids => [$oid_speed32 . "." . $_]);
        }
        if (!$self->{snmp}->is_snmpv1()) {
            $self->{snmp}->load(oids => [$oid_in64 . "." . $_, $oid_out64 . "." . $_]);
            if ($self->{get_speed} == 1) {
                $self->{snmp}->load(oids => [$oid_speed64 . "." . $_]);
            }
        }
    }

    my $result = $self->{snmp}->get_leef();
    $new_datas->{last_timestamp} = time();
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
    my $buffer_creation = 0;
    if (!defined($self->{option_results}->{interface}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All traffic are ok');
    }

    foreach (sort @{$self->{interface_id_selected}}) {
        my $display_value = $self->get_display_value(id => $_);

        if ($operstatus[$result->{$oid_operstatus . "." . $_} - 1] ne "up") {
            if (!defined($self->{option_results}->{skip}) && (!defined($result->{$oid_adminstatus . "." . $_}) || $operstatus[$result->{$oid_adminstatus . "." . $_} - 1] eq 'up') ) {
                $self->{output}->output_add(severity => 'CRITICAL',
                                            short_msg => "Interface '" . $display_value . "' is not ready: " . $operstatus[$result->{$oid_operstatus . "." . $_} - 1]);
            } else {
                # Avoid getting "buffer creation..." alone
                if (defined($self->{option_results}->{interface}) && !defined($self->{option_results}->{use_regexp})) {
                    $self->{output}->output_add(severity => 'OK',
                                                short_msg => "Interface '" . $display_value . "' is not up (normal state)");
                }
                $self->{output}->output_add(long_msg => "Skip interface '" . $display_value . "'.");
            }
            next;
        }
        
        # Manage interface speed
        my ($interface_speed_in, $interface_speed_out);
        
        if ($self->{get_speed} == 0) {
            if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
                $interface_speed_in = $self->{option_results}->{speed} * 1000000;
                $interface_speed_out = $self->{option_results}->{speed} * 1000000;
            }
            $interface_speed_in = $self->{option_results}->{speed_in} * 1000000 if (defined($self->{option_results}->{speed_in}) && $self->{option_results}->{speed_in} ne '');
            $interface_speed_out = $self->{option_results}->{speed_out} * 1000000 if (defined($self->{option_results}->{speed_out}) && $self->{option_results}->{speed_out} ne '');
        } else {
            if ((!defined($result->{$oid_speed32 . "." . $_}) || $result->{$oid_speed32 . "." . $_} !~ /^[0-9]+$/) && 
                (!defined($result->{$oid_speed64 . "." . $_}) || $result->{$oid_speed64 . "." . $_} !~ /^[0-9]+$/)) {
                $self->{output}->output_add(severity => 'UNKNOWN',
                                            short_msg => "Interface '" . $display_value . "' Speed is null or incorrect. You should force the value with --speed option");
                next;
            }
            my $interface_speed;

            if (defined($result->{$oid_speed64 . "." . $_}) && $result->{$oid_speed64 . "." . $_} ne '') {
                $interface_speed = $result->{$oid_speed64 . "." . $_} * 1000000;
                # If 0, we put the 32 bits
                if ($interface_speed == 0) {
                    $interface_speed = $result->{$oid_speed32 . "." . $_};
                }
            } else {
                $interface_speed = $result->{$oid_speed32 . "." . $_};
            }
            if (!defined($interface_speed) || $interface_speed == 0) {
                if (!defined($self->{option_results}->{skip_speed0})) {
                    $self->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Interface '" . $display_value . "' Speed is 0. You should force the value with --speed option");
                } else {
                    $self->{output}->output_add(long_msg => "Skip interface '" . $display_value . "' (speed is 0).");
                }
                next;
            }
            $interface_speed_in = $interface_speed;
            $interface_speed_out = $interface_speed;
            $interface_speed_in = $self->{option_results}->{speed_in} * 1000000 if (defined($self->{option_results}->{speed_in}) && $self->{option_results}->{speed_in} ne '');
            $interface_speed_out = $self->{option_results}->{speed_out} * 1000000 if (defined($self->{option_results}->{speed_out}) && $self->{option_results}->{speed_out} ne '');
        }
        
        my $old_mode = $self->{statefile_value}->get(name => 'mode_' . $_);
        $new_datas->{'mode_' . $_} = '32';
 
        $new_datas->{'in_' . $_} = $result->{$oid_in32 . "." . $_};
        if (defined($result->{$oid_in64 . "." . $_}) && $result->{$oid_in64 . "." . $_} ne '' && $result->{$oid_in64 . "." . $_} != 0) {
            $new_datas->{'in_' . $_} = $result->{$oid_in64 . "." . $_};
            $new_datas->{'mode_' . $_} = '64';
        }
        $new_datas->{'out_' . $_} = $result->{$oid_out32 . "." . $_};
        if (defined($result->{$oid_out64 . "." . $_}) && $result->{$oid_out64 . "." . $_} ne '' && $result->{$oid_out64 . "." . $_} != 0) {
            $new_datas->{'out_' . $_} = $result->{$oid_out64 . "." . $_};
            $new_datas->{'mode_' . $_} = '64';
        }
        
        # Check if there is no values. Can happen :)
        if (!defined($new_datas->{'out_' . $_}) || !defined($new_datas->{'in_' . $_})) {
            # Avoid empty message
            if (defined($self->{option_results}->{interface}) && !defined($self->{option_results}->{use_regexp})) {
                 $self->{output}->output_add(severity => 'OK',
                                             short_msg => "Interface '" . $display_value . "' is up");
            }
            $self->{output}->output_add(long_msg => "Skip interface '" . $display_value . "': bytes values are missing.");
            next;
        }
        $new_datas->{'out_' . $_} *= 8;
        $new_datas->{'in_' . $_} *= 8;
        
        # We change mode. need to recreate a buffer
        if (!defined($old_mode) || $new_datas->{'mode_' . $_} ne $old_mode) {
            $buffer_creation = 1;
            next;
        }
        
        my $old_in = $self->{statefile_value}->get(name => 'in_' . $_);
        my $old_out = $self->{statefile_value}->get(name => 'out_' . $_);
        if (!defined($old_in) || !defined($old_out)) {
            $buffer_creation = 1;
            next;
        }
        
        if ($new_datas->{'in_' . $_} < $old_in) {
            # We set 0. Has reboot.
            $old_in = 0;
        }
        if ($new_datas->{'out_' . $_} < $old_out) {
            # We set 0. Has reboot.
            $old_out = 0;
        }

        my $time_delta = $new_datas->{last_timestamp} - $old_timestamp;
        if ($time_delta <= 0) {
            # At least one second. two fast calls ;)
            $time_delta = 1;
        }
        my $in_absolute_per_sec = ($new_datas->{'in_' . $_} - $old_in) / $time_delta;
        my $out_absolute_per_sec = ($new_datas->{'out_' . $_} - $old_out) / $time_delta;
        my $in_prct = $in_absolute_per_sec * 100 / $interface_speed_in;
        my $out_prct = $out_absolute_per_sec * 100 / $interface_speed_out;
       
        ###########
        # Manage Output
        ###########
        my $exit1 = $self->{perfdata}->threshold_check(value => $in_prct, threshold => [ { label => 'critical-in', 'exit_litteral' => 'critical' }, { label => 'warning-in', exit_litteral => 'warning' } ]);
        my $exit2 = $self->{perfdata}->threshold_check(value => $out_prct, threshold => [ { label => 'critical-out', 'exit_litteral' => 'critical' }, { label => 'warning-out', exit_litteral => 'warning' } ]);

        my ($in_value, $in_unit) = $self->{perfdata}->change_bytes(value => $in_absolute_per_sec, network => 1);
        my ($out_value, $out_unit) = $self->{perfdata}->change_bytes(value => $out_absolute_per_sec, network => 1);
        my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
        $self->{output}->output_add(long_msg => sprintf("Interface '%s' Traffic In : %s/s (%.2f %%), Out : %s/s (%.2f %%) ", $display_value,
                                       $in_value . $in_unit, $in_prct,
                                       $out_value . $out_unit, $out_prct));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1) || (defined($self->{option_results}->{interface}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Interface '%s' Traffic In : %s/s (%.2f %%), Out : %s/s (%.2f %%) ", $display_value,
                                            $in_value . $in_unit, $in_prct,
                                            $out_value . $out_unit, $out_prct));
        }

        my $extra_label = '';
        $extra_label = '_' . $display_value if (!defined($self->{option_results}->{interface}) || defined($self->{option_results}->{use_regexp}));
        $self->{output}->perfdata_add(label => 'traffic_in' . $extra_label, unit => 'b/s',
                                      value => sprintf("%.2f", $in_absolute_per_sec),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-in', total => $interface_speed_in),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-in', total => $interface_speed_in),
                                      min => 0, max => $interface_speed_in);
        $self->{output}->perfdata_add(label => 'traffic_out' . $extra_label, unit => 'b/s',
                                      value => sprintf("%.2f", $out_absolute_per_sec),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-out', total => $interface_speed_out),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-out', total => $interface_speed_out),
                                      min => 0, max => $interface_speed_out);
    }

    $self->{statefile_value}->write(data => $new_datas);    
    if ($buffer_creation == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
    }

    $self->{output}->display();
    $self->{output}->exit();
}

sub get_display_value {
    my ($self, %options) = @_;
    my $value = $self->{statefile_cache}->get(name => $self->{option_results}->{oid_display} . "_" . $options{id});

    if (defined($self->{option_results}->{display_transform_src})) {
        $self->{option_results}->{display_transform_dst} = '' if (!defined($self->{option_results}->{display_transform_dst}));
        eval "\$value =~ s{$self->{option_results}->{display_transform_src}}{$self->{option_results}->{display_transform_dst}}";
    }
    return $value;
}

sub reload_cache {
    my ($self) = @_;
    my $datas = {};

    $datas->{oid_filter} = $self->{option_results}->{oid_filter};
    $datas->{oid_display} = $self->{option_results}->{oid_display};
    $datas->{last_timestamp} = time();
    $datas->{all_ids} = [];
    my $result = $self->{snmp}->get_table(oid => $oids_iftable{$self->{option_results}->{oid_filter}});
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /\.([0-9]+)$/);
        push @{$datas->{all_ids}}, $1;
        $datas->{$self->{option_results}->{oid_filter} . "_" . $1} = $self->{output}->to_utf8($result->{$key});
    }

    if (scalar(@{$datas->{all_ids}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't construct cache...");
        $self->{output}->option_exit();
    }

    if ($self->{option_results}->{oid_filter} ne $self->{option_results}->{oid_display}) {
       $result = $self->{snmp}->get_table(oid => $oids_iftable{$self->{option_results}->{oid_display}});
       foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
            next if ($key !~ /\.([0-9]+)$/);
            $datas->{$self->{option_results}->{oid_display} . "_" . $1} = $self->{output}->to_utf8($result->{$key});
       }
    }
    
    $self->{statefile_cache}->write(data => $datas);
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
    my $oid_display = $self->{statefile_cache}->get(name => 'oid_display');
    my $oid_filter = $self->{statefile_cache}->get(name => 'oid_filter');
    if ($has_cache_file == 0 ||
        ($self->{option_results}->{oid_display} !~ /^($oid_display|$oid_filter)$/i || $self->{option_results}->{oid_filter} !~ /^($oid_display|$oid_filter)$/i) ||
        !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60))) {
        $self->reload_cache();
        $self->{statefile_cache}->read();
    }

    my $all_ids = $self->{statefile_cache}->get(name => 'all_ids');
    if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{interface})) {
        # get by ID
        push @{$self->{interface_id_selected}}, $self->{option_results}->{interface}; 
        my $name = $self->{statefile_cache}->get(name => $self->{option_results}->{oid_display} . "_" . $self->{option_results}->{interface});
        if (!defined($name)) {
            $self->{output}->add_option_msg(short_msg => "No interface found for id '" . $self->{option_results}->{interface} . "'.");
            $self->{output}->option_exit();
        }
    } else {
        foreach my $i (@{$all_ids}) {
            my $filter_name = $self->{statefile_cache}->get(name => $self->{option_results}->{oid_filter} . "_" . $i);
            next if (!defined($filter_name));
            if (!defined($self->{option_results}->{interface})) {
                push @{$self->{interface_id_selected}}, $i; 
                next;
            }
            if (defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{interface}/i) {
                push @{$self->{interface_id_selected}}, $i; 
            }
            if (defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{interface}/) {
                push @{$self->{interface_id_selected}}, $i; 
            }
            if (!defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name eq $self->{option_results}->{interface}) {
                push @{$self->{interface_id_selected}}, $i; 
            }
        }
        
        if (scalar(@{$self->{interface_id_selected}}) <= 0) {
            if (defined($self->{option_results}->{interface})) {
                $self->{output}->add_option_msg(short_msg => "No interface found for name '" . $self->{option_results}->{interface} . "' (maybe you should reload cache file).");
            } else {
                $self->{output}->add_option_msg(short_msg => "No interface found (maybe you should reload cache file).");
            }
            $self->{output}->option_exit();
        }
    }
}

1;

__END__

=head1 MODE

=over 8

=item B<--warning-in>

Threshold warning in percent for 'in' traffic.

=item B<--critical-in>

Threshold critical in percent for 'in' traffic.

=item B<--warning-out>

Threshold warning in percent for 'out' traffic.

=item B<--critical-out>

Threshold critical in percent for 'out' traffic.

=item B<--interface>

Set the interface (number expected) ex: 1, 2,... (empty means 'check all interface').

=item B<--name>

Allows to use interface name with option --interface instead of interface oid index.

=item B<--regexp>

Allows to use regexp to filter interfaces (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=item B<--speed>

Set interface speed for incoming/outgoing traffic (in Mb).

=item B<--speed-in>

Set interface speed for incoming traffic (in Mb).

=item B<--speed-out>

Set interface speed for outgoing traffic (in Mb).

=item B<--skip>

Skip errors on interface status.

=item B<--skip-speed0>

Skip errors on interface with speed 0.

=item B<--reload-cache-time>

Time in seconds before reloading cache file (default: 180).

=item B<--oid-filter>

Choose OID used to filter interface (default: ifName) (values: ifDesc, ifAlias, ifName).

=item B<--oid-display>

Choose OID used to display interface (default: ifName) (values: ifDesc, ifAlias, ifName).

=item B<--display-transform-src>

Regexp src to transform display value. (security risk!!!)

=item B<--display-transform-dst>

Regexp dst to transform display value. (security risk!!!)

=item B<--show-cache>

Display cache interface datas.

=back

=cut
