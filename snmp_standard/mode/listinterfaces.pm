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

package snmp_standard::mode::listinterfaces;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my @operstatus = ("up", "down", "testing", "unknown", "dormant", "notPresent", "lowerLayerDown");
my %oids_iftable = (
    'ifdesc' => '.1.3.6.1.2.1.2.2.1.2',
    'ifalias' => '.1.3.6.1.2.1.31.1.1.1.18',
    'ifname' => '.1.3.6.1.2.1.31.1.1.1.1'
);

my $oid_adminstatus = '.1.3.6.1.2.1.2.2.1.7';
my $oid_operstatus = '.1.3.6.1.2.1.2.2.1.8';
my $oid_speed32 = '.1.3.6.1.2.1.2.2.1.5'; # in b/s
my $oid_speed64 = '.1.3.6.1.2.1.31.1.1.1.15';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "name"                    => { name => 'use_name' },
                                  "interface:s"             => { name => 'interface' },
                                  "speed:s"                 => { name => 'speed' },
                                  "filter-status:s"         => { name => 'filter_status' },
                                  "skip-speed0"             => { name => 'skip_speed0' },
                                  "use-adminstatus"         => { name => 'use_adminstatus' },
                                  "regexp"                  => { name => 'use_regexp' },
                                  "regexp-isensitive"       => { name => 'use_regexpi' },
                                  "oid-filter:s"            => { name => 'oid_filter', default => 'ifname'},
                                  "oid-display:s"           => { name => 'oid_display', default => 'ifname'},
                                  "display-transform-src:s" => { name => 'display_transform_src' },
                                  "display-transform-dst:s" => { name => 'display_transform_dst' },
                                });

    $self->{interface_id_selected} = [];
    
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
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    my $result = $self->get_additional_information();
    
    foreach (sort @{$self->{interface_id_selected}}) {
        my $display_value = $self->get_display_value(id => $_);

        my $interface_speed = (defined($result->{$oid_speed64 . "." . $_}) && $result->{$oid_speed64 . "." . $_} ne '' ? ($result->{$oid_speed64 . "." . $_}) : (int($result->{$oid_speed32 . "." . $_} / 1000 / 1000)));        
        if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
            $interface_speed = $self->{option_results}->{speed};
        }
        
        if (defined($self->{option_results}->{skip_speed0}) && $interface_speed == 0) {
            $self->{output}->output_add(long_msg => "Skipping interface '" . $display_value . "': interface speed is 0 and option --skip-speed0 is set");
            next;
        }
        if (defined($self->{option_results}->{filter_status}) && $operstatus[$result->{$oid_operstatus . "." . $_} - 1] !~ /$self->{option_results}->{filter_status}/i) {
            $self->{output}->output_add(long_msg => "Skipping interface '" . $display_value . "': no matching filter status");
            next;
        }
        if (defined($self->{option_results}->{use_adminstatus}) && $operstatus[$result->{$oid_adminstatus . "." . $_} - 1] ne 'up') {
            $self->{output}->output_add(long_msg => "Skipping interface '" . $display_value . "': adminstatus is not 'up' and option --use-adminstatus is set");
            next;
        }

        $self->{output}->output_add(long_msg => "'" . $display_value . "' [speed = $interface_speed, status = " . $operstatus[$result->{$oid_operstatus . "." . $_} - 1] . ", id = $_]");
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List interfaces:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub get_additional_information {
    my ($self, %options) = @_;

    my $oids = [$oid_adminstatus, $oid_operstatus, $oid_speed32];
    if (!$self->{snmp}->is_snmpv1()) {
        push @$oids, $oid_speed64;
    }
    
    $self->{snmp}->load(oids => $oids, instances => $self->{interface_id_selected});
    return $self->{snmp}->get_leef();
}

