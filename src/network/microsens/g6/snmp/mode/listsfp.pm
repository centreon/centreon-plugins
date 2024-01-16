#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::microsens::g6::snmp::mode::listsfp;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $map_status = {
    0 => 'ok', 1 => 'laserDisabled', 2 => 'lossOfSignal',
    3 => 'txFailure', 4 => 'readError'
};
my $map_type = {
    0 => 'empty', 1 => 'unknown', 2 => 'sfp',
    3 => 'gbic', 4 => 'sff', 5 => 'dwdmSfp',
    7 => 'xfp', 8 => 'csfpA', 9 => 'csfpB',
    10 => 'dwdmXfp', 11 => 'sfpPlus'
};
my $mapping = {
    port     => { oid => '.1.3.6.1.4.1.3181.10.6.1.34.100.1.2' }, # informationPort
    location => { oid => '.1.3.6.1.4.1.3181.10.6.1.34.100.1.3' }, # informationLocation
    status   => { oid => '.1.3.6.1.4.1.3181.10.6.1.34.100.1.4', map => $map_status }, # informationLocation
    type     => { oid => '.1.3.6.1.4.1.3181.10.6.1.34.100.1.5', map => $map_type } # informationLocation
};
my $oid_sfp_entry = '.1.3.6.1.4.1.3181.10.6.1.34.100.1'; # informationEntry

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_sfp_entry,
        start => $mapping->{port}->{oid},
        end => $mapping->{type}->{oid}
    );

    my $ports = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{port}->{oid}\.(.*)$/);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);
        $ports->{$1} = $result;
    }

    return $ports;
}

sub run {
    my ($self, %options) = @_;
  
    my $ports = $self->manage_selection(%options);
    foreach (sort keys %$ports) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[port: %s] [location: %s] [status: %s] [type: %s]',
                $ports->{$_}->{port},
                $ports->{$_}->{location},
                $ports->{$_}->{status},
                $ports->{$_}->{type}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List sfp ports:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [keys %$mapping]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $ports = $self->manage_selection(%options);
    foreach (sort keys %$ports) { 
        $self->{output}->add_disco_entry(
            %{$ports->{$_}}
        );
    }
}

1;

__END__

=head1 MODE

List sfp ports.

=over 8

=back

=cut
    
