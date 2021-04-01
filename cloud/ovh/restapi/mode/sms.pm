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

package cloud::ovh::restapi::mode::sms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'sms', type => 1, cb_prefix_output => 'prefix_sms_output', message_multiple => 'All sms services are ok' }
    ];
    
    $self->{maps_counters}->{sms} = [
        { label => 'left', set => {
                key_values => [ { name => 'left' }, { name => 'display' } ],
                output_template => 'SMS left : %s',
                perfdatas => [
                    { label => 'left', value => 'left', template => '%s', unit => 'sms',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },

    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-service:s"    => { name => 'filter_service' },
                                });
    
    return $self;
}

sub prefix_sms_output {
    my ($self, %options) = @_;
    
    return "Service '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{sms} = {};
    my $result = $options{custom}->get(path => '/sms');
    foreach my $service (@$result) {
        if (defined($self->{option_results}->{filter_service}) && $self->{option_results}->{filter_service} ne '' &&
            $service !~ /$self->{option_results}->{filter_service}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $service . "': no matching filter.", debug => 1);
            next;
        }
        
        my $result2 = $options{custom}->get(path => '/sms/' . $service);
        $self->{sms}->{$service} = { 
            display => $service,
            left => $result2->{creditsLeft} };
    }
    
    if (scalar(keys %{$self->{sms}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No sms service found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check sms left.

=over 8

=item B<--filter-service>

Filter service name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'left'.

=item B<--critical-*>

Threshold critical.
Can be: 'left'.

=back

=cut
