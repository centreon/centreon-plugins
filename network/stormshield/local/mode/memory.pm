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

package network::stormshield::snmp::mode::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Data::Dumper qw(Dumper);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "warning:s"       => { name => 'warning' },
        "critical:s"      => { name => 'critical' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_snsMem = '.1.3.6.1.4.1.11256.1.10.3.0'; # Stormshield Firewall memory left for in percent (host,frag,icmp,conn,ether_state,dtrack,dyn)

    my $result = $self->{snmp}->get_leef(
        oids => [$oid_snsMem],
        nothing_quit => 1
    );

    my @oid_values = split /,/, $result->{$oid_snsMem};

    my $snsMem_host = $oid_values[0];
    my $snsMem_frag = $oid_values[1];
    my $snsMem_icmp = $oid_values[2];
    my $snsMem_conn = $oid_values[3];
    my $snsMem_ether_state = 0;
    my $snsMem_dtrack = $oid_values[4];
    my $snsMem_dyn = $oid_values[5];

    if (@oid_values == 7){
        $snsMem_host = $oid_values[0];
        $snsMem_frag = $oid_values[1];
        $snsMem_icmp = $oid_values[2];
        $snsMem_conn = $oid_values[3];
        $snsMem_ether_state = $oid_values[4];
        $snsMem_dtrack = $oid_values[5];
        $snsMem_dyn = $oid_values[6];
    }

    my $sns_Total = $snsMem_host + $snsMem_frag + $snsMem_icmp + $snsMem_conn + $snsMem_ether_state + $snsMem_dtrack;

    my $exit = $self->{perfdata}->threshold_check(value => $sns_Total, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    $self->{output}->output_add(
        severity => $exit,
        short_msg => sprintf(
            "Total : %s%% (Host: %s%%, Frag: %s%%, ICMP: %s%%, Conn: %s%%, Ether_state: %s%%, Dtrack: %s%%), Dyn: %s%%",
                        $sns_Total,
                        $snsMem_host,
                        $snsMem_frag,
                        $snsMem_icmp,
                        $snsMem_conn,
                        $snsMem_ether_state,
                        $snsMem_dtrack,
                        $snsMem_dyn
        )
    );

    $self->{output}->perfdata_add(
        label => "host", nlabel => 'memory.host.percent', unit => '%',
        value => $snsMem_host,
        min => 0
    );
    $self->{output}->perfdata_add(
        label => "frag", nlabel => 'memory.frag.percent', unit => '%',
        value => $snsMem_frag,
        min => 0
    );
    $self->{output}->perfdata_add(
        label => "icmp", nlabel => 'memory.icmp.percent', unit => '%',
        value => $snsMem_icmp,
        min => 0
    );
    $self->{output}->perfdata_add(
        label => "conn", nlabel => 'memory.conn.percent', unit => '%',
        value => $snsMem_conn,
       min => 0
    );
    $self->{output}->perfdata_add(
        label => "ether_state", nlabel => 'memory.ether_state.percent', unit => '%',
        value => $snsMem_ether_state,
        min => 0
    );
    $self->{output}->perfdata_add(
        label => "dtrack", nlabel => 'memory.drack.percent', unit => '%',
        value => $snsMem_dtrack,
        min => 0
    );
    $self->{output}->perfdata_add(
        label => "dyn", nlabel => 'memory.dyn.percent', unit => '%',
        value => $snsMem_dyn,
        min => 0
    );

    $self->{output}->perfdata_add(
        label => "used", nlabel => 'memory.usage.percent', unit => '%',
        value => $sns_Total,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $sns_Total, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $sns_Total, cast_int => 1),
        min => 0, max => $sns_Total
    );
    $self->{output}->display();
    $self->{output}->exit();
  }
1;

__END__
=head1 MODE
Check stormshield memory.
=over 8
=item B<--warning>
Threshold warning in percent.
=item B<--critical>
Threshold critical in percent.
=back
=cut
