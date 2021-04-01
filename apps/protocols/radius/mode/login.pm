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

package apps::protocols::radius::mode::login;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use Authen::Radius;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'Radius Access Request Status: ' . $self->{result_values}->{status} . 
        ' [error msg: ' . $self->{result_values}->{error_msg} . ']';
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{error_msg} = $options{new_datas}->{$self->{instance} . '_error_msg'};
    $self->{result_values}->{attributes} = $self->{instance_mode}->{radius_result_attributes};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'radius', type => 0, message_separator => ' - ' }
    ];

    $self->{maps_counters}->{radius} = [
        { 
            label => 'status', 
            type => 2,
            critical_default => '%{status} ne "accepted"',
            set => {
                key_values => [ { name => 'status' }, { name => 'error_msg' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'time', nlabel => 'radius.response.time.seconds', set => {
                key_values => [ { name => 'elapsed' } ],
                output_template => 'Response time : %.3f second(s)',
                perfdatas => [
                    { label => 'time', template => '%.3f', min => 0, unit => 's' }
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
        'hostname:s'       => { name => 'hostname' },
        'port:s'           => { name => 'port', default => 1812 },
        'secret:s'         => { name => 'secret' },
        'username:s'       => { name => 'username' },
        'password:s'       => { name => 'password' },
        'warning:s'        => { name => 'warning' },
        'critical:s'       => { name => 'critical' },
        'timeout:s'        => { name => 'timeout', default => 5 },
        'retry:s'          => { name => 'retry', default => 0 },
        'radius-attribute:s%'  => { name => 'radius_attribute' },
        'radius-dictionary:s@' => { name => 'radius_dictionary' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    my @mandatory = ('hostname', 'secret');
    push @mandatory, 'username', 'password' if (!defined($self->{option_results}->{radius_attribute}));
    foreach (@mandatory) {
        if (!defined($self->{option_results}->{$_})) {
            $self->{output}->add_option_msg(short_msg => "Please set the " . $_ . " option");
            $self->{output}->option_exit();
        }
    }

    $self->{radius_dictionary} = [];
    if (defined($self->{option_results}->{radius_attribute})) {
        $self->{radius_dictionary} = $self->{option_results}->{radius_attribute};
    }
    
    $self->{option_results}->{retry} = 0 if (!defined($self->{option_results}->{retry}) || $self->{option_results}->{retry} !~ /^\d+$/);
    if (defined($self->{option_results}->{port}) && $self->{option_results}->{port} =~ /^\d+$/) {
        $self->{option_results}->{hostname} .= ':' . $self->{option_results}->{port};
    }
}

sub radius_simple_connection {
    my ($self, %options) = @_;

    $self->{timing0} = [gettimeofday];
    my $retry = 0;
    while ($retry <= $self->{option_results}->{retry}) {
        if ($self->{radius_session}->check_pwd($self->{option_results}->{username}, $self->{option_results}->{password})) {
            $self->{radius}->{status} = 'accepted';
            last;
        }

        if ($retry + 1 > $self->{option_results}->{retry}) {
            $self->{radius}->{status} = 'rejected';
            $self->{radius}->{error_msg} = $self->{radius_session}->strerror(); 
        }
        $retry++;
    }
}

sub radius_attr_connection {
    my ($self, %options) = @_;

    my $message;
    eval {
        local $SIG{__WARN__} = sub { $message = join(' - ', @_); };
        local $SIG{__DIE__} = sub { $message = join(' - ', @_); };

        foreach my $dic (@{$self->{radius_dictionary}}) {
            next if ($dic eq '');
            Authen::Radius->load_dictionary($dic);
        }

        foreach (keys %{$self->{option_results}->{radius_attribute}}) {
            $self->{radius_session}->add_attributes({ Name => $_, Value => $self->{option_results}->{radius_attribute}->{$_} });
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => $message, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Issue with dictionary and attributes");
        $self->{output}->option_exit();
    }

    $self->{timing0} = [gettimeofday];
    my $retry = 0;
    while ($retry <= $self->{option_results}->{retry}) {
        my $type;

        if ($self->{radius_session}->send_packet(ACCESS_REQUEST) && ($type = $self->{radius_session}->recv_packet()) == ACCESS_ACCEPT) {
            $self->{radius}->{status} = 'accepted';
            last;
        }

        if ($retry + 1 > $self->{option_results}->{retry}) {
            $self->{radius}->{status} = 'unknown';
            $self->{radius}->{error_msg} = $self->{radius_session}->strerror(); 
            if (defined($type) && $type == ACCESS_REJECT) {
                $self->{radius}->{status} = 'rejected';
            }
        }
        $retry++;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{radius} = { status => 'unknown', error_msg => 'none' };
    $self->{radius_session} = Authen::Radius->new(
        Host => $self->{option_results}->{hostname},
        Secret => $self->{option_results}->{secret},
        TimeOut => $self->{option_results}->{timeout},
    );
    if (!defined($self->{radius_session})) {
        $self->{output}->add_option_msg(short_msg => 'failure: ' . Authen::Radius::strerror());
        $self->{output}->option_exit();
    }

    if (defined($self->{option_results}->{radius_attribute})) {
        $self->radius_attr_connection();
    } else {
        $self->radius_simple_connection();
    }

    $self->{radius}->{elapsed} = tv_interval($self->{timing0}, [gettimeofday]);
    $self->{radius_result_attributes} = {};
    foreach my $attr ($self->{radius_session}->get_attributes()) {
        $self->{radius_result_attributes}->{$attr->{Name}} = defined($attr->{Value}) ? $attr->{Value} : '';
        $self->{output}->output_add(long_msg => 'Attribute Name = ' .  $attr->{Name} . 
            ', Value = ' . (defined($attr->{Value}) ? $attr->{Value} : ''), debug => 1);
    }
}

1;

__END__

=head1 MODE

Check login to a Radius Server.

Example with attributes:
centreon_plugins.pl --plugin=apps/protocols/radius/plugin.pm --mode=login --hostname=192.168.1.2 --secret=centreon --radius-attribute='User-Password=test' --radius-attribute='User-Name=user@test.com' --radius-dictionary=dictionary.txt

=over 8

=item B<--hostname>

IP Addr/FQDN of the radius host

=item B<--port>

Radius port (Default: 1812)

=item B<--secret>

Secret of the radius host

=item B<--username>

Specify username for authentication

=item B<--password>

Specify password for authentication

=item B<--timeout>

Connection timeout in seconds (Default: 5)

=item B<--retry>

Number of retry connection (Default: 0)

=item B<--radius-attribute>

If you need to add option, please following attributes. 
Option username and password should be set with that option.
Example: --radius-attribute="User-Password=test"

=item B<--radius-dictionary>

Set radius-dictionary file (mandatory with --radius-attribute) (multiple option).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{error_msg}, %{attributes}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} ne "accepted"').
Can used special variables like: %{status}, %{error_msg}, %{attributes}.

=item B<--warning-time>

Threshold warning in seconds

=item B<--critical-time>

Threshold critical in seconds

=back

=cut
