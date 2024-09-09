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

package storage::emc::DataDomain::snmp::mode::listreplications;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use storage::emc::DataDomain::snmp::lib::functions;

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

my $oid_fileSystemSpaceEntry = '.1.3.6.1.4.1.19746.1.3.2.1.1';
my $oid_sysDescr = '.1.3.6.1.2.1.1.1.0'; # 'Data Domain OS 5.4.1.1-411752'
my ($oid_fileSystemResourceName, $oid_fileSystemSpaceUsed, $oid_fileSystemSpaceAvail);

my @mapping = ('index', 'type', 'source', 'destination', 'state', 'status', 'initiator');

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_sysName = '.1.3.6.1.2.1.1.5.0';
    my $oid_sysDescr = '.1.3.6.1.2.1.1.1.0'; # 'Data Domain OS 5.4.1.1-411752'
    my $oid_replicationInfoEntry = '.1.3.6.1.4.1.19746.1.8.1.1.1';

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ $oid_sysDescr, $oid_sysName ],
        nothing_quit => 1
    );

    if (!($self->{os_version} = storage::emc::DataDomain::snmp::lib::functions::get_version(value => $snmp_result->{$oid_sysDescr}))) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'Cannot get DataDomain OS version.'
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    my $sysname = $snmp_result->{$oid_sysName};

    $snmp_result = $options{snmp}->get_table(
        oid => $oid_replicationInfoEntry,
        nothing_quit => 1
    );

    my ($oid_replSource, $oid_replDestination, $oid_replState, $oid_replStatus);
    my %map_state = (
        1 => 'enabled', 2 => 'disabled', 3 => 'disabledNeedsResync',
    );
    my %map_status = (
        1 => 'connected', 2 => 'disconnected', 3 => 'migrating',
        4 => 'suspended', 5 => 'neverConnected', 6 => 'idle'
    );
    if (centreon::plugins::misc::minimal_version($self->{os_version}, '5.4')) {
        %map_state = (
            1 => 'initializing', 2 => 'normal', 3 => 'recovering', 4 => 'uninitialized',
        );
        $oid_replSource = '.1.3.6.1.4.1.19746.1.8.1.1.1.7';
        $oid_replDestination = '.1.3.6.1.4.1.19746.1.8.1.1.1.8';
        $oid_replStatus = '.1.3.6.1.4.1.19746.1.8.1.1.1.4';
        $oid_replState = '.1.3.6.1.4.1.19746.1.8.1.1.1.3';
    } elsif (centreon::plugins::misc::minimal_version($self->{os_version}, '5.0')) {
        $oid_replSource = '.1.3.6.1.4.1.19746.1.8.1.1.1.7';
        $oid_replDestination = '.1.3.6.1.4.1.19746.1.8.1.1.1.8';
        $oid_replStatus = '.1.3.6.1.4.1.19746.1.8.1.1.1.4';
        $oid_replState = '.1.3.6.1.4.1.19746.1.8.1.1.1.3';
    } else {
        $oid_replSource = '.1.3.6.1.4.1.19746.1.8.1.1.1.6';
        $oid_replDestination = '.1.3.6.1.4.1.19746.1.8.1.1.1.7';
        $oid_replStatus = '.1.3.6.1.4.1.19746.1.8.1.1.1.3';
        $oid_replState = '.1.3.6.1.4.1.19746.1.8.1.1.1.2';
    }

    my $mapping = {
        replState                 => { oid => $oid_replState, map => \%map_state },
        replStatus                => { oid => $oid_replStatus, map => \%map_status },
        replSource                => { oid => $oid_replSource },
        replDestination           => { oid => $oid_replDestination }
    };

    my $results = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{replState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $result->{replSource} =~ /^(.*?):\/\//;
        my $type = $1;

        $result->{replSource} =~ s/^(.*?):\/\///;
        $result->{replDestination} =~ s/^(.*?):\/\///;

        # /data/col1/ is always present (useless information)
        $result->{replSource} =~ s/\/data\/col1//;
        $result->{replDestination} =~ s/\/data\/col1//;

        my $initiator = 0;
        $initiator = 1 if ($result->{replSource} =~ /^$sysname/);

        $results->{$instance} = {
            index => $instance,
            type => $type,
            source => $result->{replSource},
            destination => $result->{replDestination},
            state => $result->{replState},
            status => $result->{replStatus},
            initiator => $initiator
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $name (sort keys %$results) {
        $self->{output}->output_add(long_msg => 
            join('', map("[$_ = " . $results->{$name}->{$_} . ']', @mapping))
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List replications:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [@mapping]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach (sort keys %$results) {        
        $self->{output}->add_disco_entry(
            %{$results->{$_}}
        );
    }
}

1;

__END__

=head1 MODE

List replications.

=over 8

=back

=cut
