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

package network::citrix::netscaler::snmp::mode::certificatesexpire;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'certificates', type => 1, cb_prefix_output => 'prefix_certificates_output', message_multiple => 'All certificates are ok' }
    ];
    
    $self->{maps_counters}->{certificates} = [
        { label => 'days', set => {
                key_values => [ { name => 'days' }, { name => 'display' } ],
                output_template => '%d days remaining before expiration',
                closure_custom_perfdata => sub { return 0; },
            }
        },
    ];
}

sub prefix_certificates_output {
    my ($self, %options) = @_;
    
    return "Certificate '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                "filter-name:s"   => { name => 'filter_name' },
                                });

    return $self;
}

my $mapping = {
    sslCertKeyName  => { oid => '.1.3.6.1.4.1.5951.4.1.1.56.1.1.1' },
    sslDaysToExpire => { oid => '.1.3.6.1.4.1.5951.4.1.1.56.1.1.5' },
};

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{certificates} = {};
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [ { oid => $mapping->{sslCertKeyName}->{oid} }, { oid => $mapping->{sslDaysToExpire}->{oid} } ], 
        return_type => 1, nothing_quit => 1);

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{sslCertKeyName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{sslCertKeyName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{sslCertKeyName} . "': no matching filter.", debug => 1);
            next;
        }
       
        $self->{certificates}->{$instance} = { 
            display => $result->{sslCertKeyName},
            days    => $result->{sslDaysToExpire},
        };
    }
    
    if (scalar(keys %{$self->{certificates}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No certificate found.");
        $self->{output}->option_exit();
    }
}
    
1;

__END__

=head1 MODE

Check number of days remaining before the expiration of certificates (NS-MIB-smiv2).

=over 8

=item B<--filter-name>

Filter by name (can be a regexp).

=item B<--warning-days>

Threshold warning in days.

=item B<--critical-days>

Threshold critical in days.

=back

=cut
    
