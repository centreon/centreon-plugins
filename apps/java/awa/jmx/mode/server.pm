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

package apps::java::awa::jmx::mode::server;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'active : ' . $self->{result_values}->{active} . ' [IpAddress: ' . $self->{result_values}->{ipaddress} . ' ]';
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{ipaddress} = $options{new_datas}->{$self->{instance} . '_ipaddress'};
    $self->{result_values}->{active} = $options{new_datas}->{$self->{instance} . '_active'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'server', type => 1, cb_prefix_output => 'prefix_server_output', message_multiple => 'All servers are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{server} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'active' }, { name => 'ipaddress' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
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
                                  "filter-name:s"       => { name => 'filter_name' },
                                  "warning-status:s"    => { name => 'warning_status', default => '' },
                                  "critical-status:s"   => { name => 'critical_status', default => '' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_server_output {
    my ($self, %options) = @_;
    
    return "Server '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{app} = {};
    $self->{request} = [
         { mbean => 'Automic:name=*,side=Servers,type=*',
          attributes => [ { name => 'NetArea' }, { name => 'IpAddress' }, 
                          { name => 'Active' }, { name => 'Name' } ] },
    ];
    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 1);

    foreach my $mbean (keys %{$result}) {
        $mbean =~ /name=(.*?)(,|$)/i;
        my $name = $1;
        $mbean =~ /type=(.*?)(,|$)/i;
        my $display = $1 . '.' . $name;

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $display !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $display . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{server}->{$display} = { 
            display => $display,
            ipaddress => $result->{$mbean}->{IpAddress},
            active => $result->{$mbean}->{Active} ? 'yes' : 'no',
        };
    }
    
    if (scalar(keys %{$self->{server}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No server found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check server status.

=over 8

=item B<--filter-name>

Filter server name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{display}, %{ipaddress}, %{active}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{display}, %{ipaddress}, %{active}

=back

=cut
