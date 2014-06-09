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

package apps::pfsense::snmp::mode::blockedpackets;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use POSIX;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my $oid_pfsenseInterfaceName = '.1.3.6.1.4.1.12325.1.200.1.8.2.1.2';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning-in:s"            => { name => 'warning_in', },
                                  "warning-out:s"           => { name => 'warning_out', },
                                  "critical-in:s"           => { name => 'critical_in', },
                                  "critical-out:s"          => { name => 'critical_out', },
                                  "reload-cache-time:s"     => { name => 'reload_cache_time', default => 180 },
                                  "name"                    => { name => 'use_name' },
                                  "interface:s"             => { name => 'interface' },
                                  "regexp"                  => { name => 'use_regexp' },
                                  "regexp-isensitive"       => { name => 'use_regexpi' },
                                  "show-cache"              => { name => 'show_cache' },
                                });

    $self->{interface_id_selected} = [];
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning-in', value => $self->{option_results}->{warning_in})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning in threshold '" . $self->{option_results}->{warning_in} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-out', value => $self->{option_results}->{warning_out})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning out threshold '" . $self->{option_results}->{warning_out} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-in', value => $self->{option_results}->{critical_in})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical in threshold '" . $self->{option_results}->{critical_in} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-out', value => $self->{option_results}->{critical_out})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical out threshold '" . $self->{option_results}->{critical_out} . "'.");
       $self->{output}->option_exit();
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

    if ($self->{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Can't check SNMP 64 bits counters with SNMPv1.");
        $self->{output}->option_exit();
    }

    $self->manage_selection();

    my $oid_pfsenseBlockedInPackets = '.1.3.6.1.4.1.12325.1.200.1.8.2.1.12';
    my $oid_pfsenseBlockedOutPackets = '.1.3.6.1.4.1.12325.1.200.1.8.2.1.14';
    my ($result, $valueIn, $valueOut);
   
    my $new_datas = {};
    $self->{statefile_value}->read(statefile => "pfsense_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode} . '_' . (defined($self->{option_results}->{interface}) ? md5_hex($self->{option_results}->{interface}) : md5_hex('all')));


    foreach (@{$self->{interface_id_selected}}) {
        $self->{snmp}->load(oids => [$oid_pfsenseBlockedInPackets . "." . $_, $oid_pfsenseBlockedOutPackets . "." . $_]);
    }

    $result = $self->{snmp}->get_leef();
    $new_datas->{last_timestamp} = time();
    my $old_timestamp;
    if (!defined($self->{option_results}->{interface}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All interfaces are ok.');
    }

    foreach (sort @{$self->{interface_id_selected}}) {
        my $display_value = $self->{statefile_value}->get(name => $_);

        #################
        # New values
        ################# 
        $new_datas->{'in_blocked_' . $_} = $result->{$oid_pfsenseBlockedInPackets . "." . $_};
        $new_datas->{'out_blocked_' . $_} = $result->{$oid_pfsenseBlockedOutPackets . "." . $_};

        ################
        # Old values
        ################
        my @getting = ('in_blocked', 'out_blocked');
        my $old_datas = {};
        $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
        foreach my $key (@getting) {
            $old_datas->{$key} = $self->{statefile_value}->get(name => $key . '_' . $_);
            if (!defined($old_datas->{$key}) || $new_datas->{$key . '_' . $_} < $old_datas->{$key}) {
                # We set 0. Has reboot.
                $old_datas->{$key} = 0;
            }
        }

        if (!defined($old_timestamp)) {
            next;
        }
        my $time_delta = $new_datas->{last_timestamp} - $old_timestamp;
        if ($time_delta <= 0) {
            # At least one second. two fast calls ;)
            $time_delta = 1;
        }

        ###########
        
        my $in_blocked_absolute = $new_datas->{'in_blocked_' . $_} - $old_datas->{in_blocked};
        my $out_blocked_absolute = $new_datas->{'out_blocked_' . $_} - $old_datas->{out_blocked};
        my $in_blocked_absolute_per_sec = $in_blocked_absolute / $time_delta;
        my $out_blocked_absolute_per_sec = $out_blocked_absolute / $time_delta;    

        ###############
        # Manage Output
        ###############

        my $exit1 = $self->{perfdata}->threshold_check(value => $in_blocked_absolute_per_sec, threshold => [ { label => 'critical-in', 'exit_litteral' => 'critical' }, { label => 'warning-in', exit_litteral => 'warning' } ]);
        my $exit2 = $self->{perfdata}->threshold_check(value => $out_blocked_absolute_per_sec, threshold => [ { label => 'critical-out', 'exit_litteral' => 'critical' }, { label => 'warning-out', exit_litteral => 'warning' } ]);

        my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
        $self->{output}->output_add(long_msg => sprintf("Interface '%s' Packets In Blocked : %.2f /s, Out Blocked : %.2f /s", $display_value,
                                                $in_blocked_absolute_per_sec, $in_blocked_absolute,
                                                $out_blocked_absolute_per_sec, $out_blocked_absolute));

        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1) || (defined($self->{option_results}->{interface}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Interface '%s' Packets In Blocked : %.2f /s [%i], Out Blocked : %.2f /s [%i]", $display_value,
                                                    $in_blocked_absolute_per_sec, 
                                                    $out_blocked_absolute_per_sec));
        }

        my $extra_label = '';
        $extra_label = '_' . $display_value if (!defined($self->{option_results}->{interface}) || defined($self->{option_results}->{use_regexp}));
        $self->{output}->perfdata_add(label => 'packets_blocked_in_per_sec' . $extra_label,
                                      value => sprintf("%.2f", $in_blocked_absolute_per_sec),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-in'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-in'),
                                      min => 0);
        $self->{output}->perfdata_add(label => 'packets_blocked_out_per_sec' . $extra_label,
                                      value => sprintf("%.2f", $out_blocked_absolute_per_sec),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-out'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-out'),
                                      min => 0);

    }

    $self->{statefile_value}->write(data => $new_datas);
    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
    }

    $self->{output}->display();
    $self->{output}->exit();
}

