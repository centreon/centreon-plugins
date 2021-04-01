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

package apps::bind9::web::mode::zoneusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'zones', type => 1, cb_prefix_output => 'prefix_zone_output', message_multiple => 'All zone counters are ok', skipped_code => { -1 => 1, -10 => 1, 11 => -1 } }
    ];
    
    $self->{maps_counters}->{zones} = [
         { label => 'message', threshold => 0, set => {
                key_values => [ { name => 'display' } ],
                closure_custom_calc => sub { return 0; },
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => sub { return 'ok'; },
                closure_custom_output => sub { return 'counters are ok' },
            }
        },
    ];

    my @map = (
        ['qtype_a', 'qtype A : %s', 'qtype-a'],
        ['qtype_cname', 'qtype CNAME : %s', 'qtype-cname'],
        ['qtype_mx', 'qtype MX : %s', 'qtype-mx'],
        ['qtype_txt', 'qtype TXT : %s', 'qtype-txt'],
        ['qtype_soa', 'qtype SOA : %s', 'qtype-soa'],
        ['qtype_ptr', 'qtype PTR : %s', 'qtype-ptr'],
        ['qtype_ns', 'qtype NS : %s', 'qtype-ns'],
        ['rcode_requestv4', 'rcode request v4 : %s', 'rcode-requestv4'],
        ['rcode_requestv6', 'rcode request v6 : %s', 'rcode-requestv6'],
    );

    for (my $i = 0; $i < scalar(@map); $i++) {
        my $perf_label = $map[$i]->[2];
        $perf_label =~ s/-/_/g;
        push @{$self->{maps_counters}->{zones}}, { label => $map[$i]->[2], display_ok => 0, set => {
                key_values => [ { name => $map[$i]->[0], diff => 1 }, { name => 'display' } ],
                output_template => $map[$i]->[1],
                perfdatas => [
                    { label => $perf_label, value => $map[$i]->[0] , template => '%s', min => 0, 
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        };
    }
}

sub prefix_zone_output {
    my ($self, %options) = @_;

    return "Zone '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s"     => { name => 'filter_name' },
    });
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
                                                           
    my $result = $options{custom}->get_zones();
    $self->{zones} = { };
    
    foreach my $zone_name (keys %{$result}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $zone_name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $zone_name . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{zones}->{$zone_name} = { display => $zone_name };
        foreach my $type (keys %{$result->{$zone_name}->{counters}}) {
            foreach my $counter (keys %{$result->{$zone_name}->{counters}->{$type}}) {
                $self->{zones}->{$zone_name}->{lc($type) . '_' . lc($counter)} = $result->{$zone_name}->{counters}->{$type}->{$counter};
            }
        }
    }
    
    if (scalar(keys %{$self->{zones}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No zone found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "bind9_" . $self->{mode} . '_' . $options{custom}->get_uniq_id()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check bind zone usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='request'

=item B<--filter-name>

Filter zone name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: qtype-a', 'qtype-cname', 'qtype-mx', 'qtype-txt', 'qtype-soa', 'qtype-ptr', 'qtype-ns',
'nsstat-requestv4', 'nsstat-requestv6'.

=back

=cut
