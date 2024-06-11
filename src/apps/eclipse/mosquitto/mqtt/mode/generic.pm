#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package apps::eclipse::mosquitto::mqtt::mode::generic;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use Time::HiRes qw(time);
use POSIX qw(floor);

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'topic:s'      => { name => 'topic' },
        'label:s'      => { name => 'label' },
        'data-regex:s' => { name => 'data_regex' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($options{option_results}->{topic})) {
        $self->{output}->add_option_msg(short_msg => 'Missing parameter --topic.');
        $self->{output}->option_exit();
    }
    $self->{topic} = $options{option_results}->{topic};

    if (!defined($options{option_results}->{label})) {
        $self->{label} = $self->{topic} =~ s/[^a-zA-Z0-9]/_/gr;
    } else {
        $self->{label} = $options{option_results}->{label};
    }
    $self->{data_regex} = $options{option_results}->{data_regex};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'generic',
          set   => {
              key_values                     => [{ name => 'generic' }],
              closure_custom_output          => $self->can('custom_generic_output'),
              closure_custom_perfdata        => $self->can('custom_generic_perfdata')
          }
        }
    ];
}

sub custom_generic_output {
    my ($self, %options) = @_;

    return sprintf(
        $self->{instance_mode}->{label} . ' is: %s',
        $self->{result_values}->{generic}
    );
}

sub custom_generic_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label    => $self->{instance_mode}->{label},
        nlabel   => $self->{instance_mode}->{label},
        value    => $self->{result_values}->{generic},
        warning  => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min      => 0
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    my %results = $options{mqtt}->query(
        topic => $self->{topic}
    );

    my $data = $results{$self->{topic}};
    if (defined($options{option_results}->{data_regex}) and $data =~ /data_regex/) {
        $data = $1;
    }

    if (!defined($data)) {
        $self->{output}->add_option_msg(short_msg => "Cannot find information");
        $self->{output}->option_exit();
    }

    $self->{global} = { generic => $data };
}

1;

__END__

=head1 MODE

Check a topic.

=over 8

=item B<--warning-generic>

Warning threshold.

=item B<--critical-generic>

Critical threshold.

=back

=cut