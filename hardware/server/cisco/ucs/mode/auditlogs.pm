#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package hardware::server::cisco::ucs::mode::auditlogs;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

use centreon::plugins::misc;
use centreon::plugins::statefile;
use POSIX;

my %severity_map = (
    0 => 'cleared',
    1 => 'info',
    2 => 'condition',
    3 => 'warning',
    4 => 'minor',
    5 => 'major',
    6 => 'critical',
);

my $oid_cucsAaaModLRDescr = '.1.3.6.1.4.1.9.9.719.1.2.17.1.9';
my $oid_cucsAaaModLRCreated = '.1.3.6.1.4.1.9.9.719.1.2.17.1.8';
my $oid_cucsAaaModLRSeverity = '.1.3.6.1.4.1.9.9.719.1.2.17.1.12';
my $oid_cucsAaaModLRDn = '.1.3.6.1.4.1.9.9.719.1.2.17.1.2';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-severity:s@"  => { name => 'filter_severity', },
                                  "filter-message:s"    => { name => 'filter_message' },
                                  "retention:s"         => { name => 'retention' },
                                  "memory"              => { name => 'memory' },
                                });
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    $self->{severities} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->check_options(%options);
    }
    foreach my $val (@{$self->{option_results}->{filter_severity}}) {
        if ($val !~ /(.*?)=(.*)/) {
            $self->{output}->add_option_msg(short_msg => "Wrong filter-severity option '" . $val . "'.");
            $self->{output}->option_exit();
        }

        my ($filter, $threshold) = ($1, $2);
        if ($self->{output}->is_litteral_status(status => $threshold) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong filter_severity status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        
        $self->{severities}->{$filter} = $threshold;
    }
    if (scalar(keys %{$self->{severities}}) == 0) {
        $self->{severities} = { 'major|critical' => 'critical', 'minor|warning' => 'warning' };
    }
}

sub get_timestamp {
    my ($self, %options) = @_;

    my $value = unpack('H*', $options{value});
    $value =~ /^([0-9a-z]{4})([0-9a-z]{2})([0-9a-z]{2})([0-9a-z]{2})([0-9a-z]{2})([0-9a-z]{2})/;

	my $currentTmsp = mktime(hex($6), hex($5), hex($4), hex($3), hex($2) - 1, hex($1) - 1900);
    return $currentTmsp;
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();
    my $datas = {};
    my ($start, $last_instance);
    my ($num_eventlog_checked, $num_errors) = (0, 0);
    my %oids = ($oid_cucsAaaModLRDescr => undef, $oid_cucsAaaModLRCreated => undef, $oid_cucsAaaModLRSeverity => undef, $oid_cucsAaaModLRDn => undef);
    
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => "cache_ciscoucs_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
        $self->{output}->output_add(severity => 'OK', 
                                    short_msg => "No new problems detected.");
        $start = $self->{statefile_cache}->get(name => 'start');
        $last_instance = $start;
        if (defined($start)) {
            foreach (keys %oids) {
                $oids{$_} = $_ . '.' . $start;
            }
        }
    } else {
        $self->{output}->output_add(severity => 'OK', 
                                    short_msg => "No problems detected.");
    }
    
    my $result = $self->{snmp}->get_multiple_table(oids => [ 
                                                            { oid => $oid_cucsAaaModLRDescr, start => $oids{$oid_cucsAaaModLRDescr} },
                                                            { oid => $oid_cucsAaaModLRCreated, start => $oids{$oid_cucsAaaModLRCreated} },
                                                            { oid => $oid_cucsAaaModLRSeverity, start => $oids{$oid_cucsAaaModLRSeverity} },
                                                            { oid => $oid_cucsAaaModLRDn, start => $oids{$oid_cucsAaaModLRDn} },
                                                           ] );
    my @exits_global;
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_cucsAaaModLRDn}})) {
        next if ($key !~ /^$oid_cucsAaaModLRDn\.(\d+)$/);
        my $instance = $1;
        $last_instance = $instance;

        my $message = centreon::plugins::misc::trim($result->{$oid_cucsAaaModLRDescr}->{$oid_cucsAaaModLRDescr . '.' . $instance});
        my $severity = $result->{$oid_cucsAaaModLRSeverity}->{$oid_cucsAaaModLRSeverity . '.' . $instance};
        my $timestamp = $self->get_timestamp(value => $result->{$oid_cucsAaaModLRCreated}->{$oid_cucsAaaModLRCreated . '.' . $instance});
        my $dn = $result->{$oid_cucsAaaModLRDn}->{$oid_cucsAaaModLRDn . '.' . $instance};
        
        if (defined($self->{option_results}->{retention})) {
            next if (time() - $timestamp > $self->{option_results}->{retention});
        }

        $num_eventlog_checked++;        
        next if (defined($self->{option_results}->{filter_message}) && $self->{option_results}->{filter_message} ne '' && $message !~ /$self->{option_results}->{filter_message}/);
        
        my @exits;
        foreach (keys %{$self->{severities}}) {
            if ($severity_map{$severity} =~ /$_/) {
                push @exits, $self->{severities}->{$_};
                push @exits_global, $self->{severities}->{$_};
            }
        }
        
        my $exit = $self->{output}->get_most_critical(status => \@exits);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $num_errors++;
            $self->{output}->output_add(long_msg => sprintf("%s : %s (%s)", 
                                                            scalar(localtime($timestamp)),
                                                            $message, $dn
                                                           )
                                        );
        }
    }
    
    $self->{output}->output_add(long_msg => sprintf("Number of message checked: %s", $num_eventlog_checked));
    if ($num_errors != 0) {
        # Message problem
        my $exit = $self->{output}->get_most_critical(status => \@exits_global);
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("%d problem detected (use verbose for more details)", $num_errors)
                                    );
    }
    
    if (defined($self->{option_results}->{memory})) {
        $datas->{start} = $last_instance;
        $self->{statefile_cache}->write(data => $datas);
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check audit logs.

=over 8

=item B<--memory>

Only check new audit.

=item B<--filter-severity>

Filter on severity. (Default: 'critical|major=critical', 'warning|minor=warning')
Can be: critical, major, warning, minor, info, condition, cleared. 

=item B<--filter-message>

Filter on event message. (Default: none)

=item B<--retention>

Event older (current time - retention time) is not checked (in seconds).

=back

=cut
    