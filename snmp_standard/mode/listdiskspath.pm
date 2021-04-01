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
    
    $options{options}->add_options(arguments => { 
        'diskpath:s'              => { name => 'diskpath' },
        'name'                    => { name => 'use_name' },
        'regexp'                  => { name => 'use_regexp' },
        'regexp-isensitive'       => { name => 'use_regexpi' },
        'display-transform-src:s' => { name => 'display_transform_src' },
        'display-transform-dst:s' => { name => 'display_transform_dst' },
        'skip-total-size-zero'    => { name => 'skip_total_size_zero' }
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
        $self->{datas}->{'dskPath_' . $1} = $self->{output}->decode($result->{$key});
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
        
        if (scalar(@{$self->{diskpath_id_selected}}) <= 0 && !defined($options{disco})) {
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
    $self->{snmp} = $options{snmp};

    $self->manage_selection(disco => 1);
    return if (scalar(@{$self->{diskpath_id_selected}}) == 0);
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
