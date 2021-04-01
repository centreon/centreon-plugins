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

package snmp_standard::mode::listinterfaces;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use snmp_standard::mode::resources::types qw($map_iftype);

my $oid_speed32 = '.1.3.6.1.2.1.2.2.1.5'; # in b/s
my $oid_speed64 = '.1.3.6.1.2.1.31.1.1.1.15';

sub set_oids_status {
    my ($self, %options) = @_;

    $self->{oid_adminstatus} = '.1.3.6.1.2.1.2.2.1.7';
    $self->{oid_adminstatus_mapping} = {
        1 => 'up', 2 => 'down', 3 => 'testing', 4 => 'unknown', 5 => 'dormant', 6 => 'notPresent', 7 => 'lowerLayerDown'
    };
    $self->{oid_opstatus} = '.1.3.6.1.2.1.2.2.1.8';
    $self->{oid_opstatus_mapping} = {
        1 => 'up', 2 => 'down', 3 => 'testing', 4 => 'unknown', 5 => 'dormant', 6 => 'notPresent', 7 => 'lowerLayerDown'
    };
    $self->{oid_mac_address} = '.1.3.6.1.2.1.2.2.1.6';
    $self->{oid_iftype} = '.1.3.6.1.2.1.2.2.1.3';
}

sub check_oids_label {
    my ($self, %options) = @_;

    foreach (('oid_filter', 'oid_display')) {
        $self->{option_results}->{$_} = lc($self->{option_results}->{$_}) if (defined($self->{option_results}->{$_}));
        if (!defined($self->{oids_label}->{$self->{option_results}->{$_}})) {
            my $label = $_;
            $label =~ s/_/-/g;
            $self->{output}->add_option_msg(short_msg => "Unsupported oid in --" . $label . " option.");
            $self->{output}->option_exit();
        }
    }
}

sub set_oids_label {
    my ($self, %options) = @_;

    $self->{oids_label} = {
        'ifdesc' => '.1.3.6.1.2.1.2.2.1.2',
        'ifalias' => '.1.3.6.1.2.1.31.1.1.1.18',
        'ifname' => '.1.3.6.1.2.1.31.1.1.1.1'
    };
}

sub default_oid_filter_name {
    my ($self, %options) = @_;

    return 'ifname';
}

sub default_oid_display_name {
    my ($self, %options) = @_;

    return 'ifname';
}

