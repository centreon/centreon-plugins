#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package network::juniper::trapeze::snmp::mode::apstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg;
    
    if ($self->{result_values}->{opstatus} eq 'disabled') {
        $msg = ' is disabled';
    } else {
        $msg = 'Status : ' . $self->{result_values}->{opstatus};
    }
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{opstatus} = $options{new_datas}->{$self->{instance} . '_opstatus'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_init => 'skip_global', },
        { name => 'ap', type => 1, cb_prefix_output => 'prefix_ap_output', message_multiple => 'All AP status are ok' }
    ];
    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total ap : %s',
                perfdatas => [
                    { label => 'total', value => 'total', template => '%s', 
                      min => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{ap} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'opstatus' }, { name => 'display' } ],
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
                                  "filter-name:s"           => { name => 'filter_name' },
                                  "warning-status:s"        => { name => 'warning_status', default => '' },
                                  "critical-status:s"       => { name => 'critical_status', default => '%{opstatus} !~ /init|redundant|operationnal/' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub skip_global {
    my ($self, %options) = @_;
    
    scalar(keys %{$self->{ap}}) > 1 ? return(0) : return(1);
}

sub prefix_ap_output {
    my ($self, %options) = @_;
    
    return "AP '" . $options{instance_value}->{display} . "' ";
}

my %map_ap_status = ( 
    1 => 'cleared',
    2 => 'init',
    3 => 'bootStarted',
    4 => 'imageDownloaded',
    5 => 'connectFailed',
    6 => 'configuring',
    7 => 'operationnal',
    10 => 'redundant',
    20 => 'connOutage',
);

my $mapping_name_oid = {
    trpzApStatApStatusApName   => { oid => '.1.3.6.1.4.1.14525.4.5.1.1.2.1.8' },
};
my $mapping_state_oid = {
    trpzApStatApStatusApState    => { oid => '.1.3.6.1.4.1.14525.4.5.1.1.2.1.5', map => \%map_ap_status },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{ap} = {};
    $self->{global} = { total => 0};
    $self->{results} = $options{snmp}->get_multiple_table(oids => [{ oid => $mapping_name_oid->{trpzApStatApStatusApName}->{oid} },
                                                                   { oid => $mapping_state_oid->{trpzApStatApStatusApState}->{oid} },
                                                                 ],
                                                          nothing_quit => 1);
                                            
    foreach my $oid (keys %{$self->{results}->{ $mapping_name_oid->{trpzApStatApStatusApName}->{oid} }}) {
        $oid =~ /^$mapping_name_oid->{trpzApStatApStatusApName}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping_name_oid, results => $self->{results}->{ $mapping_name_oid->{trpzApStatApStatusApName}->{oid} }, instance => $instance);
        my $result2 = $options{snmp}->map_instance(mapping => $mapping_state_oid, results => $self->{results}->{ $mapping_state_oid->{trpzApStatApStatusApState}->{oid} }, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{trpzApStatApStatusApName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{trpzApStatApStatusApName} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{global}->{total}++;
        $self->{ap}->{$instance} = { display => $result->{trpzApStatApStatusApName}, 
                                     opstatus => $result2->{trpzApStatApStatusApState}};
    }
    
    if (scalar(keys %{$self->{ap}}) <= 0) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'No AP associated, check your filter ? ');
    }
}

1;

__END__

=head1 MODE

Check AP status.

=over 8

=item B<--filter-name>

Filter AP name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{opstatus}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{opstatus} !~ /init|redundant|operationnal/').
Can used special variables like: %{opstatus}, %{display}

=item B<--warning-total>

Set warning threshold for number of AP linked to the WLC

=item B<--critical-total>

Set critical threshold for number of AP linked to the WLC

=back

=cut
