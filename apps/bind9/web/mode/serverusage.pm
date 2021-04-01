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

package apps::bind9::web::mode::serverusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'server', type => 0, skipped_code => { -1 => 1, -10 => 1, 11 => -1 } }
    ];
    
    $self->{maps_counters}->{server} = [];

    my @map = (
        ['opcode_query', 'opcode query : %s', 'opcode-query'],
        ['opcode_iquery', 'opcode iquery : %s', 'opcode-iquery'],
        ['opcode_status', 'opcode status : %s', 'opcode-status'],
        ['opcode_notify', 'opcode notify : %s', 'opcode-notify'],
        ['opcode_update', 'opcode update : %s', 'opcode-update'],
        ['qtype_a', 'qtype A : %s', 'qtype-a'],
        ['qtype_cname', 'qtype CNAME : %s', 'qtype-cname'],
        ['qtype_mx', 'qtype MX : %s', 'qtype-mx'],
        ['qtype_txt', 'qtype TXT : %s', 'qtype-txt'],
        ['qtype_soa', 'qtype SOA : %s', 'qtype-soa'],
        ['qtype_ptr', 'qtype PTR : %s', 'qtype-ptr'],
        ['qtype_ns', 'qtype NS : %s', 'qtype-ns'],
        ['nsstat_requestv4', 'nsstat request v4 : %s', 'nsstat-requestv4'],
        ['nsstat_requestv6', 'nsstat request v6 : %s', 'nsstat-requestv6'],
    );

    for (my $i = 0; $i < scalar(@map); $i++) {
        my $perf_label = $map[$i]->[2];
        $perf_label =~ s/-/_/g;
        push @{$self->{maps_counters}->{server}}, { label => $map[$i]->[2], display_ok => 0, set => {
                key_values => [ { name => $map[$i]->[0], diff => 1 } ],
                output_template => $map[$i]->[1],
                perfdatas => [
                    { label => $perf_label, value => $map[$i]->[0] , template => '%s', min => 0 },
                ],
            }
        };
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
                                                           
    my $result = $options{custom}->get_server();
    $self->{server} = { };

    # Not present in response if no request on the server
    foreach ('a', 'cname', 'mx', 'txt', 'soa', 'ptr', 'ns', 'any') {
        $self->{server}->{'qtype_' . $_} = 0;
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All bind9 counters are ok');
    foreach my $type (keys %{$result->{counters}}) {
        foreach my $counter (keys %{$result->{counters}->{$type}}) {
            $self->{server}->{lc($type) . '_' . lc($counter)} = $result->{counters}->{$type}->{$counter};
        }
    }
    
    $self->{cache_name} = "bind9_" . $self->{mode} . '_' . $options{custom}->get_uniq_id()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check bind global server usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='request'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'opcode-query', 'opcode-iquery', 'opcode-status', 'opcode-notify', 'opcode-update',
'qtype-a', 'qtype-cname', 'qtype-mx', 'qtype-txt', 'qtype-soa', 'qtype-ptr', 'qtype-ns', 'qtype-any',
'nsstat-requestv4', 'nsstat-requestv6'.

=back

=cut
