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

package hardware::telephony::avaya::cm::snmp::mode::trunks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_sig_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        "state: %s [far node: %s]",
        $self->{result_values}->{state},
        $self->{result_values}->{far_node}
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'sig', type => 1, cb_prefix_output => 'prefix_sig_output', message_multiple => 'All signaling groups are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{sig} = [
        { label => 'sig-status', threshold => 0, set => {
                key_values => [ { name => 'state' }, { name => 'far_node' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_sig_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_sig_output {
    my ($self, %options) = @_;

    return "Signaling group '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-sigid:s'        => { name => 'filter_sigid' },
        'unknown-sig-status:s'  => { name => 'unknown_sig_status', default => '' },
        'warning-sig-status:s'  => { name => 'warning_sig_status', default => '' },
        'critical-sig-status:s' => { name => 'critical_sig_status', default => '%{state} =~ /out-of-service/' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'unknown_sig_status', 'warning_sig_status', 'critical_sig_status',
    ]);
}

my $mapping = {
    avCmListSigGrpFarNode    => { oid => '.1.3.6.1.4.1.6889.2.73.8.1.84.1.1.12' },
    avCmStatusSigGrpGrpState => { oid => '.1.3.6.1.4.1.6889.2.73.8.1.85.1.1.4' },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{sig} = {};
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping->{avCmListSigGrpFarNode}->{oid} },
            { oid => $mapping->{avCmStatusSigGrpGrpState}->{oid} },
        ],
        return_type => 1,
        nothing_quit => 1
    );

    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{avCmStatusSigGrpGrpState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_sigid}) && $self->{option_results}->{filter_sigid} ne '' &&
            $instance !~ /$self->{option_results}->{filter_sigid}/) {
            $self->{output}->output_add(long_msg => "skipping signaling group '" . $instance . "': no matching filter.", debug => 1);
            next;
        }

        $self->{sig}->{$instance} = {
            display => $instance,
            state => $result->{avCmStatusSigGrpGrpState},
            far_node => defined($result->{avCmListSigGrpFarNode}) && $result->{avCmListSigGrpFarNode} ne '' ? $result->{avCmListSigGrpFarNode} : '-',
        };
    }
}

1;

__END__

=head1 MODE

Check trunks.

=over 8

=item B<--filter-sigid>

Filter signaling group instance (can be a regexp).

=item B<--unknown-sig-status>

Set unknown threshold for status.
Can used special variables like: %{state}, %{far_node}, %{display}

=item B<--warning-sig-status>

Set warning threshold for status.
Can used special variables like: %{state}, %{far_node}, %{display}

=item B<--critical-sig-status>

Set critical threshold for status (Default: '%{state} =~ /out-of-service/').
Can used special variables like: %{state}, %{far_node}, %{display}

=back

=cut
    
