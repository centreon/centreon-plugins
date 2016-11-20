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

package storage::netapp::snmp::mode::listfilesys;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_dfFileSys = '.1.3.6.1.4.1.789.1.5.4.1.2';
my $oid_dfType = '.1.3.6.1.4.1.789.1.5.4.1.23';
my $oid_dfKBytesTotal = '.1.3.6.1.4.1.789.1.5.4.1.3';
my $oid_df64TotalKBytes = '.1.3.6.1.4.1.789.1.5.4.1.29';

my %map_types = (
    1 => 'traditionalVolume',
    2 => 'flexibleVolume',
    3 => 'aggregate',
    4 => 'stripedAggregate',
    5 => 'stripedVolume'
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "name:s"                => { name => 'name' },
                                  "regexp"                => { name => 'use_regexp' },
                                  "type:s"                => { name => 'type' },
                                  "skip-total-zero"       => { name => 'skip_total_zero' },
                                });
    $self->{filesys_id_selected} = [];

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{result_names} = $self->{snmp}->get_table(oid => $oid_dfFileSys, nothing_quit => 1);
    $self->{result_types} = $self->{snmp}->get_table(oid => $oid_dfType, nothing_quit => 1);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{result_names}})) {
        next if ($oid !~ /\.([0-9]+)$/);
        my $instance = $1;
        my $type = $map_types{$self->{result_types}->{$oid_dfType . '.' . $instance}};
        
        # Get all without a name
        if (!defined($self->{option_results}->{name})) {
            push @{$self->{filesys_id_selected}}, $instance; 
            next;
        }
        
        if (defined($self->{option_results}->{type}) && $type !~ /$self->{option_results}->{type}/i) {
            $self->{output}->output_add(long_msg => "Skipping filesys '" . $self->{result_names}->{$oid} . "': no matching filter type");
            next;
        }

        if (!defined($self->{option_results}->{use_regexp}) && $self->{result_names}->{$oid} ne $self->{option_results}->{name}) {
            $self->{output}->output_add(long_msg => "Skipping filesys '" . $self->{result_names}->{$oid} . "': no matching filter name");
            next;
        }
        if (defined($self->{option_results}->{use_regexp}) && $self->{result_names}->{$oid} !~ /$self->{option_results}->{name}/) {
            $self->{output}->output_add(long_msg => "Skipping filesys '" . $self->{result_names}->{$oid} . "': no matching filter name (regexp)");
            next;
        }
        
        push @{$self->{filesys_id_selected}}, $instance;
    }
}

sub get_additional_information {
    my ($self, %options) = @_;

    return if (scalar(@{$self->{filesys_id_selected}}) <= 0);
    $self->{snmp}->load(oids => [$oid_dfKBytesTotal], instances => $self->{filesys_id_selected});
    if (!$self->{snmp}->is_snmpv1()) {
        $self->{snmp}->load(oids => [$oid_df64TotalKBytes], instances => $self->{filesys_id_selected});
    }    
    return $self->{snmp}->get_leef();
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    my $result = $self->get_additional_information();

    foreach my $instance (sort @{$self->{filesys_id_selected}}) { 
        my $name = $self->{result_names}->{$oid_dfFileSys . '.' . $instance};
        my $type = $self->{result_types}->{$oid_dfType . '.' . $instance};
        my $total_size = $result->{$oid_dfKBytesTotal . '.' . $instance} * 1024;
        if (defined($result->{$oid_df64TotalKBytes . '.' . $instance}) && $result->{$oid_df64TotalKBytes . '.' . $instance} != 0) {
            $total_size = $result->{$oid_df64TotalKBytes . '.' . $instance} * 1024;
        }
        if (defined($self->{option_results}->{skip_total_zero}) && $total_size == 0) {
            $self->{output}->output_add(long_msg => "Skipping filesys '" . $name . "': total size is 0 and option --skip-total-zero is set");
            next;
        }

        $self->{output}->output_add(long_msg => "'" . $name . "' [total_size = $total_size B] [type = " . $map_types{$type} . "]");
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List filesys:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'total', 'type']);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    my $result = $self->get_additional_information();
    foreach my $instance (sort @{$self->{filesys_id_selected}}) {        
        my $name = $self->{result_names}->{$oid_dfFileSys . '.' . $instance};
        my $type = $self->{result_types}->{$oid_dfType . '.' . $instance};
        my $total_size = $result->{$oid_dfKBytesTotal . '.' . $instance} * 1024;
        if (defined($result->{$oid_df64TotalKBytes . '.' . $instance}) && $result->{$oid_df64TotalKBytes . '.' . $instance} != 0) {
            $total_size = $result->{$oid_df64TotalKBytes . '.' . $instance} * 1024;
        }
        next if (defined($self->{option_results}->{skip_total_zero}) && $total_size == 0);
        
        $self->{output}->add_disco_entry(name => $name,
                                         total => $total_size,
                                         type => $map_types{$type});
    }
}

1;

__END__

=head1 MODE

List filesystems (volumes and aggregates also).

=over 8

=item B<--name>

Set the filesystem name.

=item B<--regexp>

Allows to use regexp to filter filesystem name (with option --name).

=item B<--type>

Filter filesystem type (a regexp. Example: 'flexibleVolume|aggregate').

=item B<--skip-total-zero>

Don't display filesys with total equals 0.

=back

=cut
    