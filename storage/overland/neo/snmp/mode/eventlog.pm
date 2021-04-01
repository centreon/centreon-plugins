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

package storage::overland::neo::snmp::mode::eventlog;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %severity_map = (
    0 => 'informational', 
    1 => 'mild', 
    2 => 'hard', 
    3 => 'severe',
);

my $mapping = {
    errCode         => { oid => '.1.3.6.1.4.1.3351.1.3.2.3.3.1.2' },
    errSeverity     => { oid => '.1.3.6.1.4.1.3351.1.3.2.3.3.1.3', map => \%severity_map  },
    errMsg          => { oid => '.1.3.6.1.4.1.3351.1.3.2.3.3.1.4' },
};
my $oid_errorEntry = '.1.3.6.1.4.1.3351.1.3.2.3.3.1';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-severity:s"   => { name => 'filter_severity', default => 'hard|severe' },
                                  "filter-message:s"    => { name => 'filter_message' },
                                  "warning"             => { name => 'warning' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    my $exit = defined($self->{option_results}->{warning}) ? 'WARNING' : 'CRITICAL';
    my ($num_eventlog_checked, $num_errors) = (0, 0);
    
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "No problems detected.");
    
    my $results = $options{snmp}->get_table(oid => $oid_errorEntry);

    foreach my $oid ($options{snmp}->oid_lex_sort(keys %$results)) {
        next if ($oid !~ /^$mapping->{errSeverity}->{oid}(?:\.(.*)|$)/);
        my $instance = defined($1) ? $1 : undef;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);
        
        $num_eventlog_checked++;
        
        next if (defined($self->{option_results}->{filter_severity}) && $self->{option_results}->{filter_severity} ne '' && $result->{errSeverity} !~ /$self->{option_results}->{filter_severity}/);
        next if (defined($self->{option_results}->{filter_message}) && $self->{option_results}->{filter_message} ne '' && $result->{errMsg} !~ /$self->{option_results}->{filter_message}/);
        
        $num_errors++;
        $self->{output}->output_add(long_msg => sprintf("%s : %s [severity: %s]", 
                                                         $result->{errCode},
                                                         $result->{errMsg}, $result->{errSeverity}
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

=item B<--filter-severity>

Filter on severity. (Default: hard|severe)
Can be: severe, hard, mild, informational. 

=item B<--filter-message>

Filter on event message. (Default: none)

=back

=cut
    