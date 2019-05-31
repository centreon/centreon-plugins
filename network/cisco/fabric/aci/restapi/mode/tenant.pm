#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package network::cisco::fabric::aci::restapi::mode::tenant;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_health_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Current: '%d'%% Previous '%d'%%", $self->{result_values}->{current}, $self->{result_values}->{previous});
    return $msg;
}

sub custom_health_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{dn} = $options{new_datas}->{$self->{instance} . '_dn'};
    $self->{result_values}->{previous} = $options{new_datas}->{$self->{instance} . '_previous'};
    $self->{result_values}->{current} = $options{new_datas}->{$self->{instance} . '_current'};
    return 0;
}

sub custom_health_perfdata {
    my ($self, %options) = @_;

    foreach ('current', 'previous') {
        $self->{output}->perfdata_add(label => $_ . '_' . $self->{result_values}->{dn},
                                      value => $self->{result_values}->{$_},
                                      unit => '%', min => 0, max => 100);
    }
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'tenant', type => 1, cb_prefix_output => 'prefix_tenant_output',
            message_multiple => 'All tenants are OK' },
    ];

    $self->{maps_counters}->{tenant} = [
        { label => 'health', set => {
                key_values => [ { name => 'current' }, { name => 'previous' }, { name => 'dn'} ],
                closure_custom_calc => $self->can('custom_health_calc'),
                closure_custom_output => $self->can('custom_health_output'),
                closure_custom_threshold_check => \&catalog_status_threshold,
		        closure_custom_perfdata => $self->can('custom_health_perfdata')
            }
        },
    ];    
}

sub prefix_tenant_output {
    my ($self, %options) = @_;

    return "Tenant '" . $options{instance_value}->{dn} . "' Health ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments => 
                                {
                                  "filter-tenant"     => { name => 'filter_tenant' },
                                  "warning-health:s"  => { name => 'warning_health' },
                                  "critical-health:s" => { name => 'critical_health' },
    				            });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['warning_health', 'critical_health']);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{tenant} = {};

    my $result = $options{custom}->get_tenant_health();

    foreach my $object (@{$result->{imdata}}) {
	    my $dn = $object->{fvTenant}->{attributes}->{name};
        if (defined($self->{option_results}->{filter_tenant}) && $self->{option_results}->{filter_tenant} ne '' &&
            $dn =~ /$self->{option_results}->{filter_tenant}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $dn . "': no matching filter ", debug => 1);
            next;
        }
	    $self->{tenant}->{$dn} = {
              current => $object->{fvTenant}->{children}->[0]->{healthInst}->{attributes}->{cur}, 
		      previous => $object->{fvTenant}->{children}->[0]->{healthInst}->{attributes}->{prev}, 
		      dn => $dn
		}; 
    }

    if (scalar(keys %{$self->{tenant}}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No tenants found (try --debug)");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

=item B<--filter-tenant>

Regexp filter on the tenant name 

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
