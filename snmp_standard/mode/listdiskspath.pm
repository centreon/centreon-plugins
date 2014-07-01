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

package snmp_standard::mode::listdiskspath;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_dskPath = '.1.3.6.1.4.1.2021.9.1.2';
my $oid_dskTotalLow = '.1.3.6.1.4.1.2021.9.1.11';
my $oid_dskTotalHigh = '.1.3.6.1.4.1.2021.9.1.12';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "diskpath:s"              => { name => 'diskpath' },
                                  "name"                    => { name => 'use_name' },
                                  "regexp"                  => { name => 'use_regexp' },
                                  "regexp-isensitive"       => { name => 'use_regexpi' },
                                  "display-transform-src:s" => { name => 'display_transform_src' },
                                  "display-transform-dst:s" => { name => 'display_transform_dst' },
                                  "skip-total-size-zero"    => { name => 'skip_total_size_zero' },
                                });

    $self->{diskpath_id_selected} = [];
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    my $result = $self->get_additional_information();

    foreach (sort @{$self->{diskpath_id_selected}}) {
        my $display_value = $self->get_display_value(id => $_);
        
        if (defined($result)) {
            my $total_size = (($result->{$oid_dskTotalHigh . "." . $_} << 32) + $result->{$oid_dskTotalLow . "." . $_});
            if ($total_size == 0) {
                $self->{output}->output_add(long_msg => "Skipping disk path '" . $display_value . "': size is 0");
                next;
            }
        }

        $self->{output}->output_add(long_msg => "'" . $display_value . "' [id = " . $_ . ']');
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List disk path:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub get_additional_information {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{skip_total_size_zero})) {
        return undef;
    }
    my $oids = [$oid_dskTotalLow, $oid_dskTotalHigh];
    
    $self->{snmp}->load(oids => $oids, instances => $self->{diskpath_id_selected});
    return $self->{snmp}->get_leef();
}

sub get_display_value {
    my ($self, %options) = @_;
    my $value = $self->{datas}->{'dskPath_' . $options{id}};

    if (defined($self->{option_results}->{display_transform_src})) {
        $self->{option_results}->{display_transform_dst} = '' if (!defined($self->{option_results}->{display_transform_dst}));
        eval "\$value =~ s{$self->{option_results}->{display_transform_src}}{$self->{option_results}->{display_transform_dst}}";
    }
    return $value;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{datas} = {};
    my $result = $self->{snmp}->get_table(oid => $oid_dskPath);
    my $total_diskpath = 0;
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /\.([0-9]+)$/);
        $self->{datas}->{'dskPath_' . $1} = $self->{output}->to_utf8($result->{$key});
        $total_diskpath = $1;
    }
    
    if (scalar(keys %{$self->{datas}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't get disks path...");
        $self->{output}->option_exit();
    }
    
    if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{diskpath})) {
        # get by ID
        push @{$self->{diskpath_id_selected}}, $self->{option_results}->{diskpath}; 
        my $name = $self->{datas}->{'dskPath_' . $self->{option_results}->{diskpath}};
        if (!defined($name)) {
            $self->{output}->add_option_msg(short_msg => "No disk path found for id '" . $self->{option_results}->{diskpath} . "'.");
            $self->{output}->option_exit();
        }
    } else {
        for (my $i = 0; $i <= $total_diskpath; $i++) {
            my $filter_name = $self->{datas}->{'dskPath_' . $i};
            next if (!defined($filter_name));
            if (!defined($self->{option_results}->{diskpath})) {
                push @{$self->{diskpath_id_selected}}, $i; 
                next;
            }
            if (defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{diskpath}/i) {
                push @{$self->{diskpath_id_selected}}, $i; 
            }
            if (defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{diskpath}/) {
                push @{$self->{diskpath_id_selected}}, $i; 
            }
            if (!defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name eq $self->{option_results}->{diskpath}) {
                push @{$self->{diskpath_id_selected}}, $i; 
            }
        }
        
        if (scalar(@{$self->{diskpath_id_selected}}) <= 0) {
            if (defined($self->{option_results}->{diskpath})) {
                $self->{output}->add_option_msg(short_msg => "No disk path found for name '" . $self->{option_results}->{diskpath} . "'.");
            } else {
                $self->{output}->add_option_msg(short_msg => "No disk path found.");
            }
            $self->{output}->option_exit();
        }
    }
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'diskpathid']);
}

sub disco_show {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    my $result = $self->get_additional_information();
    foreach (sort @{$self->{diskpath_id_selected}}) {
        if (defined($result)) {
            my $total_size = (($result->{$oid_dskTotalHigh . "." . $_} << 32) + $result->{$oid_dskTotalLow . "." . $_});
            next if ($total_size == 0);
        }
        my $display_value = $self->get_display_value(id => $_);

        $self->{output}->add_disco_entry(name => $display_value,
                                         diskpathid => $_);
    }
}

1;

__END__

=head1 MODE

List disk path (UCD-SNMP-MIB).
Need to enable "includeAllDisks 10%" on snmpd.conf.

=over 8

=item B<--diskpath>

Set the disk path (number expected) ex: 1, 2,... (empty means 'check all disks path').

=item B<--name>

Allows to use disk path name with option --diskpath instead of disk path oid index.

=item B<--regexp>

Allows to use regexp to filter diskpath (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=item B<--display-transform-src>

Regexp src to transform display value. (security risk!!!)

=item B<--display-transform-dst>

Regexp dst to transform display value. (security risk!!!)

=item B<--skip-total-size-zero>

Filter partitions with total size equals 0.

=back

=cut