sub is_admin_status_down {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{use_adminstatus}) && defined($options{admin_status}) && 
        $self->{oid_adminstatus_mapping}->{$options{admin_status}} ne 'up') {
        return 1;
    }
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => defined($options{package}) ? $options{package} : __PACKAGE__, %options);
    bless $self, $class;

    $self->{no_speed} = defined($options{no_speed}) && $options{no_speed} =~ /^[01]$/ ? $options{no_speed} : 0;
    $options{options}->add_options(arguments => { 
        'name'                    => { name => 'use_name' },
        'interface:s'             => { name => 'interface' },
        'speed:s'                 => { name => 'speed' },
        'filter-status:s'         => { name => 'filter_status' },
        'skip-speed0'             => { name => 'skip_speed0' },
        'use-adminstatus'         => { name => 'use_adminstatus' },
        'oid-filter:s'            => { name => 'oid_filter', default => $self->default_oid_filter_name() },
        'oid-display:s'           => { name => 'oid_display', default => $self->default_oid_display_name() },
        'display-transform-src:s' => { name => 'display_transform_src' },
        'display-transform-dst:s' => { name => 'display_transform_dst' },
        'add-extra-oid:s@'        => { name => 'add_extra_oid' },
        'add-mac-address'         => { name => 'add_mac_address' }
    });

    $self->{interface_id_selected} = [];

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->set_oids_label();
    $self->check_oids_label();
    $self->set_oids_status();

    $self->{extra_oids} = {};
    foreach (@{$self->{option_results}->{add_extra_oid}}) {
        next if ($_ eq '');
        my ($name, $oid, $matching) = split /,/;
        $matching = '%{instance}$' if (!defined($matching));
        if (!defined($oid) || $oid !~ /^(\.\d+){1,}$/ || $name eq '') {
            $self->{output}->add_option_msg(short_msg => "Wrong syntax for add-extra-oid '" . $_ . "' option.");
            $self->{output}->option_exit();
        }
        $self->{extra_oids}->{$name} = { oid => $oid, matching => $matching };
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    my $result = $self->get_additional_information();
    foreach (sort @{$self->{interface_id_selected}}) {
        my $display_value = $self->get_display_value(id => $_);

        my $interface_speed = 0;
        if ($self->{no_speed} == 0) {
            $interface_speed = (defined($result->{$oid_speed64 . "." . $_}) && $result->{$oid_speed64 . "." . $_} ne '' && $result->{$oid_speed64 . "." . $_} != 0) ? 
                                ($result->{$oid_speed64 . "." . $_}) : 
                                    (defined($result->{$oid_speed32 . "." . $_}) && $result->{$oid_speed32 . "." . $_} ne '' && $result->{$oid_speed32 . "." . $_} != 0 ?
                                        (sprintf("%g", $result->{$oid_speed32 . "." . $_} / 1000 / 1000)) : '');
        }
        if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
            $interface_speed = $self->{option_results}->{speed};
        }

        if (defined($self->{option_results}->{skip_speed0}) && $interface_speed == 0) {
            $self->{output}->output_add(long_msg => "skipping interface '" . $display_value . "': interface speed is 0 and option --skip-speed0 is set");
            next;
        }
        if (defined($self->{option_results}->{filter_status}) && defined($result->{$self->{oid_opstatus} . "." . $_}) && 
            $self->{oid_opstatus_mapping}->{$result->{$self->{oid_opstatus} . "." . $_}} !~ /$self->{option_results}->{filter_status}/i) {
            $self->{output}->output_add(long_msg => "skipping interface '" . $display_value . "': no matching filter status");
            next;
        }
        if ($self->is_admin_status_down(admin_status => $result->{$self->{oid_adminstatus} . "." . $_})) {
            $self->{output}->output_add(long_msg => "skipping interface '" . $display_value . "': adminstatus is not 'up' and option --use-adminstatus is set");
            next;
        }

        my $extra_values = $self->get_extra_values_by_instance(result => $result, instance => $_);
        my $extra_display = '';
        foreach my $name (keys %{$extra_values}) {
            $extra_display .= '[' . $name . ' = ' . $extra_values->{$name} . ']';
        }
        if (defined($self->{oid_iftype})) {
            $extra_display .= '[type = ' . $map_iftype->{ $result->{ $self->{oid_iftype} . '.' . $_ } } . ']';
        }

        $self->{output}->output_add(
            long_msg => sprintf(
                "'%s' [speed = %s][status = %s][id = %s]%s",
                $display_value,
                $interface_speed,
                (defined($result->{$self->{oid_opstatus} . "." . $_}) ?  $self->{oid_opstatus_mapping}->{$result->{$self->{oid_opstatus} . "." . $_}} : ''),
                $_,
                $extra_display
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List interfaces:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub get_additional_information {
    my ($self, %options) = @_;

    my $oids = [];
    push @$oids, $self->{oid_adminstatus} if (defined($self->{oid_adminstatus}));
    push @$oids, $self->{oid_opstatus} if (defined($self->{oid_opstatus}));
    push @$oids, $self->{oid_mac_address} if (defined($self->{option_results}->{add_mac_address}));
    push @$oids, $self->{oid_iftype} if (defined($self->{oid_iftype}));
    push @$oids, $oid_speed32 if ($self->{no_speed} == 0);
    push @$oids, $oid_speed64 if (!$self->{snmp}->is_snmpv1() && $self->{no_speed} == 0);
    
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

    my $oids = [{ oid => $self->{oids_label}->{$self->{option_results}->{oid_filter}} }];
    if ($self->{option_results}->{oid_filter} ne $self->{option_results}->{oid_display}) {
        push @$oids, { oid => $self->{oids_label}->{$self->{option_results}->{oid_display}} };
    }
    if (scalar(keys %{$self->{extra_oids}}) > 0) {
        foreach (keys %{$self->{extra_oids}}) {
            push @$oids, { oid => $self->{extra_oids}->{$_}->{oid} };
        }
    }
    
    $self->{datas} = {};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $oids);
    $self->{datas}->{all_ids} = [];
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $self->{oids_label}->{$self->{option_results}->{oid_filter}} }})) {
        next if ($key !~ /^$self->{oids_label}->{$self->{option_results}->{oid_filter}}\.(.*)$/);
        $self->{datas}->{$self->{option_results}->{oid_filter} . "_" . $1} = $self->{output}->decode($self->{results}->{$self->{oids_label}->{ $self->{option_results}->{oid_filter}} }->{$key});
        push @{$self->{datas}->{all_ids}}, $1;
    }
    
    if (scalar(@{$self->{datas}->{all_ids}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't get interfaces...");
        $self->{output}->option_exit();
    }

    if ($self->{option_results}->{oid_filter} ne $self->{option_results}->{oid_display}) {
        foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $self->{oids_label}->{$self->{option_results}->{oid_display}} }})) {
            next if ($key !~ /^$self->{oids_label}->{$self->{option_results}->{oid_display}}\.(.*)$/);
            $self->{datas}->{$self->{option_results}->{oid_display} . "_" . $1} = $self->{output}->decode($self->{results}->{$self->{oids_label}->{ $self->{option_results}->{oid_display}} }->{$key});
        }
    }
    
    if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{interface})) {
        foreach (@{$self->{datas}->{all_ids}}) {
            if ($self->{option_results}->{interface} =~ /(^|\s|,)$_(\s*,|$)/) {
                push @{$self->{interface_id_selected}}, $_;
            }
        }
    } else {
        foreach (@{$self->{datas}->{all_ids}}) {
            my $filter_name = $self->{datas}->{$self->{option_results}->{oid_filter} . "_" . $_};
            next if (!defined($filter_name));
            
            if (!defined($self->{option_results}->{interface})) {
                push @{$self->{interface_id_selected}}, $_;
                next;
            }
            if ($filter_name =~ /$self->{option_results}->{interface}/) {
                push @{$self->{interface_id_selected}}, $_; 
            }
        }
    }

    if (scalar(@{$self->{interface_id_selected}}) <= 0 && !defined($options{disco})) {
        $self->{output}->add_option_msg(short_msg => 'No entry found');
        $self->{output}->option_exit();
    }
}

