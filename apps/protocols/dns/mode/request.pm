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

package apps::protocols::dns::mode::request;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use apps::protocols::dns::lib::dns;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
         {
         "nameservers:s@"       => { name => 'nameservers' },
         "searchlist:s@"        => { name => 'searchlist' },
         "dns-options:s@"       => { name => 'dns_options' },
         "search:s"             => { name => 'search' },
         "search-type:s"        => { name => 'search_type' },
         "search-field:s"       => { name => 'search_field' },
         "expected-answer:s"    => { name => 'expected_answer' },
         "warning:s"            => { name => 'warning' },
         "critical:s"           => { name => 'critical' },
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
    
    if (!defined($self->{option_results}->{search}) || $self->{option_results}->{search} eq '') {
        $self->{output}->add_option_msg(short_msg => "Please set the search option");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    
    my $timing0 = [gettimeofday];
    
    apps::protocols::dns::lib::dns::connect($self);
    my @results = apps::protocols::dns::lib::dns::search($self, error_quit => 'critical');  

    my $timeelapsed = tv_interval ($timing0, [gettimeofday]);
    my $result_str = join(', ', @results);
    
    my $exit = $self->{perfdata}->threshold_check(value => $timeelapsed,
                                                  threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Response time %.3f second(s) (answer: %s)", $timeelapsed, $result_str));
    $self->{output}->perfdata_add(label => "time", unit => 's',
                                  value => sprintf('%.3f', $timeelapsed),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));

    if (defined($self->{option_results}->{expected_answer}) && $self->{option_results}->{expected_answer} ne '') {
        my $match = 0;
        foreach (@results) {
            if (/$self->{option_results}->{expected_answer}/) {
                $match = 1;
            }
        }
        
        if ($match == 0) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("No result values match expected answer (answer: %s)", $result_str));
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check requests to a DNS Server.
Example:
perl centreon_plugins.pl --plugin=apps::protocols::dns::plugin --mode=request --search=google.com --search-type=MX

=over 8

=item B<--nameservers>

Set nameserver to query (can be multiple).
The system configuration is used by default.

=item B<--searchlist>

Set domains to search for unqualified names (can be multiple).
The system configuration is used by default.

=item B<--search>

Set the search value (required).

=item B<--search-type>

Set the search type. Can be: 'MX', 'SOA', 'NS', 'A' or 'PTR'.
'A' or 'PTR' is used by default (depends if an IP or not).

=item B<--search-field>

Set the search field used for 'expected-answer'. 
By default:
'MX' is 'exchange', 'SOA' is 'mname', 'NS' is 'nsdname', 
'A' is 'address' and 'PTR' is 'name'.
'A' or 'PTR' is used by default (depends if an IP or not).

=item B<--expected-answer>

What the server must answer (can be a regexp).

=item B<--dns-options>

Add custom dns options.
Example: --dns-options='debug=1' --dns-options='retry=2' 
--dns-options='port=972' --dns-options='recurse=0' ...

=item B<--warning>

Threshold warning in seconds

=item B<--critical>

Threshold critical in seconds

=back

=cut
