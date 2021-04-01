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

package snmp_standard::mode::listspanningtrees;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-port:s' => { name => 'filter_port' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $mapping_state = {
    1 => 'disabled',
    2 => 'blocking',
    3 => 'listening',
    4 => 'learning',
    5 => 'forwarding',
    6 => 'broken',
    10 => 'not defined'
};
my $mapping_status = {
    1 => 'enabled',
    2 => 'disabled'
};

my $mapping = {
    dot1dStpPortState   => { oid => '.1.3.6.1.2.1.17.2.15.1.3', map => $mapping_state },
    dot1dStpPortEnable  => { oid => '.1.3.6.1.2.1.17.2.15.1.4', map => $mapping_status }
};
my $oid_dot1dStpPortEntry = '.1.3.6.1.2.1.17.2.15.1';

my $oid_dot1dBasePortIfIndex = '.1.3.6.1.2.1.17.1.4.1.2';

my $mapping_if_status = {
    1 => 'up', 2 => 'down', 3 => 'testing', 4 => 'unknown',
    5 => 'dormant', 6 => 'notPresent', 7 => 'lowerLayerDown',
    100 => 'notfound'
};
my $oid_ifDesc = '.1.3.6.1.2.1.2.2.1.2';
my $oid_ifAdminStatus = '.1.3.6.1.2.1.2.2.1.7';
my $oid_ifOpStatus = '.1.3.6.1.2.1.2.2.1.8';

sub manage_selection {
    my ($self, %options) = @_;

    my $results = {};
    my $snmp_results = $options{snmp}->get_table(oid => $oid_dot1dStpPortEntry, start => $mapping->{dot1dStpPortState}->{oid}, end => $mapping->{dot1dStpPortEnable}->{oid}, nothing_quit => 1);

    my @instances = ();
    foreach my $oid (keys %$snmp_results) {
        next if ($oid !~ /^$mapping->{dot1dStpPortState}->{oid}\.(.*)/);
        my $instance = $1;
        my $map_result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_results, instance => $instance);

        if ($map_result->{dot1dStpPortEnable} =~ /disabled/) {
            $self->{output}->output_add(long_msg => sprintf("skipping interface '%d': Stp port disabled", $instance), debug => 1);
            next;
        }
        push @instances, $instance;
    }

    $options{snmp}->load(oids => [ $oid_dot1dBasePortIfIndex ], instances => [ @instances ]);
    my $result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach my $oid (keys %{$result}) {
        next if ($oid !~ /^$oid_dot1dBasePortIfIndex\./ || !defined($result->{$oid}));
        $options{snmp}->load(oids => [ $oid_ifDesc . "." . $result->{$oid}, $oid_ifAdminStatus . "." . $result->{$oid}, $oid_ifOpStatus . "." . $result->{$oid} ]);
    }
    my $result_if = $options{snmp}->get_leef();

    foreach my $instance (@instances) {
        my $map_result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_results, instance => $instance);

        my $state = (defined($map_result->{dot1dStpPortState})) ? $map_result->{dot1dStpPortState} : 'not defined';
        my $description = (defined($result->{$oid_dot1dBasePortIfIndex . '.' . $instance}) && defined($result_if->{$oid_ifDesc . '.' . $result->{$oid_dot1dBasePortIfIndex . '.' . $instance}})) ?
            $result_if->{$oid_ifDesc . '.' . $result->{$oid_dot1dBasePortIfIndex . '.' . $instance}} : $instance . '.unknown';
        my $admin_status = (defined($result->{$oid_dot1dBasePortIfIndex . '.' . $instance}) && defined($result_if->{$oid_ifAdminStatus . '.' . $result->{$oid_dot1dBasePortIfIndex . '.' . $instance}})) ?
            $result_if->{$oid_ifAdminStatus . '.' . $result->{$oid_dot1dBasePortIfIndex . '.' . $instance}} : 100;
        my $op_status = (defined($result->{$oid_dot1dBasePortIfIndex . '.' . $instance}) && defined($result_if->{$oid_ifOpStatus . '.' . $result->{$oid_dot1dBasePortIfIndex . '.' . $instance}})) ?
            $result_if->{$oid_ifOpStatus . '.' . $result->{$oid_dot1dBasePortIfIndex . '.' . $instance}} : 100;

        if (defined($self->{option_results}->{filter_port}) && $self->{option_results}->{filter_port} ne '' &&
            $description !~ /$self->{option_results}->{filter_port}/) {
            $self->{output}->output_add(long_msg => sprintf("skipping interface '%s': filtered with options", $description), debug => 1);
            next;
        }

        $results->{$instance} = {
            state => $state,
            admin_status => $mapping_if_status->{$admin_status},
            op_status => $mapping_if_status->{$op_status},
            index => defined($result->{$oid_dot1dBasePortIfIndex . '.' . $instance}) ? $result->{$oid_dot1dBasePortIfIndex . '.' . $instance} : 'notfound',
            description => $description
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;
  
    my $results = $self->manage_selection(%options);
    foreach my $instance (sort keys %$results) { 
        $self->{output}->output_add(
            long_msg => sprintf(
                "[port = %s] [state = %s] [op_status = %s] [admin_status = %s] [index = %s]",
                $results->{$instance}->{description},
                $results->{$instance}->{state}, 
                $results->{$instance}->{op_status},
                $results->{$instance}->{admin_status},
                $results->{$instance}->{index}
            )
        );
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List ports with spanning tree protocol:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['port', 'state', 'op_status', 'admin_status', 'index']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach my $instance (sort keys %$results) {             
        $self->{output}->add_disco_entry(
            port => $results->{$instance}->{description},
            state => $results->{$instance}->{state},
            op_status => $results->{$instance}->{op_status},
            admin_status => $results->{$instance}->{admin_status},
            index => $results->{$instance}->{index}
        );
    }
}

1;

__END__

=head1 MODE

List ports using Spanning Tree Protocol.

=over 8

=item B<--filter-port>

Filter by port description (can be a regexp).

=back

=cut
    
