#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package hardware::server::ibm::mgmt_cards::imm::snmp::mode::eventlog;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

use centreon::plugins::misc;
use centreon::plugins::statefile;

my %severity_map = (
    0 => 'error',
    1 => 'warning',
    2 => 'information',
    3 => 'other',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-severity:s"   => { name => 'filter_severity', default => 'error' },
                                  "filter-message:s"    => { name => 'filter_message' },
                                  "memory"              => { name => 'memory' },
                                  "warning"             => { name => 'warning' },
                                });
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->check_options(%options);
    }
}


sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();
    my $datas = {};
    my $last_time;
    my $exit = defined($self->{option_results}->{warning}) ? 'WARNING' : 'CRITICAL';
    my ($num_eventlog_checked, $num_errors) = (0, 0);
    
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => "cache_imm_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
        $self->{output}->output_add(severity => 'OK', 
                                    short_msg => "No new problems detected.");
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    } else {
        $self->{output}->output_add(severity => 'OK', 
                                    short_msg => "No problems detected.");
    }
    
    #### Get OIDS
    ## Not need to check from an index point (not so much values. and can clear)
    
    my $oid_eventLogEntry = '.1.3.6.1.4.1.2.3.51.3.2.1.1.1';
    my $oid_eventLogString = '.1.3.6.1.4.1.2.3.51.3.2.1.1.1.2';
    my $oid_eventLogSeverity = '.1.3.6.1.4.1.2.3.51.3.2.1.1.1.3';
    my $oid_eventLogDate = '.1.3.6.1.4.1.2.3.51.3.2.1.1.1.4'; # Month/Day/YEAR
    my $oid_eventLogTime = '.1.3.6.1.4.1.2.3.51.3.2.1.1.1.5'; # Hour::Min::Sec
    
    my $result = $self->{snmp}->get_table(oid => $oid_eventLogEntry);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_eventLogString\.(\d+)$/);
        my $instance = $1;

        my $message = centreon::plugins::misc::trim($result->{$oid_eventLogString . '.' . $instance});
        my $severity = $result->{$oid_eventLogSeverity . '.' . $instance};
        my $date = $result->{$oid_eventLogDate . '.' . $instance};
        my $time = $result->{$oid_eventLogTime . '.' . $instance};
        
        my $date_compare = '';
        $date =~ /(\d+)\/(\d+)\/(\d+)/;
        $date_compare = $3 . $1 . $2;
        $time =~ /(\d+):(\d+):(\d+)/;
        $date_compare .= $1 . $2 . $3;
        
        if (defined($self->{option_results}->{memory})) {
            $datas->{last_time} = $date_compare;
            next if (defined($last_time) && $datas->{last_time} <= $last_time);
        }
        
        $num_eventlog_checked++;
        
        next if (defined($self->{option_results}->{filter_severity}) && $self->{option_results}->{filter_severity} ne '' && $severity_map{$severity} !~ /$self->{option_results}->{filter_severity}/);
        next if (defined($self->{option_results}->{filter_message}) && $self->{option_results}->{filter_message} ne '' && $message !~ /$self->{option_results}->{filter_message}/);
        
        $num_errors++;
        $self->{output}->output_add(long_msg => sprintf("%s : %s", 
                                                         $date . ' ' . $time,
                                                         $message
                                                         )
                                    );
        
        
    }
    
    $self->{output}->output_add(long_msg => sprintf("Number of message checked: %s", $num_eventlog_checked));
    if ($num_errors != 0) {
        # Message problem
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("%d problem detected (use verbose for more details)", $num_errors)
                                    );
    }
    
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->write(data => $datas);
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check eventlogs.

=over 8

=item B<--warning>

Use warning return instead 'critical'.

=item B<--memory>

Only check new eventlogs.

=item B<--filter-severity>

Filter on severity. (Default: error)
Can be: error, warning, information, other. 

=item B<--filter-message>

Filter on event message. (Default: none)

=back

=cut
    