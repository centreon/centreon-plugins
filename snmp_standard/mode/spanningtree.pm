#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package snmp_standard::mode::spanningtree;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my $instance_mode;

sub custom_status_threshold {
    my ($self, %options) = @_;
    my $status = 'ok';
    my $message;
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        if (defined($instance_mode->{option_results}->{critical_status}) && $instance_mode->{option_results}->{critical_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) && $instance_mode->{option_results}->{warning_status} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = " spanning tree state is '" . $self->{result_values}->{state} . "' [index: '" . $self->{result_values}->{index} . "']";

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{port} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{index} = $options{new_datas}->{$self->{instance} . '_index'};


    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'stp_port', type => 1, cb_prefix_output => 'prefix_peers_output', message_multiple => 'Spanning tree is OK' },
    ];
    $self->{maps_counters}->{stp_port} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'state' }, { name => 'index' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
    ];
}

sub prefix_peers_output {
    my ($self, %options) = @_;

    return "Port: '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "filter-port:s"         => { name => 'filter_port' },
                                "warning-status:s"      => { name => 'warning_status', default => '' },
                                "critical-status:s"     => { name => 'critical_status', default => '%{state} =~ /blocking|broken/' },
                                });

    return $self;
}

sub change_macros {
    my ($self, %options) = @_;

    foreach (('warning_status', 'critical_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $instance_mode = $self;
    $self->change_macros();
}


my %states = (
    1 => 'disabled',
    2 => 'blocking',
    3 => 'listening',
    4 => 'learning',
    5 => 'forwarding',
    6 => 'broken',
    10 => 'not defined'
);

sub manage_selection {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    $self->{stp_port} = {};

    my $oid_dot1dStpPortEnable = '.1.3.6.1.2.1.17.2.15.1.4';
    my $oid_dot1dStpPortState = '.1.3.6.1.2.1.17.2.15.1.3';
    my $oid_dot1dBasePortIfIndex = '.1.3.6.1.2.1.17.1.4.1.2';
    my $oid_ifDesc = '.1.3.6.1.2.1.2.2.1.2';
    my $results = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_dot1dStpPortEnable },
                                                            { oid => $oid_dot1dStpPortState },
                                                           ], nothing_quit => 1);
    my @instances = ();
    foreach my $oid (keys %{$results->{$oid_dot1dStpPortEnable}}) {
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;

        # '2' => disabled, we skip
        if ($results->{$oid_dot1dStpPortEnable}->{$oid} == 2) {
            $self->{output}->output_add(long_msg => sprintf("Skipping interface '%d': Stp port disabled", $instance));
            next;
        }

        push @instances, $instance;

    }

    $self->{snmp}->load(oids => [$oid_dot1dBasePortIfIndex],
                            instances => [@instances]);
    my $result = $self->{snmp}->get_leef(nothing_quit => 1);

    # Get description
    foreach my $oid (keys %$result) {
        next if ($oid !~ /^$oid_dot1dBasePortIfIndex\./ || !defined($result->{$oid}));

        $self->{snmp}->load(oids => [$oid_ifDesc . "." . $result->{$oid}]);
    }
    my $result_desc = $self->{snmp}->get_leef();

    foreach my $instance (@instances) {
        my $stp_state = defined($results->{$oid_dot1dStpPortState}->{$oid_dot1dStpPortState . '.' . $instance}) ?
                          $results->{$oid_dot1dStpPortState}->{$oid_dot1dStpPortState . '.' . $instance} : 10;
        my $descr = (defined($result->{$oid_dot1dBasePortIfIndex . '.' . $instance}) && defined($result_desc->{$oid_ifDesc . '.' . $result->{$oid_dot1dBasePortIfIndex . '.' . $instance}})) ?
                        $result_desc->{$oid_ifDesc . '.' . $result->{$oid_dot1dBasePortIfIndex . '.' . $instance}} : 'unknown';


        if (defined($self->{option_results}->{filter_port}) && $self->{option_results}->{filter_port} ne '' &&
            $descr !~ /$self->{option_results}->{filter_port}/) {
            $self->{output}->output_add(long_msg => sprintf("Skipping interface '%s': filtered with options", $descr));
            next;
        }
        $self->{stp_port}->{$descr} = { state => $states{$stp_state},
                                        index => $result->{$oid_dot1dBasePortIfIndex . '.' . $instance},
                                        display => $descr };
    }

}

1;

__END__

=head1 MODE

Check Spanning-Tree current state of ports (BRIDGE-MIB).
example: perl centreon_plugins.pl --plugin=network::cisco::standard::snmp::plugin --mode=spanning-tree --hostname=X.X.X.X --snmp-version='2c' --snmp-community='snmpcommunity' --verbose --warning-status='%{state} =~ /forwarding/ && %{port} !~ /^Port/'

=over 8

=item B<--warning-status>
Specify logical expression to trigger a warning alert. Can use %{port} and %{state} or %{index}
e.g --warning-status "%{port} eq 'Port-Channel' && %{state} !~ /forwarding/"

=item B<--critical-status>
Specify logical expression to trigger a critical alert. Can use %{port} and %{state} or %{index}
Default is --critical-status='%{state} =~ /blocking|broken/'

=item B<--filter-port>
Filter on port description, can be a regexp

=back

=cut
