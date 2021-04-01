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

package network::cisco::aci::apic::restapi::mode::fabric;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_health_output {
    my ($self, %options) = @_;
    
    return sprintf('health current: %d%%, previous: %d%%', $self->{result_values}->{current}, $self->{result_values}->{previous});
}

sub custom_health_perfdata {
    my ($self, %options) = @_;

    foreach ('current', 'previous') {
        $self->{output}->perfdata_add(
            nlabel => 'fabric.health.' . $_ . '.percentage', 
            instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{dn} : undef,
            value => $self->{result_values}->{$_},
            unit => '%', min => 0, max => 100
        );
    }
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'fabric', type => 1, cb_prefix_output => 'prefix_fabric_output', message_multiple => 'all fabrics are ok' }
    ];

    $self->{maps_counters}->{fabric} = [
        { label => 'health', type => 2, set => {
                key_values => [ { name => 'current' }, { name => 'previous' }, { name => 'dn' } ],
                closure_custom_output => $self->can('custom_health_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
		        closure_custom_perfdata => $self->can('custom_health_perfdata')
            }
        }
    ];
}

sub prefix_fabric_output {
    my ($self, %options) = @_;

    return "Fabric '" . $options{instance_value}->{dn} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{fabric} = {};

    my $result_global = $options{custom}->get_fabric_health();
    foreach my $object (@{$result_global->{imdata}}) {
        my $dn = $object->{fabricHealthTotal}->{attributes}->{dn};
	    $self->{fabric}->{$dn} = { 
            current => $object->{fabricHealthTotal}->{attributes}->{cur}, 
		    previous => $object->{fabricHealthTotal}->{attributes}->{prev}, 
		    dn => $dn
	    }; 
    }

    if (scalar(keys %{$self->{fabric}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No fabric found (try --debug)");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check fabrics.

=over 8

=item B<--warning-health>

Set warning for the health level
Can used special variables like: %{current}, %{previous}.
example: --warning-health='%{previous} < %{current}'

=item B<--critical-health>

Set critical for the health level
Can used special variables like: %{current}, %{previous}.
example: --critical-health='%{current} < 98'

=back

=cut
