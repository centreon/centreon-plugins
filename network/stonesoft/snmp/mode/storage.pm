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

package network::stonesoft::snmp::mode::storage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_fwMountPointName = '.1.3.6.1.4.1.1369.5.2.1.11.3.1.3';
my $oid_fwPartitionSize = '.1.3.6.1.4.1.1369.5.2.1.11.3.1.4'; # in kB
my $oid_fwPartitionUsed = '.1.3.6.1.4.1.1369.5.2.1.11.3.1.5'; # in kB

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning' },
                                  "critical:s"              => { name => 'critical' },
                                  "units:s"                 => { name => 'units', default => '%' },
                                  "free"                    => { name => 'free' },
                                  "storage:s"               => { name => 'storage' },
                                  "regexp"                  => { name => 'use_regexp' },
                                  "regexp-isensitive"       => { name => 'use_regexpi' },
                                });

    $self->{storage_id_selected} = [];
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }    
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    my $num_disk_check = 0;
    foreach (sort @{$self->{storage_id_selected}}) {
        my $name_storage = $self->get_display_value(id => $_);
        my $total_size = ($self->{results}->{$oid_fwPartitionSize}->{$oid_fwPartitionSize . "." . $_}) * 1024;
        if ($total_size == 0) {
            $self->{output}->output_add(long_msg => sprintf("Skipping partition '%s' (total size is 0)", $name_storage));
            next;
        }

        $num_disk_check++;
        my $total_used = ($self->{results}->{$oid_fwPartitionUsed}->{$oid_fwPartitionUsed . "." . $_}) * 1024;
        my $total_free = $total_size - $total_used;
        my $prct_used = $total_used * 100 / $total_size;
        my $prct_free = 100 - $prct_used;

        my ($exit, $threshold_value);

        $threshold_value = $total_used;
        $threshold_value = $total_free if (defined($self->{option_results}->{free}));
        if ($self->{option_results}->{units} eq '%') {
            $threshold_value = $prct_used;
            $threshold_value = $prct_free if (defined($self->{option_results}->{free}));
        } 
        $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

        my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $total_size);
        my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $total_used);
        my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => ($total_size - $total_used));

        $self->{output}->output_add(long_msg => sprintf("Partition '%s' Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)", $name_storage,
                                            $total_size_value . " " . $total_size_unit,
                                            $total_used_value . " " . $total_used_unit, $prct_used,
                                            $total_free_value . " " . $total_free_unit, $prct_free));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1) || (defined($self->{option_results}->{storage}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Partition '%s' Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)", $name_storage,
                                            $total_size_value . " " . $total_size_unit,
                                            $total_used_value . " " . $total_used_unit, $prct_used,
                                            $total_free_value . " " . $total_free_unit, $prct_free));
        }    

        my $label = 'used';
        my $value_perf = $total_used;
        if (defined($self->{option_results}->{free})) {
            $label = 'free';
            $value_perf = $total_free;
        }
        my $extra_label = '';
        $extra_label = '_' . $name_storage if (!defined($self->{option_results}->{storage}) || defined($self->{option_results}->{use_regexp}));
        my %total_options = ();
        if ($self->{option_results}->{units} eq '%') {
            $total_options{total} = $total_size;
            $total_options{cast_int} = 1; 
        }
        $self->{output}->perfdata_add(label => $label . $extra_label, unit => 'B',
                                      value => $value_perf,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', %total_options),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', %total_options),
                                      min => 0, max => $total_size);
    }

    if (!defined($self->{option_results}->{storage}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All partitions are ok.');
    } elsif ($num_disk_check == 0) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'No usage for partition.');
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                                { oid => $oid_fwMountPointName },
                                                                { oid => $oid_fwPartitionSize },
                                                                { oid => $oid_fwPartitionUsed }
                                                              ],
                                                              nothing_quit => 1);
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_fwMountPointName}})) {
        $key =~ /\.([0-9]+)$/;
        my $instance = $1;
        my $filter_name = $self->{output}->decode($self->{results}->{$oid_fwMountPointName}->{$key});
        next if (!defined($filter_name));
        if (!defined($self->{option_results}->{storage})) {
            push @{$self->{storage_id_selected}}, $instance; 
            next;
        }
        if (defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{storage}/i) {
            push @{$self->{storage_id_selected}}, $instance; 
        }
        if (defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name =~ /$self->{option_results}->{storage}/) {
            push @{$self->{storage_id_selected}}, $instance; 
        }
        if (!defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) && $filter_name eq $self->{option_results}->{storage}) {
            push @{$self->{storage_id_selected}}, $instance; 
        }
    }
        
    if (scalar(@{$self->{storage_id_selected}}) <= 0) {
        if (defined($self->{option_results}->{storage})) {
            $self->{output}->add_option_msg(short_msg => "No storage found for name '" . $self->{option_results}->{storage} . "'.");
        } else {
            $self->{output}->add_option_msg(short_msg => "No storage found.");
        }
        $self->{output}->option_exit();
    }
}

sub get_display_value {
    my ($self, %options) = @_;
    my $value = $self->{results}->{$oid_fwMountPointName}->{$oid_fwMountPointName . '.' . $options{id}};

    return $value;
}

1;

__END__

=head1 MODE

Check usage on partitions.

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--storage>

Set the storage name (empty means 'check all storage').

=item B<--regexp>

Allows to use regexp to filter storage.

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=back

=cut
