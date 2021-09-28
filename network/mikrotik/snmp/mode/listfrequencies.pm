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

package network::mikrotik::snmp::mode::listfrequencies;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'oid-filter:s'  => { name => 'oid_filter', default => 'ifname' },
        'oid-display:s' => { name => 'oid_display', default => 'ifname' }
    });

    $self->{oids_label} = {
        'ifdesc' => '.1.3.6.1.2.1.2.2.1.2',
        'ifalias' => '.1.3.6.1.2.1.31.1.1.1.18',
        'ifname' => '.1.3.6.1.2.1.31.1.1.1.1'
    };
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    
    my $oids = [{ oid => $self->{oids_label}->{'ifname'} }];
    $self->{snmp} = $options{snmp};
    my $interfaceTables = $self->{snmp}->get_multiple_table(oids => $oids);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$interfaceTables->{ $self->{oids_label}->{'ifname'} }})) {
        next if ($key !~ /^$self->{oids_label}->{'ifname'}\.(.*)$/);
        $self->{datas}->{'ifname' . "_" . $1} = $self->{output}->decode($interfaceTables->{$self->{oids_label}->{'ifname'} }->{$key});
        push @{$self->{datas}->{all_ids}}, $1;
    }
    
    if (scalar(@{$self->{datas}->{all_ids}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't get interfaces...");
        $self->{output}->option_exit();
    }


    if (scalar(@{$self->{datas}->{all_ids}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found");
        $self->{output}->option_exit();
    }
    
    my $mktFrequenOid = '.1.3.6.1.4.1.14988.1.1.1.3.1.7.';

    foreach (sort @{$self->{datas}->{all_ids}}) {
        my $display_value = $self->get_display_value(id => $_);
        my $oid = $mktFrequenOid . $_;
        my $snmp_result = $options{snmp}->get_leef(oids => [$oid]);
        if(defined($snmp_result->{$oid})){
            $self->{output}->output_add(long_msg => $display_value . " : " . $snmp_result->{$oid} . " Mhz");
        }
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'Frequencies:'
    );

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub get_display_value {
    my ($self, %options) = @_;

    my $value = $self->{datas}->{"ifname_" . $options{id}};
    return $value;
}

1;

__END__

=head1 MODE

List frequencies for each interface.

=over 8

=cut
