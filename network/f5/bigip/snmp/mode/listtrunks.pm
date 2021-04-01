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

package network::f5::bigip::snmp::mode::listtrunks;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $map_trunk_status = {
    0 => 'up',
    1 => 'down',
    2 => 'disable',
    3 => 'uninitialized',
    4 => 'loopback',
    5 => 'unpopulated'
};

my $mapping = {
    sysTrunkName   => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.1.2.1.1' },
    sysTrunkStatus => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.1.2.1.2', map => $map_trunk_status },
    sysTrunkOperBw => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.1.2.1.5' }
};
my $oid_sysTrunkTable = '.1.3.6.1.4.1.3375.2.1.2.12.1.2';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_sysTrunkTable,
        end => $mapping->{sysTrunkOperBw}->{oid},
        nothing_quit => 1
    );
    my $trunks = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{sysTrunkName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{sysTrunkName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping trunk '" . $result->{sysTrunkName} . "': no matching filter name.", debug => 1);
            next;
        }

        $trunks->{$result->{sysTrunkName}} = $result;
    }

    return $trunks;
}

sub run {
    my ($self, %options) = @_;

    my $trunks = $self->manage_selection(snmp => $options{snmp});
    foreach (sort keys %$trunks) {
        $self->{output}->output_add( 
            long_msg => sprintf(
                "'%s' [status: %s] [speed: %s]",
                $_,
                $trunks->{$_}->{sysTrunkStatus},
                $trunks->{$_}->{sysTrunkOperBw}
            )
        );
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List trunks:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'status', 'speed']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $trunks = $self->manage_selection(snmp => $options{snmp});
    foreach (sort keys %$trunks) {        
        $self->{output}->add_disco_entry(
            name => $_,
            status => $trunks->{$_}->{sysTrunkStatus},
            speed => $trunks->{$_}->{sysTrunkOperBw}
        );
    }
}

1;

__END__

=head1 MODE

List Trunks.

=over 8

=item B<--filter-name>

Filter by trunk name (regexp can be used).

=back

=cut
    