sub reload_cache {
    my ($self) = @_;
    my $datas = {};

    $datas->{last_timestamp} = time();
    $datas->{all_ids} = [];

    my $result = $self->{snmp}->get_table(oid => $oid_pfsenseInterfaceName);
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /\.([0-9]+)$/);
        push @{$datas->{all_ids}}, $1;
        $datas->{$1} = $self->{output}->to_utf8($result->{$key});
    }

    if (scalar(@{$datas->{all_ids}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't construct cache...");
        $self->{output}->option_exit();
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
    if ($has_cache_file == 0) {
        $self->reload_cache();
        $self->{statefile_cache}->read();
    }

    my $all_ids = $self->{statefile_cache}->get(name => 'all_ids');
    if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{interface})) {
        # get by ID
        push @{$self->{interface_id_selected}}, $self->{option_results}->{interface};
        my $name = $self->{statefile_cache}->get(name => $self->{option_results}->{interface});
        if (!defined($name)) {
            $self->{output}->add_option_msg(short_msg => "No interface found for id '" . $self->{option_results}->{interface} . "'.");
            $self->{output}->option_exit();
        }
    } else {
        foreach my $i (@{$all_ids}) {
            my $filter_name = $self->{statefile_cache}->get(name => $i);
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

Check pfSense blocked packets.

=over 8

=item B<--warning-in>

Threshold warning for input blocked packets.

=item B<--warning-out>

Threshold warning for output blocked packets.

=item B<--critical-in>

Threshold critical for input blocked packets.

=item B<--critical-out>

Threshold critical for output blocked packets.

=item B<--interface>

Set the interface (number expected) ex: 1, 2,... (empty means 'check all interface').

=item B<--name>

Allows to use interface name with option --interface instead of interface oid index.

=item B<--regexp>

Allows to use regexp to filter interfaces (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=item B<--reload-cache-time>

Time in seconds before reloading cache file (default: 180).

=item B<--show-cache>

Display cache interface datas.


=back

=cut
