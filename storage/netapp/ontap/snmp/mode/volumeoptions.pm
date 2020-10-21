#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package storage::netapp::ontap::snmp::mode::volumeoptions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_options_threshold {
    my ($self, %options) = @_;

    my $status = catalog_status_threshold_ng($self, %options);
    if (!$self->{output}->is_status(value => $status, compare => 'ok', litteral => 1)) {
        $self->{instance_mode}->{global}->{failed}++;
    }
    return $status;
}

sub prefix_volume_output {
    my ($self, %options) = @_;

    return "Volume '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'volumes', type => 1, cb_prefix_output => 'prefix_volume_output', message_multiple => 'All volumes are ok', skipped_code => { -10 => 1 } },
        { name => 'global', type => 0 } # need to be after for counting failed
    ];

    $self->{maps_counters}->{volumes} = [
         { label => 'status', type => 2, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                output_template => "status is '%s'",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'options', type => 2, set => {
                key_values => [ { name => 'options' }, { name => 'display' } ],
                output_template => "options: '%s'",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_options_threshold')
            }
        }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'failed', display_ok => 0, set => {
                key_values => [ { name => 'failed' } ],
                output_template => 'Failed: %s',
                perfdatas => [
                    { label => 'failed', template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'    => { name => 'filter_name' },
        'filter-vserver:s' => { name => 'filter_vserver' },
        'filter-status:s'  => { name => 'filter_status' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{test_option} = 0;
    foreach ('warning', 'unknown', 'critical') {
        $self->{test_option} = 1 if (defined($self->{option_results}->{$_ . '-options'}) && $self->{option_results}->{$_ . '-options'} ne '');
    }
}

my $mapping = {
    name    => { oid => '.1.3.6.1.4.1.789.1.5.8.1.2' }, # volName
    vserver => { oid => '.1.3.6.1.4.1.789.1.5.8.1.14' } # volVserver
};
my $mapping2 = {
    status  => { oid => '.1.3.6.1.4.1.789.1.5.8.1.5' }, # volState
    options => { oid => '.1.3.6.1.4.1.789.1.5.8.1.7' }  # volOptions
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping->{name}->{oid} },
            { oid => $mapping->{vserver}->{oid} }
        ],
        return_type => 1,
        nothing_quit => 1
    );

    $self->{volumes} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /\.([0-9]+)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        my $name = defined($result->{vserver}) && $result->{vserver} ne '' ?
            $result->{vserver} . ':' . $result->{name} :
            $result->{name};
        if (defined($self->{option_results}->{filter_vserver}) && $self->{option_results}->{filter_vserver} ne '' &&
            $result->{vserver} !~ /$self->{option_results}->{filter_vserver}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        
        $self->{volumes}->{$instance} = {
            display => $name
        };
    }

    if (scalar(keys %{$self->{volumes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No volume found.");
        $self->{output}->option_exit();
    }

    my $load_oids = [$mapping2->{status}->{oid}];
    push @$load_oids, $mapping2->{options}->{oid} if ($self->{test_option} == 1);
    $options{snmp}->load(oids => $load_oids, instances => [keys %{$self->{volumes}}]);
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    $self->{global} = { failed => 0 };
    foreach (keys %{$self->{volumes}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => $_);
        if (defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status} ne '' &&
            $result->{status} !~ /$self->{option_results}->{filter_status}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $self->{volumes}->{$_}->{name} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{volumes}->{$_}->{status} = $result->{status};
        $self->{volumes}->{$_}->{options} = $result->{options};
    }
}

1;

__END__

=head1 MODE

Check options from volumes.

=over 8

=item B<--filter-vserver>

Filter volumes by vserver name (can be a regexp).

=item B<--filter-name>

Filter on volume name (can be a regexp).

=item B<--filter-status>

Filter on volume status (can be a regexp).

=item B<--unknown-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--unknown-options>

Set warning threshold for status (Default: '').
Can used special variables like: %{options}, %{display}

=item B<--warning-options>

Set warning threshold for status (Default: '').
Can used special variables like: %{options}, %{display}

=item B<--critical-options>

Set critical threshold for status (Default: '').
Can used special variables like: %{options}, %{display}

=back

=cut
    