sub get_extra_values_by_instance {
    my ($self, %options) = @_;

    my $extra_values = {};
    foreach my $name (keys %{$self->{extra_oids}}) {
        my $matching = $self->{extra_oids}->{$name}->{matching};
        $matching =~ s/%\{instance\}/$options{instance}/g;
        next if (!defined($self->{results}->{ $self->{extra_oids}->{$name}->{oid} }));

        my $append = '';
        foreach (keys %{$self->{results}->{ $self->{extra_oids}->{$name}->{oid} }}) {
            if (/^$self->{extra_oids}->{$name}->{oid}\.$matching/) {
                $extra_values->{$name} = '' if (!defined($extra_values->{$name}));
                $extra_values->{$name} .= $append . $self->{output}->decode($self->{results}->{ $self->{extra_oids}->{$name}->{oid} }->{$_});
                $append = ',';
            }
        }
    }

    if (defined($self->{option_results}->{add_mac_address})) {
        my $macaddress = defined($options{result}->{$self->{oid_mac_address} . "." . $_}) ? unpack('H*', $options{result}->{$self->{oid_mac_address} . "." . $_}) : '';
        $macaddress =~ s/(..)(?=.)/$1:/g;
        $extra_values->{macaddress} = $macaddress;
    }

    return $extra_values;
}

sub disco_format {
    my ($self, %options) = @_;

    my $names = ['name', 'total', 'status', 'interfaceid'];
    if (scalar(keys %{$self->{extra_oids}}) > 0) {
        push @$names, keys %{$self->{extra_oids}};
    }
    if (defined($self->{option_results}->{add_mac_address})) {
        push @$names, 'macaddress';
    }
    push @$names, 'type' if (defined($self->{oid_iftype}));

    $self->{output}->add_disco_format(elements => $names);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection(disco => 1);
    return if (scalar(@{$self->{interface_id_selected}}) == 0);
    my $result = $self->get_additional_information();
    foreach (sort @{$self->{interface_id_selected}}) {
        my $display_value = $self->get_display_value(id => $_);
        
        my $interface_speed = 0;
        if ($self->{no_speed} == 0) {
            $interface_speed = (defined($result->{$oid_speed64 . "." . $_}) && $result->{$oid_speed64 . "." . $_} ne '' && $result->{$oid_speed64 . "." . $_} != 0) ? 
                                ($result->{$oid_speed64 . "." . $_}) : 
                                    (defined($result->{$oid_speed32 . "." . $_}) && $result->{$oid_speed32 . "." . $_} ne '' && $result->{$oid_speed32 . "." . $_} != 0 ?
                                        (sprintf("%g", $result->{$oid_speed32 . "." . $_} / 1000 / 1000)) : '');
        }
        if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
            $interface_speed = $self->{option_results}->{speed};
        }
        next if (defined($self->{option_results}->{skip_speed0}) && $interface_speed == 0);
        next if (defined($self->{option_results}->{filter_status}) && defined($result->{$self->{oid_opstatus} . "." . $_}) && 
            $self->{oid_opstatus_mapping}->{$result->{$self->{oid_opstatus} . "." . $_}} !~ /$self->{option_results}->{filter_status}/i);
        next if ($self->is_admin_status_down(admin_status => $result->{$self->{oid_adminstatus} . "." . $_}));

        my $extra_values = $self->get_extra_values_by_instance(result => $result, instance => $_);
        if (defined($self->{oid_iftype})) {
            $extra_values->{type} = $map_iftype->{ $result->{ $self->{oid_iftype} . '.' . $_ } };
        }
        $self->{output}->add_disco_entry(
            name => $display_value,
            total => $interface_speed,
            status => defined($result->{$self->{oid_opstatus} . "." . $_}) ? $self->{oid_opstatus_mapping}->{$result->{$self->{oid_opstatus} . "." . $_}} : '',
            interfaceid => $_,
            %$extra_values
        );
    }
}

1;

__END__

=head1 MODE

=over 8

=item B<--interface>

Set the interface (number expected) ex: 1,2,... (empty means 'check all interface').

=item B<--name>

Allows to use interface name with option --interface instead of interface oid index (Can be a regexp)

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

=item B<--add-extra-oid>

Display an OID.
Example: --add-extra-oid='alias,.1.3.6.1.2.1.31.1.1.1.18'
or --add-extra-oid='vlan,.1.3.6.1.2.1.31.19,%{instance}\..*'

=item B<--add-mac-address>

Display interface mac address.

=back

=cut
