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

package network::f5::bigip::snmp::mode::listvirtualservers;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my %map_vs_status = (
    0 => 'none',
    1 => 'green',
    2 => 'yellow',
    3 => 'red',
    4 => 'blue', # unknown
    5 => 'gray',
);
my %map_vs_enabled = (
    0 => 'none',
    1 => 'enabled',
    2 => 'disabled',
    3 => 'disabledbyparent',
);
my $mapping = {
    new => {
        AvailState => { oid => '.1.3.6.1.4.1.3375.2.2.10.13.2.1.2', map => \%map_vs_status },
        EnabledState => { oid => '.1.3.6.1.4.1.3375.2.2.10.13.2.1.3', map => \%map_vs_enabled },
    },
    old => {
        AvailState => { oid => '.1.3.6.1.4.1.3375.2.2.10.1.2.1.22', map => \%map_vs_status },
        EnabledState => { oid => '.1.3.6.1.4.1.3375.2.2.10.1.2.1.23', map => \%map_vs_enabled },
    },
};
my $oid_ltmVsStatusEntry = '.1.3.6.1.4.1.3375.2.2.10.13.2.1'; # new
my $oid_ltmVirtualServEntry = '.1.3.6.1.4.1.3375.2.2.10.1.2.1'; # old

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_ltmVirtualServEntry, start => $mapping->{old}->{AvailState}->{oid}, end => $mapping->{old}->{EnabledState}->{oid} },
            { oid => $oid_ltmVsStatusEntry, start => $mapping->{new}->{AvailState}->{oid}, end => $mapping->{new}->{EnabledState}->{oid} },
        ],
        nothing_quit => 1
    );
    
    my ($branch, $map) = ($oid_ltmVsStatusEntry, 'new');
    if (!defined($snmp_result->{$oid_ltmVsStatusEntry}) || scalar(keys %{$snmp_result->{$oid_ltmVsStatusEntry}}) == 0)  {
        ($branch, $map) = ($oid_ltmVirtualServEntry, 'old');
    }
    
    my $results = {};
    foreach my $oid (keys %{$snmp_result->{$branch}}) {
        next if ($oid !~ /^$mapping->{$map}->{AvailState}->{oid}\.(.*?)\.(.*)$/);
        my ($num, $index) = ($1, $2);
        my $result = $options{snmp}->map_instance(mapping => $mapping->{$map}, results => $snmp_result->{$branch}, instance => $num . '.' . $index);

        my $name = $self->{output}->decode(join('', map(chr($_), split(/\./, $index))));        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping virtual server '" . $name . "'.", debug => 1);
            next;
        }
        
        $results->{$name} = {
            status => $result->{AvailState},
            state => $result->{EnabledState},
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $name (sort keys %$results) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[name: %s] [status: %s] [state: %s]',
                $name,
                $results->{$name}->{status},
                $results->{$name}->{state},
            )
        );
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List virtual servers:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'status', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $name (sort keys %$results) {
        $self->{output}->add_disco_entry(
            name => $name,
            status => $results->{$name}->{status},
            state => $results->{$name}->{state}
        );
    }
}

1;

__END__

=head1 MODE

List F-5 Virtual Servers.

=over 8

=item B<--filter-name>

Filter by virtual server name.

=back

=cut
    
