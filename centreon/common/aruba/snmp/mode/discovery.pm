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

package centreon::common::aruba::snmp::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "prettify" => { name => 'prettify' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my %map_status = (
    1 => 'up', 2 => 'down'
);

my $oid_wlsxWlanAPTable = '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1';

my $mapping = {
    wlanAPIpAddress => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1.2' },
    wlanAPName => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1.3' },
    wlanAPGroupName=> { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1.4' },
    wlanAPUpTime => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1.12' },
    wlanAPLocation => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1.14' },
    wlanAPStatus => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1.20', map => \%map_status },
    wlanAPNumBootstraps => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1.21' },
    wlanAPNumReboots => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1.22' },
};

sub run {
    my ($self, %options) = @_;

    my @disco_data;
    my $disco_stats;

    $disco_stats->{start_time} = time();
    
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_wlsxWlanAPTable,
        start => $mapping->{wlanAPIpAddress}->{oid},
        end => $mapping->{wlanAPNumReboots}->{oid},
        nothing_quit => 1
    );
    
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{wlanAPIpAddress}->{oid}\.(.*)/);
        my $instance = $1;
        
        my $result = $options{snmp}->map_instance(
            mapping => $mapping,
            results => $snmp_result,
            instance => $instance
        );
        
        my %ap;
        $ap{name} = $result->{wlanAPName};
        $ap{ip} = $result->{wlanAPIpAddress};
        $ap{group} = $result->{wlanAPGroupName};
        $ap{location} = $result->{wlanAPLocation};
        $ap{status} = $result->{wlanAPStatus};
        $ap{type} = "ap";
        
        push @disco_data, \%ap;
    }

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = @disco_data;
    $disco_stats->{results} = \@disco_data;

    my $encoded_data;
    eval {
        if (defined($self->{option_results}->{prettify})) {
            $encoded_data = JSON::XS->new->utf8->pretty->encode($disco_stats);
        } else {
            $encoded_data = JSON::XS->new->utf8->encode($disco_stats);
        }
    };
    if ($@) {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}';
    }
    
    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Resources discovery.

=over 8

=item B<--prettify>

Prettify JSON output.

=back

=cut
