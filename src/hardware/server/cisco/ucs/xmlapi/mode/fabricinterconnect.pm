#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package hardware::server::cisco::ucs::xmlapi::mode::fabricinterconnect;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);

sub custom_status_output {
    my ($self, %options) = @_;
    return sprintf(
        "fabric interconnect '%s' [model: %s] role is '%s', operability is '%s'",
        $self->{result_values}->{id},
        $self->{result_values}->{model},
        $self->{result_values}->{role},
        $self->{result_values}->{oper_state}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'fis',    type => 1, cb_prefix_output => 'prefix_output',
          message_multiple => 'All fabric interconnects are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'fabricinterconnects.total.count', set => {
            key_values      => [ { name => 'total' } ],
            output_template => 'Total fabric interconnects: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
    ];

    $self->{maps_counters}->{fis} = [
        { label => 'status', type => 2,
          set => {
            key_values => [
                { name => 'id' }, { name => 'role' }, { name => 'oper_state' },
                { name => 'model' }, { name => 'mgmt_ip' },
            ],
            closure_custom_output           => $self->can('custom_status_output'),
            closure_custom_perfdata         => sub { return 0; },
            closure_custom_threshold_check => \&_threshold_check,
          }
        },
    ];
}

sub _threshold_check {
    my ($self, %options) = @_;

    if (defined($self->{instance_mode}->{option_results}->{critical_status})
        && $self->{instance_mode}->{option_results}->{critical_status} ne '') {
        my %rv = %{$self->{result_values}};
        my ($id, $role, $oper_state) = ($rv{id}, $rv{role}, $rv{oper_state});
        ## no critic
        return 'CRITICAL' if eval "$self->{instance_mode}->{option_results}->{critical_status}";
    }
    if (defined($self->{instance_mode}->{option_results}->{warning_status})
        && $self->{instance_mode}->{option_results}->{warning_status} ne '') {
        my %rv = %{$self->{result_values}};
        my ($id, $role, $oper_state) = ($rv{id}, $rv{role}, $rv{oper_state});
        return 'WARNING' if eval "$self->{instance_mode}->{option_results}->{warning_status}";
    }
    return 'OK';
}

sub prefix_output {
    my ($self, %options) = @_;
    return "Fabric interconnect '" . $options{instance_value}->{id} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'warning-status:s'  => { name => 'warning_status',  default => '' },
        'critical-status:s' => { name => 'critical_status',
            default => '%{oper_state} !~ /^operable$/i' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $fis = $options{custom}->request(class_id => 'networkElement');

    $self->{global} = { total => 0 };
    $self->{fis}    = {};

    foreach my $fi (@{$fis}) {
        my $id         = $fi->{id}         // $fi->{dn}       // 'unknown';
        my $role       = $fi->{role}       // 'unknown';
        my $oper_state = $fi->{operState}  // 'unknown';
        my $model      = $fi->{model}      // 'unknown';
        my $mgmt_ip    = $fi->{oobIfIp}   // $fi->{mgmtIp}   // '';

        $self->{global}->{total}++;
        $self->{fis}->{$id} = {
            id         => $id,
            role       => $role,
            oper_state => $oper_state,
            model      => $model,
            mgmt_ip    => $mgmt_ip,
        };
    }

    if (scalar(keys %{$self->{fis}}) == 0) {
        $self->{output}->add_option_msg(short_msg => 'No fabric interconnects found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Cisco UCS Fabric Interconnect status via XML API (networkElement class).

=over 8

=item B<--warning-status>

Warning threshold. Perl expression using %{id}, %{role}, %{oper_state}.
Default: ''

=item B<--critical-status>

Critical threshold. Perl expression using %{id}, %{role}, %{oper_state}.
Default: '%{oper_state} !~ /^operable$/i'

Example: --critical-status='%{role} ne "primary" && %{oper_state} ne "operable"'

=back

=cut
