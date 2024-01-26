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

package network::chapsvision::crossing::snmp::mode::antivirus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use DateTime::Format::Strptime;
use DateTime;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use POSIX;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_database_output {
    my ($self, %options) = @_;

    return sprintf(
        "database last update %s",
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{db_lastupdate_time})
    );
}

sub custom_license_perfdata {
    my ($self, %options) = @_;

    return if ($self->{result_values}->{expires_seconds} eq 'permanent');

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        unit => $self->{instance_mode}->{option_results}->{unit},
        instances => $self->{result_values}->{name},
        value => floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_license_threshold {
    my ($self, %options) = @_;

    return 'ok' if ($self->{result_values}->{expires_seconds} eq 'permanent');
    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub custom_license_output {
    my ($self, %options) = @_;

    my $message;
    if ($self->{result_values}->{expires_seconds} eq 'permanent') {
        $message = 'permanent license';
    } else {
        $message = sprintf(
            "license expires in %s",
            $self->{result_values}->{expires_human}
        );
    }

    return $message;
}

sub custom_version_output {
    my ($self, %options) = @_;

    return sprintf(
        "version: %s",
        $self->{result_values}->{version}
    );
}

sub prefix_antivirus_output {
    my ($self, %options) = @_;

    return "antivirus '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'antivirus', type => 1, cb_prefix_output => 'prefix_antivirus_output', message_multiple => 'All antivirus are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{antivirus} = [
         {
             label => 'version',
             type => 2,
             set => {
                key_values => [ { name => 'name' }, { name => 'version' } ],
                closure_custom_output => $self->can('custom_version_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'database-last-update', nlabel => 'antivirus.database.lastupdate.seconds', set => {
                key_values      => [ { name => 'db_lastupdate_time' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_database_output'),
                perfdatas => [
                    { template => '%s', min => 0, unit => 's' }
                ]
            }
        },
        { label => 'license-expires', nlabel => 'antivirus.license.expires', set => {
                key_values      => [ { name => 'expires_seconds' }, { name => 'expires_human' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_license_output'),
                closure_custom_perfdata => $self->can('custom_license_perfdata'),
                closure_custom_threshold_check => $self->can('custom_license_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'antivirus1-date-format:s' => { name => 'antivirus1_date_format' },
        'antivirus2-date-format:s' => { name => 'antivirus2_date_format' },
        'unit:s'                   => { name => 'unit', default => 's' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{antivirus1_strp} = DateTime::Format::Strptime->new(
        pattern  => defined($self->{option_results}->{antivirus1_date_format}) && $self->{option_results}->{antivirus1_date_format} ne '' ? $self->{option_results}->{antivirus1_date_format} : '%Y/%m/%d',
        on_error => 'undef'
    );
    $self->{antivirus2_strp} = DateTime::Format::Strptime->new(
        pattern  => defined($self->{option_results}->{antivirus2_date_format}) && $self->{option_results}->{antivirus2_date_format} ne '' ? $self->{option_results}->{antivirus2_date_format} : '%Y/%m/%d',
        on_error => 'undef'
    );

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }
}

my $mapping = {
    antivirus1 => {
        name       => '.1.3.6.1.4.1.50853.1.2.6.1.1',
        version    => '.1.3.6.1.4.1.50853.1.2.6.1.2',
        date       => '.1.3.6.1.4.1.50853.1.2.6.1.3',
        expiration => '.1.3.6.1.4.1.50853.1.2.6.1.4'
    },
    antivirus2 => {
        name       => '.1.3.6.1.4.1.50853.1.2.6.2.1',
        version    => '.1.3.6.1.4.1.50853.1.2.6.2.2',
        date       => '.1.3.6.1.4.1.50853.1.2.6.2.3',
        expiration => '.1.3.6.1.4.1.50853.1.2.6.2.4'
    }
};

sub add_antivirus {
    my ($self, %options) = @_;

    my $name = $options{snmp_result}->{ $mapping->{ $options{label} }->{name} };
    $self->{antivirus}->{$name} = {
        name => $name,
        version => $options{snmp_result}->{ $mapping->{ $options{label} }->{version} }
    };

    if ($options{snmp_result}->{ $mapping->{ $options{label} }->{expiration} } =~ /permanent/i) {
        $self->{antivirus}->{$name}->{expires_seconds} = 'permanent';
        $self->{antivirus}->{$name}->{expires_human} = '-';
    } else {
        my $dt = $self->{ $options{label} . '_strp' }->parse_datetime($options{snmp_result}->{ $mapping->{ $options{label} }->{expiration} });
        if (defined($dt)) {
             $self->{antivirus}->{$name}->{expires_seconds} = $dt->epoch() - time();
             $self->{antivirus}->{$name}->{expires_seconds} = 0 if ($self->{antivirus}->{$name}->{expires_seconds} < 0);
             $self->{antivirus}->{$name}->{expires_human} = centreon::plugins::misc::change_seconds(value => $self->{antivirus}->{$name}->{expires_seconds});
        } else {
            $self->{output}->output_add(long_msg => "cannot parse date: " . $options{snmp_result}->{ $mapping->{ $options{label} }->{expiration} } . ' (please use option --' . $options{label} . '-date-format)');
        }
    }

    my $dt = $self->{ $options{label} . '_strp' }->parse_datetime($options{snmp_result}->{ $mapping->{ $options{label} }->{date} });
    if (defined($dt)) {
         $self->{antivirus}->{$name}->{db_lastupdate_time} = time() - $dt->epoch();
    } else {
        $self->{output}->output_add(long_msg => "cannot parse date: " . $options{snmp_result}->{ $mapping->{ $options{label} }->{date} } . ' (please use option --' . $options{label} . '-date-format)');
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_, values(%{$mapping->{antivirus1}}), values(%{$mapping->{antivirus2}})) ],
        nothing_quit => 1
    );

    $self->{antivirus} = {};
    $self->add_antivirus(label => 'antivirus1', snmp_result => $snmp_result);
    $self->add_antivirus(label => 'antivirus2', snmp_result => $snmp_result);
}

1;

__END__

=head1 MODE

Check antivirus.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='version'

=item B<--antivirus1-date-format>

Define the date format for the first antivirus (default: '%Y/%m/%d').

=item B<--antivirus2-date-format>

Define the date format for the second antivirus (default: '%Y/%m/%d').

=item B<--unknown-version>

Define the conditions the version must match for the status to be UNKNOWN.
You can use the following variables: %{version}, %{name}

=item B<--warning-version>

Define the conditions the version must match for the status to be WARNING.
You can use the following variables: %{version}, %{name}

=item B<--critical-version>

Define the conditions the version must match for the status to be CRITICAL.
You can use the following variables: %{version}, %{name}

=item B<--unit>

Select the time unit for the expired license thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'license-expires', 'database-last-update'.

=back

=cut
