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

package network::raisecom::pon::snmp::mode::processcount;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_process_status = (
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

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'process-status:s' => { name => 'process_status' },
            'process-name:s'   => { name => 'process_name' },
            'regexp-name'      => { name => 'regexp_name' },
            'process-pid'      => { name => 'process_pid' },
            'warning:s'        => { name => 'warning' },
            'critical:s'       => { name => 'critical' }
        });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg =>
                                        "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical}))
        == 0) {
        $self->{output}->add_option_msg(short_msg =>
                                        "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
}

my $filters = {
    status => { oid => '.1.3.6.1.4.1.8886.18.1.7.2.2.1.9', value => '', regexp => 1 }, # rcRunProcessStatus
    name   => { oid => '.1.3.6.1.4.1.8886.18.1.7.2.2.1.3', value => '' },              # rcRunProcessName
    pid    => { oid => '.1.3.6.1.4.1.8886.18.1.7.2.2.1.2', value => '' },              # rcRunProcessPID
};

my $oid_rcRunProcessName = '.1.3.6.1.4.1.8886.18.1.7.2.2.1.3';
my $oid_rcRunProcessPID = '.1.3.6.1.4.1.8886.18.1.7.2.2.1.2';
my $oid_rcRunProcessStatus = '.1.3.6.1.4.1.8886.18.1.7.2.2.1.9';


sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    foreach my $filter (keys %$filters) {
        if (defined($self->{option_results}->{'process_' . $filter}) && $self->{option_results}->{'process_' . $filter}
                                                                        ne '') {
            $filters->{$filter}->{value} = $self->{option_results}->{'process_' . $filter};
        }
        if (defined($self->{option_results}->{'regexp_' . $filter})) {
            $filters->{$filter}->{regexp} = 1;
        }
    }

    my $oids_multiple_table = [
        { oid => $oid_rcRunProcessStatus },
        { oid => $oid_rcRunProcessName },
        { oid => $oid_rcRunProcessPID }
    ];

    # First lookup on name and status
    $self->{snmp_response} = $self->{snmp}->get_multiple_table(oids => $oids_multiple_table);
    use Data::Dumper;
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$self->{snmp_response}->{$oid_rcRunProcessStatus}})) {
        next if ($key !~ /^$oid_rcRunProcessStatus\.(.*)$/);
        my $instance = $1;
        $self->{results}->{$instance}->{status} = $map_process_status{$self
            ->{snmp_response}
            ->{$oid_rcRunProcessStatus}
            ->{$oid_rcRunProcessStatus . '.' . $instance}};
        $self->{results}->{$instance}->{name} = $self
            ->{snmp_response}
            ->{$oid_rcRunProcessName}
            ->{$oid_rcRunProcessName . '.' . $instance};
        $self->{results}->{$instance}->{pid} = $self
            ->{snmp_response}
            ->{$oid_rcRunProcessPID}
            ->{$oid_rcRunProcessPID . '.' . $instance};

        foreach my $filter (keys %$filters) {
            next if !defined($self->{results}->{$instance}) || $filters->{$filter}->{value} eq '';
            if ((defined($filters->{$filter}->{regexp}) && $self->{results}->{$instance}->{$filter} !~ /$filters
                ->{$filter}
                ->{value}/)
                || (!defined($filters->{$filter}->{regexp}) && $self->{results}->{$instance}->{$filter} ne $filters
                ->{$filter}
                ->{value})) {
                delete $self->{results}->{$instance};
            }
        }
    }

    my $num_processes_match = scalar(keys(%{$self->{results}}));
    my $exit = $self->{perfdata}->threshold_check(
        value     => $num_processes_match,
        threshold => [ { label => 'critical', exit_litteral => 'critical' },
                       { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(
        severity  => $exit,
        short_msg => "Number of current processes running: $num_processes_match");
    $self->{output}->perfdata_add(
        label    => 'nbproc',
        value    => $num_processes_match,
        warning  => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
        min      => 0);

    foreach my $pid (keys %{$self->{results}}) {
        my $long_msg = sprintf("Process '%s'", $self->{results}->{$pid}->{name});
        $long_msg .= sprintf(" [status: %s, pid: %s]",
                             $self->{results}->{$pid}->{status},
                             $self->{results}->{$pid}->{pid});
        $self->{output}->output_add(long_msg => $long_msg);
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__


=head1 MODE

Check system number of processes.

=over 8

=item B<--process-status>

Filter process status. Can be a regexp.

=item B<--process-name>

Filter process name.

=item B<--regexp-name>

Allows to use regexp to filter process
name (with option --process-name)

=back

=cut