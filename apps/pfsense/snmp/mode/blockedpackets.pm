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
                                  "name"                    => { name => 'use_name' },
                                  "interface:s"             => { name => 'interface' },
                                  "regexp"                  => { name => 'use_regexp' },
                                  "regexp-isensitive"       => { name => 'use_regexpi' },
                                });

    $self->{interface_id_selected} = [];
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

    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
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
    
    $self->{snmp}->load(oids => [$oid_pfsenseBlockedInPackets, $oid_pfsenseBlockedOutPackets],
                        instances => $self->{interface_id_selected});
    $result = $self->{snmp}->get_leef();

    $new_datas->{last_timestamp} = time();
    my $old_timestamp;
    if (!defined($self->{option_results}->{interface}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All interfaces are ok.');
    }

    foreach (sort @{$self->{interface_id_selected}}) {
        my $display_value = $self->{names}->{$_};

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
        $self->{output}->output_add(long_msg => sprintf("Interface '%s' Packets In Blocked : %.2f /s [%i packets], Out Blocked : %.2f /s [%i packets]", $display_value,
                                                $in_blocked_absolute_per_sec, $in_blocked_absolute,
                                                $out_blocked_absolute_per_sec, $out_blocked_absolute));

        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1) || (defined($self->{option_results}->{interface}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Interface '%s' Packets In Blocked : %.2f /s [%i packets], Out Blocked : %.2f /s [%i packets]", $display_value,
                                                    $in_blocked_absolute_per_sec, $in_blocked_absolute, 
                                                    $out_blocked_absolute_per_sec, $out_blocked_absolute));
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

sub manage_selection {
    my ($self, %options) = @_;
    
    my $all_ids = [];
    $self->{names} = {};
    my $result = $self->{snmp}->get_table(oid => $oid_pfsenseInterfaceName, nothing_quit => 1);
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /\.([0-9]+)$/);
        push @{$all_ids}, $1;
        $self->{names}->{$1} = $self->{output}->to_utf8($result->{$key});
    }

    if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{interface})) {
        # get by ID
        push @{$self->{interface_id_selected}}, $self->{option_results}->{interface};
        if (!defined($self->{names}->{$self->{option_results}->{interface}})) {
            $self->{output}->add_option_msg(short_msg => "No interface found for id '" . $self->{option_results}->{interface} . "'.");
            $self->{output}->option_exit();
        }
    } else {
        foreach my $i (@{$all_ids}) {
            my $filter_name = $self->{names}->{$i};
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

=back

=cut
