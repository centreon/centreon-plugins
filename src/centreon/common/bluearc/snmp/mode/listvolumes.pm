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

package centreon::common::bluearc::snmp::mode::listvolumes;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $map_volume_status = {
    1 => 'unformatted',
    2 => 'mounted',
    3 => 'formatted',
    4 => 'needsChecking'
};
my $mapping = {
    label   => { oid => '.1.3.6.1.4.1.11096.6.1.1.1.3.5.2.1.3' }, # volumeLabel
    status  => { oid => '.1.3.6.1.4.1.11096.6.1.1.1.3.5.2.1.4', map => $map_volume_status }  # volumeStatus 
};
my $oid_volumeEntry = '.1.3.6.1.4.1.11096.6.1.1.1.3.5.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_volumeEntry,
        start => $mapping->{label}->{oid},
        end => $mapping->{status}->{oid}
    );

    my $volumes = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{label}->{oid}\.(.*)$/);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);
        $volumes->{$1} = $result;
    }

    return $volumes;
}

sub run {
    my ($self, %options) = @_;
  
    my $volumes = $self->manage_selection(%options);
    foreach (sort keys %$volumes) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[label: %s] [status: %s]',
                $volumes->{$_}->{label},
                $volumes->{$_}->{status}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List volumes:'
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

    my $volumes = $self->manage_selection(%options);
    foreach (sort keys %$volumes) { 
        $self->{output}->add_disco_entry(
            %{$volumes->{$_}}
        );
    }
}

1;

__END__

=head1 MODE

List volumes.

=over 8

=back

=cut
