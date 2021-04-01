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

package hardware::devices::cisco::ces::restapi::mode::certificates;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub custom_validity_output {
    my ($self, %options) = @_;

    return sprintf(
        'expires in %s', 
        $self->{result_values}->{generation_time}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'certificates', type => 1, cb_prefix_output => 'prefix_certificate_output', message_multiple => 'All certificates are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{certificates} = [
        { label => 'certificate-expire', nlabel => 'system.certificate.expire.seconds', set => {
                key_values => [ { name => 'validity_time' }, { name => 'generation_time' } ],
                closure_custom_output => $self->can('custom_validity_output'),
                perfdatas => [
                    { template => '%d', min => 0, unit => 's' }
                ]
            }
        }
    ];
}

sub prefix_certificate_output {
    my ($self, %options) = @_;

    return "Certificate '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
    });

    centreon::plugins::misc::mymodule_load(
        output => $self->{output},
        module => 'Date::Parse',
        error_msg => "Cannot load module 'Date::Parse'."
    );
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        method => 'POST',
        url_path => '/putxml',
        query_form_post => '<Command><Security><Certificates><Services><Show/></Services></Certificates></Security></Command>',
        ForceArray => ['Details']
    );

    $self->{certificates} = {};
    if (defined($result->{ServicesShowResult}->{Details})) {
        foreach (@{$result->{ServicesShowResult}->{Details}}) {
            my $end_date = Date::Parse::str2time($_->{notAfter});
            if (!defined($end_date)) {
                $self->{output}->output_add(
                    severity => 'UNKNOWN',
                    short_msg => "can't parse date '" . $_->{notAfter} . "'"
                );
                next;
            }

            $self->{certificates}->{$_->{item}} = {
                display => $_->{SubjectName},
                validity_time => $end_date - time(),
                generation_time => centreon::plugins::misc::change_seconds(value => $end_date - time())
            };
        }
    }

    if (scalar(keys %{$self->{certificates}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No certificate found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check certificates validity (since CE 9.2)

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'certificate-expire'.

=back

=cut
