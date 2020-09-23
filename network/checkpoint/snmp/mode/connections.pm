#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::checkpoint::snmp::mode::connections;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'warning:s'   => { name => 'warning' },
        'critical:s'  => { name => 'critical' },
        'units:s'     => { name => 'units', default => 'absolute' }
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
    
    if ($self->{option_results}->{units} !~ /^(absolute|%)$/i) {
        $self->{output}->add_option_msg(short_msg => "Wrong units option: absolute or %");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_fwNumCom = '.1.3.6.1.4.1.2620.1.1.25.3.0';
    my $oid_fwConnTableLimit = '.1.3.6.1.4.1.2620.1.1.25.10.0';
    my $result = $self->{snmp}->get_leef(oids => [$oid_fwNumCom, $oid_fwConnTableLimit], nothing_quit => 1);

    my $value = $result->{$oid_fwNumCom};
    my $extra = '';
    my %total_options = ();
    if (defined($result->{$oid_fwConnTableLimit}) && $result->{$oid_fwConnTableLimit} > 0) {
        my $prct_used = sprintf("%.2f", $result->{$oid_fwNumCom} * 100 / $result->{$oid_fwConnTableLimit});
        $extra = " (" . $prct_used . '% used on ' . $result->{$oid_fwConnTableLimit} . ")";
        if ($self->{option_results}->{units} eq '%') {
            $value = $prct_used;
            %total_options = ( total => $result->{$oid_fwConnTableLimit}, cast_int => 1);
        }
    } elsif ($self->{option_results}->{units} eq '%') {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => "Couldn't get fwConnTableLimit OID ($oid_fwConnTableLimit) to compute thresholds"
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    my $exit = $self->{perfdata}->threshold_check(value => $value, 
                                                  threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(
        severity => $exit,
        short_msg => sprintf("Connections: %d%s", $result->{$oid_fwNumCom}, $extra)
    );
    $self->{output}->perfdata_add(
        label => 'connections', unit => 'con',
        nlabel => 'connections.active.count',
        value => $result->{$oid_fwNumCom},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', %total_options),
        min => 0,
        max => (defined($result->{$oid_fwConnTableLimit}) && $result->{$oid_fwConnTableLimit} > 0) ? $result->{$oid_fwConnTableLimit} : undef
    );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check firewall number of connections (chkpnt.mib).

=over 8

=item B<--warning>

Number of connections trigerring a warning state

=item B<--critical>

Number of connections trigerring a criticalstate

=item B<--units>

Units of thresholds (Default: 'absolute') ('%', 'absolute').

=back

=cut
    
