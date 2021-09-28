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

package apps::nginx::serverstatus::mode::requests;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use POSIX;
use Digest::MD5 qw(md5_hex);

sub custom_requests_perfdata {
    my ($self, %options) = @_;

    my $nlabel = $self->{nlabel};
    if (defined($self->{instance_mode}->{option_results}->{per_minute})) {
        $nlabel =~ s/persecond/perminute/;
    }
    $self->{output}->perfdata_add(
        nlabel => $nlabel,
        value => sprintf('%.2f', $self->{result_values}->{value}),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_requests_calc {
    my ($self, %options) = @_;

    my $diff_value = ($options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{metric} } - $options{old_datas}->{ $self->{instance} . '_' . $options{extra_options}->{metric} });
    $self->{result_values}->{value} = $diff_value / $options{delta_time};
    if (defined($self->{instance_mode}->{option_results}->{per_minute})) {
        $self->{result_values}->{value} = $diff_value / ceil($options{delta_time} / 60);
    }
    $self->{result_values}->{output_str} = sprintf(
        $options{extra_options}->{output_str} . (defined($self->{instance_mode}->{option_results}->{per_minute}) ? '/min' : '/s'),
        $self->{result_values}->{value}
    );
    return 0;
}

sub custom_dropped_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{dropped} =
        ($options{new_datas}->{ $self->{instance} . '_accepts' } - $options{old_datas}->{ $self->{instance} . '_accepts' }) -
        ($options{new_datas}->{ $self->{instance} . '_handled' } - $options{old_datas}->{ $self->{instance} . '_handled' });
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'connections-accepted', nlabel => 'server.connections.accepted.persecond', set => {
                key_values => [ { name => 'accepts', diff => 1 }  ],
                closure_custom_calc => $self->can('custom_requests_calc'),
                closure_custom_calc_extra_options => { metric => 'accepts', output_str => 'connections accepted: %.2f' },
                output_template => '%s',
                output_use => 'output_str', threshold_use => 'value',
                closure_custom_perfdata => $self->can('custom_requests_perfdata')
            }
        },
        { label => 'connections-handled', nlabel => 'server.connections.handled.persecond', set => {
                key_values => [ { name => 'handled', diff => 1 }  ],
                closure_custom_calc => $self->can('custom_requests_calc'),
                closure_custom_calc_extra_options => { metric => 'handled', output_str => 'connections handled: %.2f' },
                output_template => '%s',
                output_use => 'output_str', threshold_use => 'value',
                closure_custom_perfdata => $self->can('custom_requests_perfdata')
            }
        },
        { label => 'connections-dropped', nlabel => 'server.connections.dropped.count', set => {
                key_values => [ { name => 'accepts', diff => 1 }, { name => 'handled', diff => 1 } ],
                closure_custom_calc => $self->can('custom_dropped_calc'),
                output_template => 'connections dropped: %d',
                output_use => 'dropped', threshold_use => 'dropped',
                perfdatas => [
                    { value => 'dropped', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'requests', nlabel => 'server.requests.persecond', set => {
                key_values => [ { name => 'requests', diff => 1 } ],
                closure_custom_calc => $self->can('custom_requests_calc'),
                closure_custom_calc_extra_options => { metric => 'requests', output_str => 'requests: %.2f' },
                output_template => '%s',
                output_use => 'output_str', threshold_use => 'value',
                closure_custom_perfdata => $self->can('custom_requests_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'per-minute'  => { name => 'per_minute' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->{maps_counters}->{global}->[0]->{nlabel} = 'toto';
    $self->SUPER::check_options(%options);

}

sub manage_selection {
    my ($self, %options) = @_;

    my $content = $options{custom}->get_status();
    if ($content !~ /server accepts handled requests.*?(\d+)\s+(\d+)\s+(\d+)/msi) {
        $self->{output}->add_option_msg(short_msg => 'Cannot find request informations.');
        $self->{output}->option_exit();
    }
    $self->{global} = {
        accepts => $1,
        handled => $2,
        requests => $3
    };

    $self->{cache_name} = 'nginx_' . $self->{mode} . '_' . md5_hex($options{custom}->get_connection_info()) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check Nginx request statistics.

=over 8

=item B<--per-minute>

Per second metrics are computed per minute.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'connections-accepted', 'connections-handled', 'requests'.

=back

=cut
