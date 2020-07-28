#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package centreon::plugins::templates::catalog_functions;

use strict;
use warnings;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(catalog_status_threshold catalog_status_threshold_ng catalog_status_calc);

sub catalog_status_threshold {
    my ($self, %options) = @_;
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        my $label = $self->{label};
        $label =~ s/-/_/g;
        if (defined($self->{instance_mode}->{option_results}->{'ok_' . $label}) && $self->{instance_mode}->{option_results}->{'ok_' . $label} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{'ok_' . $label}") {
            $status = 'ok';
        } elsif (defined($self->{instance_mode}->{option_results}->{'critical_' . $label}) && $self->{instance_mode}->{option_results}->{'critical_' . $label} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{'critical_' . $label}") {
            $status = 'critical';
        } elsif (defined($self->{instance_mode}->{option_results}->{'warning_' . $label}) && $self->{instance_mode}->{option_results}->{'warning_' . $label} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{'warning_' . $label}") {
            $status = 'warning';
        } elsif (defined($self->{instance_mode}->{option_results}->{'unknown_' . $label}) && $self->{instance_mode}->{option_results}->{'unknown_' . $label} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{'unknown_' . $label}") {
            $status = 'unknown';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub catalog_status_threshold_ng {
    my ($self, %options) = @_;
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        my $label = $self->{label};
        if (defined($self->{instance_mode}->{option_results}->{'critical-' . $self->{label}}) && $self->{instance_mode}->{option_results}->{'critical-' . $label} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{'critical-' . $self->{label}}") {
            $status = 'critical';
        } elsif (defined($self->{instance_mode}->{option_results}->{'warning-' . $label}) && $self->{instance_mode}->{option_results}->{'warning-' . $label} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{'warning-' . $label}") {
            $status = 'warning';
        } elsif (defined($self->{instance_mode}->{option_results}->{'unknown-' . $label}) && $self->{instance_mode}->{option_results}->{'unknown-' . $label} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{'unknown-' . $label}") {
            $status = 'unknown';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub catalog_status_calc {
    my ($self, %options) = @_;

    foreach (keys %{$options{new_datas}}) {
        if (/^\Q$self->{instance}\E_(.*)/) {
            $self->{result_values}->{$1} = $options{new_datas}->{$_};
        }
    }
}

1;

__END__

