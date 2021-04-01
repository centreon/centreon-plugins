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

package apps::protocols::dns::mode::request;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use apps::protocols::dns::lib::dns;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'nameservers:s@'    => { name => 'nameservers' },
        'searchlist:s@'     => { name => 'searchlist' },
        'dns-options:s@'    => { name => 'dns_options' },
        'search:s'          => { name => 'search' },
        'search-type:s'     => { name => 'search_type' },
        'use-ptr-fqdn'      => { name => 'use_ptr_fqdn' },
        'expected-answer:s' => { name => 'expected_answer' },
        'warning:s'         => { name => 'warning' },
        'critical:s'        => { name => 'critical' },
        'memory'            => { name => 'memory' }
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
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
    
    if (defined($self->{option_results}->{memory})) {
        $self->{cache_filename} = $self->{option_results}->{search};
        foreach (('search_type', 'search', 'nameservers')) {
            $self->{cache_filename} .= '_';
            if (defined($self->{option_results}->{$_})) {
                if (ref($self->{option_results}->{$_}) eq 'ARRAY') {
                    $self->{cache_filename} .= join('-', @{$self->{option_results}->{$_}});
                } else {
                    $self->{cache_filename} .= $self->{option_results}->{$_};
                }
            }
        }
        $self->{statefile_cache}->check_options(%options);
    }
}

sub run {
    my ($self, %options) = @_;
    
    my $timing0 = [gettimeofday];
    
    apps::protocols::dns::lib::dns::connect($self);
    my @results = apps::protocols::dns::lib::dns::search($self, error_quit => 'critical');  

    my $timeelapsed = tv_interval ($timing0, [gettimeofday]);
    my $result_str = join(', ', @results);
    
    my $exit = $self->{perfdata}->threshold_check(
        value => $timeelapsed,
        threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]
    );
    $self->{output}->output_add(
        severity => $exit,
        short_msg => sprintf("Response time %.3f second(s) (answer: %s)", $timeelapsed, $result_str)
    );
    $self->{output}->perfdata_add(
        label => "time", unit => 's',
        value => sprintf('%.3f', $timeelapsed),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical')
    );

    if (defined($self->{option_results}->{expected_answer}) && $self->{option_results}->{expected_answer} ne '') {
        my $match = 0;
        foreach (@results) {
            if (/$self->{option_results}->{expected_answer}/) {
                $match = 1;
            }
        }
        
        if ($match == 0) {
            $self->{output}->output_add(
                severity => 'CRITICAL',
                short_msg => sprintf("No result values match expected answer (answer: %s)", $result_str
            )
        );
        }
    }
    
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => 'cache_dns_' . md5_hex($self->{cache_filename}));
        my $datas = { result => $result_str };
        my $old_result = $self->{statefile_cache}->get(name => "result");
        if (defined($old_result)) {
            if ($old_result ne $result_str) {
                $self->{output}->output_add(
                    severity => 'CRITICAL',
                    short_msg => sprintf("Result has changed [answer: %s] [old answer: %s]", $result_str, $old_result)
                );
            }
        } else {
            $self->{output}->output_add(long_msg => 'cache file created.');
        }
        $self->{statefile_cache}->write(data => $datas);
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

Set the search type. Can be: 'MX', 'SOA', 'NS', 'A', 'CNAME' or 'PTR'.
'A' or 'PTR' is used by default (depends if an IP or not).

=item B<--use-ptr-fqdn>

Search is done on conical names for PTR type.

=item B<--expected-answer>

What the server must answer (can be a regexp).

=item B<--dns-options>

Add custom dns options.
Example: --dns-options='debug=1' --dns-options='retry=2' 
--dns-options='port=972' --dns-options='recurse=0' ...

=item B<--memory>

Critical threshold if the answer changed between two checks.

=item B<--warning>

Threshold warning in seconds.

=item B<--critical>

Threshold critical in seconds.

=back

=cut
