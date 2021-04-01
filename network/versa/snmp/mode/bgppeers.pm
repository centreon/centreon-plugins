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

package network::versa::snmp::mode::bgppeers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s [as: %s]',
        $self->{result_values}->{state},
        $self->{result_values}->{as}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'peers', type => 1, cb_prefix_output => 'prefix_peers_output', message_multiple => 'All BGP peers are ok' }
    ];

    $self->{maps_counters}->{peers} = [
        { label => 'status', threshold => 0, set => {
                key_values => [
                    { name => 'display' }, { name => 'local_addr' },
                    { name => 'remote_addr' }, { name => 'as' },
                    { name => 'state' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'update-last', nlabel => 'peer.update.last.seconds', set => {
                key_values => [ { name => 'last_update' }, { name => 'display' } ],
                output_template => 'last update: %s s',
                perfdatas => [
                    { template => '%s', unit => 's', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub prefix_peers_output {
    my ($self, %options) = @_;

    return "Peer '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-local-addr:s'  => { name => 'filter_local_addr' },
        'filter-remote-addr:s' => { name => 'filter_remote_addr' },
        'filter-as:s'          => { name => 'filter_as' },
        'unknown-status:s'     => { name => 'unknown_status', default => '' },
        'warning-status:s'     => { name => 'warning_status', default => '' },
        'critical-status:s'    => { name => 'critical_status', default => '%{state} !~ /established/' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

my $map_state = {
    1 => 'idle', 2 => 'connect', 3 => 'active',
    4 => 'opensent', 5 => 'openconfirm', 6 => 'established'
};

my $mapping = {
    bgpPeerStatusState             => { oid => '.1.2.826.42.1.1578918.5.65.1.3.1.4.1.10', map => $map_state },
    bgpPeerStatusInUpdatesElpsTime => { oid => '.1.2.826.42.1.1578918.5.65.1.3.1.4.1.22' }
};

sub manage_selection {
    my ($self, %options) = @_;

    # .1.2.826.42.1.1578918.5.65.1.3.1.4.1.9.rmEntIndex.localAddrType.LocalAddr        .LocalPort.remoteAddrType.remoteAddr     .remotePort.localScopeId
    # .1.2.826.42.1.1578918.5.65.1.3.1.4.1.9.1         .1            .4.114.136.48.101 .0        .1             .4.114.136.48.1 .0         .0 

    $self->{peers} = {};

    my $oid_bgpPeerStatusRemoteAs = '.1.2.826.42.1.1578918.5.65.1.3.1.4.1.15';
    my $snmp_result = $options{snmp}->get_table(oid => $oid_bgpPeerStatusRemoteAs, nothing_quit => 1);
    foreach my $oid (keys %$snmp_result) {
        $oid =~ /^$oid_bgpPeerStatusRemoteAs\.(.*)$/;
        my $instance = $1;
        my @datas = split /\./, $instance;

        my ($rm_ent_index, $local_addr_type) = (shift(@datas), shift(@datas));
        my $local_len = shift(@datas);
        my $local_addr = join('.', splice(@datas, 0, $local_len));
        $local_addr .= ':' . shift(@datas);

        my $remote_addr_type = shift(@datas);
        my $remote_len = shift(@datas);
        my $remote_addr = join('.', splice(@datas, 0, $remote_len));
        $remote_addr .= ':' . shift(@datas);

        my $remote_as = $snmp_result->{$oid};
        if (defined($self->{option_results}->{filter_local_addr}) && $self->{option_results}->{filter_local_addr} ne '' &&
            $local_addr !~ /$self->{option_results}->{filter_local_addr}/) {
            $self->{output}->output_add(long_msg => "skipping peer local address '" . $local_addr . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_remote_addr}) && $self->{option_results}->{filter_remote_addr} ne '' &&
            $remote_addr !~ /$self->{option_results}->{filter_remote_addr}/) {
            $self->{output}->output_add(long_msg => "skipping peer remote address '" . $remote_addr . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_as}) && $self->{option_results}->{filter_as} ne '' &&
            $remote_as !~ /$self->{option_results}->{filter_as}/) {
            $self->{output}->output_add(long_msg => "skipping AS '" . $remote_as . "': no matching filter.", debug => 1);
            next;
        }

        $self->{peers}->{$instance} = { 
            display => $local_addr . '-' . $remote_addr,
            local_addr => $local_addr,
            remote_addr => $remote_addr,
            as => $remote_as,
        };
    }

    return if (scalar(keys %{$self->{peers}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ keys %{$self->{peers}} ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$self->{peers}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);
        $self->{peers}->{$_}->{state} = $result->{bgpPeerStatusState};
        $self->{peers}->{$_}->{last_update} = $result->{bgpPeerStatusInUpdatesElpsTime};
    }

}

1;

__END__

=head1 MODE

Check BGP peers.

=over 8

=item B<--filter-as>

Filter based on AS number (regexp allowed)

=item B<--filter-local-addr>

Filter based on local IP:PORT of peers (regexp allowed)

=item B<--filter-remote-addr>

Filter based on remote IP:PORT of peers (regexp allowed)

=item B<--warning-updates>

Warning threshold on last update (seconds)

=item B<--critical-updates>

Critical threshold on last update (seconds)

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{local_addr}, %{remote_addr}, %{as}, %{state}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{local_addr}, %{remote_addr}, %{as}, %{state}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} !~ /established/').
Can used special variables like: %{local_addr}, %{remote_addr}, %{as}, %{state}, %{display}

=back

=cut
