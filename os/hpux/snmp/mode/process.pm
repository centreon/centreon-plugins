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

package os::hpux::snmp::mode::process;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_process_status = (
    1 => 'sleep',
    2 => 'run',
    3 => 'stop',
    4 => 'zombie',
    5 => 'other',
    6 => 'idle',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
                                  "process-cmd:s"           => { name => 'process_cmd', },
                                  "regexp-cmd"              => { name => 'regexp_cmd', },
                                  "process-status:s"        => { name => 'process_status', default => 'run' },
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

my $oids = {
    status => '.1.3.6.1.4.1.11.2.3.1.4.2.1.19', # processStatus
    cmd => '.1.3.6.1.4.1.11.2.3.1.4.2.1.22', # processCmd
};

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid2check_filter = 'status';
    # To have a better order
    foreach (('cmd', 'status')) {
        if (defined($self->{option_results}->{'process_' . $_}) && $self->{option_results}->{'process_' . $_} ne '') {
            $oid2check_filter = $_;
            last;
        }
    }
    # Build other
    my $mores_filters = {};
    my $more_oids = [];
    foreach (keys %$oids) {
        if ($_ ne $oid2check_filter && defined($self->{option_results}->{'process_' . $_}) && $self->{option_results}->{'process_' . $_} ne '') {
            push @{$more_oids}, $oids->{$_};
            $mores_filters->{$_} = 1;
        }
    }

    my $oids_multiple_table = [ { oid => $oids->{$oid2check_filter} } ];

    $self->{results} = $self->{snmp}->get_multiple_table(oids => $oids_multiple_table);
    my $result = $self->{results}->{$oids->{$oid2check_filter}};
    my $instances_keep = {};
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$result})) {
        my $option_val = $self->{option_results}->{'process_' . $oid2check_filter};
        
        if ($oid2check_filter eq 'status') {
            if ($map_process_status{$result->{$key}} =~ /$option_val/) {
                $key =~ /\.([0-9]+)$/;
                $instances_keep->{$1} = 1;
            }
        } elsif ((defined($self->{option_results}->{'regexp_' . $oid2check_filter}) && $result->{$key} =~ /$option_val/)
                 || (!defined($self->{option_results}->{'regexp_' . $oid2check_filter}) && $result->{$key} eq $option_val)) {
            $key =~ /\.([0-9]+)$/;
            $instances_keep->{$1} = 1;
        }
    }

    my $result2;
    if (scalar(keys %$instances_keep) > 0) {
        if (scalar(@$more_oids) > 0) {
            $self->{snmp}->load(oids => $more_oids, instances => [ keys %$instances_keep ]);
            $result2 = $self->{snmp}->get_leef();
        }
    
        foreach my $key (keys %$instances_keep) {
            my $value = ($oid2check_filter eq 'status') ? $map_process_status{$result->{$oids->{$oid2check_filter} . '.' . $key}} : $result->{$oids->{$oid2check_filter} . '.' . $key};       
            my $long_value = '[ ' . $oid2check_filter . ' => ' . $value . ' ]';
            my $deleted = 0;
            foreach (keys %$mores_filters) {
                my $opt_val = $self->{option_results}->{'process_' . $_};
                $value = ($_ eq 'status') ? $map_process_status{$result2->{$oids->{$_} . '.' . $key}} : $result2->{$oids->{$_} . '.' . $key};
                
                if ($_ eq 'status') {
                    if ($value !~ /$opt_val/) {
                        delete $instances_keep->{$key};
                        $deleted = 1;
                        last;
                    }
                } elsif ((defined($self->{option_results}->{'regexp_' . $_}) && $value !~ /$opt_val/)
                    || (!defined($self->{option_results}->{'regexp_' . $_}) && $value ne $opt_val)) {
                    delete $instances_keep->{$key};
                    $deleted = 1;
                    last;
                }
                
                $long_value .= ' [ ' . $_ . ' => ' . $value . ' ]';
            }
            
            if ($deleted == 0) {
                $self->{output}->output_add(long_msg => 'Process: ' . $long_value);
            }
        }
    }
    
    my $num_processes_match = scalar(keys(%$instances_keep));
    my $exit = $self->{perfdata}->threshold_check(value => $num_processes_match, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => "Number of current processes running: $num_processes_match");
    $self->{output}->perfdata_add(label => 'nbproc',
                                  value => $num_processes_match,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check system number of processes.

=over 8

=item B<--warning>

Threshold warning (process count).

=item B<--critical>

Threshold critical (process count).

=item B<--process-cmd>

Check process command.

=item B<--regexp-cmd>

Allows to use regexp to filter process command (with option --process-cmd).

=item B<--process-status>

Check process status (Default: 'run'). Can be a regexp.

=back

=cut
