#
# Copyright 2022 Centreon (http://www.centreon.com/)
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
# Authors : Roman Morandell - i-Vertix
#

package network::raisecom::pon::snmp::mode::listprocesses;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'   => { name => 'filter_name' },
        'filter-status:s' => { name => 'filter_status' }
    });

    $self->{order} = [ 'name', 'pid', 'status' ];
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my %map_status = (
    0 => 'ready',
    1 => 'suspend',
    2 => 'pend',
    3 => 'pend_s',
    4 => 'delay',
    5 => 'delay_s',
    6 => 'pend_t',
    7 => 'pend_t_s',
    8 => 'dead'
);

my $mapping = {
    name   => { oid => '.1.3.6.1.4.1.8886.18.1.7.2.2.1.3' },                      # rcRunProcessName
    pid    => { oid => '.1.3.6.1.4.1.8886.18.1.7.2.2.1.2' },                      #  rcRunProcessPID
    status => { oid => '.1.3.6.1.4.1.8886.18.1.7.2.2.1.9', map => \%map_status }, #  rcRunProcessStatus
};


sub manage_selection {
    my ($self, %options) = @_;

    my $oid_hrSWRunEntry = '.1.3.6.1.4.1.8886.18.1.7.2.2.1';
    my $snmp_result = $options{snmp}->get_table(
        oid          => $oid_hrSWRunEntry,
        start        => $mapping->{pid}->{oid},
        end          => $mapping->{status}->{oid},
        nothing_quit => 1
    );
    my $results = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*?)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $result->{name} . "': no matching name filter.",
                debug    => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_status}/) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $result->{name} . "': no matching status filter.",
                debug    => 1);
            next;
        }

        $results->{$instance} = { %$result };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach (values %$results) {
        my $entry = '';
        foreach my $label (@{$self->{order}}) {
            $entry .= '[' . $label . ' = ' . $_->{$label} . '] ';
        }
        $self->{output}->output_add(long_msg => $entry);
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'List processes:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => $self->{order});
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach (values %$results) {
        $self->{output}->add_disco_entry(%$_);
    }
}

1;

__END__


=head1 MODE

List processes.

=over 8

=item B<--filter-name>

Filter by service name (can be a regexp).

=back

=cut