sub get_display_value {
    my ($self, %options) = @_;
    my $value = $self->{datas}->{$self->{option_results}->{oid_display} . "_" . $options{id}};

    if (defined($self->{option_results}->{display_transform_src})) {
        $self->{option_results}->{display_transform_dst} = '' if (!defined($self->{option_results}->{display_transform_dst}));
        eval "\$value =~ s{$self->{option_results}->{display_transform_src}}{$self->{option_results}->{display_transform_dst}}";
    }
    return $value;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{datas} = {};
    $self->{datas}->{oid_filter} = $self->{option_results}->{oid_filter};
    $self->{datas}->{oid_display} = $self->{option_results}->{oid_display};
    my $result = $self->{snmp}->get_table(oid => $oids_iftable{$self->{option_results}->{oid_filter}});
    $self->{datas}->{all_ids} = [];
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /\.([0-9]+)$/);
        $self->{datas}->{$self->{option_results}->{oid_filter} . "_" . $1} = $self->{output}->to_utf8($result->{$key});
        push @{$self->{datas}->{all_ids}}, $1;
    }
    
    if (scalar(@{$self->{datas}->{all_ids}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't get interfaces...");
        $self->{output}->option_exit();
    }

    if ($self->{option_results}->{oid_filter} ne $self->{option_results}->{oid_display}) {
       $result = $self->{snmp}->get_table(oid => $oids_iftable{$self->{option_results}->{oid_display}});
       foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
            next if ($key !~ /\.([0-9]+)$/);
            $self->{datas}->{$self->{option_results}->{oid_display} . "_" . $1} = $self->{output}->to_utf8($result->{$key});
       }
    }
    
    if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{interface})) {
        # get by ID
        push @{$self->{interface_id_selected}}, $self->{option_results}->{interface}; 
        my $name = $self->{datas}->{$self->{option_results}->{oid_display} . "_" . $self->{option_results}->{interface}};
        if (!defined($name)) {
            $self->{output}->add_option_msg(short_msg => "No interface found for id '" . $self->{option_results}->{interface} . "'.");
            $self->{output}->option_exit();
        }
    } else {
        foreach my $i (@{$self->{datas}->{all_ids}}) {
            my $filter_name = $self->{datas}->{$self->{option_results}->{oid_filter} . "_" . $i};
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
        
        if (scalar(@{$self->{interface_id_selected}}) <= 0 && !defined($options{disco})) {
            if (defined($self->{option_results}->{interface})) {
                $self->{output}->add_option_msg(short_msg => "No interface found for name '" . $self->{option_results}->{interface} . "'.");
            } else {
                $self->{output}->add_option_msg(short_msg => "No interface found.");
            }
            $self->{output}->option_exit();
        }
    }
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'total', 'status', 'interfaceid']);
}

sub disco_show {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->manage_selection(disco => 1);
    return if (scalar(@{$self->{interface_id_selected}}) == 0);
    my $result = $self->get_additional_information();
    foreach (sort @{$self->{interface_id_selected}}) {
        my $display_value = $self->get_display_value(id => $_);
        
        my $interface_speed = (defined($result->{$oid_speed64 . "." . $_}) && $result->{$oid_speed64 . "." . $_} ne '' && $result->{$oid_speed64 . "." . $_} != 0 ? ($result->{$oid_speed64 . "." . $_}) : (int($result->{$oid_speed32 . "." . $_} / 1000 / 1000)));
        if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
            $interface_speed = $self->{option_results}->{speed};
        }
        next if (defined($self->{option_results}->{skip_speed0}) && $interface_speed == 0);
        if (defined($self->{option_results}->{filter_status}) && $operstatus[$result->{$oid_operstatus . "." . $_} - 1] !~ /$self->{option_results}->{filter_status}/i) {
            next;
        }
        if (defined($self->{option_results}->{use_adminstatus}) && $operstatus[$result->{$oid_adminstatus . "." . $_} - 1] ne 'up') {
            next;
        }
        
        $self->{output}->add_disco_entry(name => $display_value,
                                         total => $interface_speed,
                                         status => $result->{$oid_operstatus . "." . $_},
                                         interfaceid => $_);
    }
}

1;

__END__

=head1 MODE

=over 8

=item B<--interface>

Set the interface (number expected) ex: 1, 2,... (empty means 'check all interface').

=item B<--name>

Allows to use interface name with option --interface instead of interface oid index.

=item B<--regexp>

Allows to use regexp to filter interfaces (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=item B<--speed>

Set interface speed (in Mb).

=item B<--skip-speed0>

Don't display interface with speed 0.

=item B<--filter-status>

Display interfaces matching the filter (example: 'up').

=item B<--use-adminstatus>

Display interfaces with AdminStatus 'up'.

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
