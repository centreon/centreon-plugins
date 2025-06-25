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

package os::as400::connector::mode::pagefaults;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_page_perfdata {
    my ($self, %options) = @_;

    if ($self->{instance_mode}->{option_results}->{units} =~ /percent/) {
        my $nlabel = $self->{nlabel};
        $nlabel =~ s/count$/percentage/;

        $self->{output}->perfdata_add(
            nlabel => $nlabel,
            unit => '%',
            value => sprintf('%.2f', $self->{result_values}->{prct}),
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
            min => 0,
            max => 100
        );
    } else {
        $self->{output}->perfdata_add(
            nlabel => $self->{nlabel},
            value => $self->{result_values}->{used},
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
            min => 0,
            max => $self->{result_values}->{total}
        );
    }
}

sub custom_page_threshold {
    my ($self, %options) = @_;

    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{units} =~ /percent/) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } else {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{used}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_page_output {
    my ($self, %options) = @_;

    return sprintf(
        '%s page faults: %.2f%% (%s on %s)',
        $self->{result_values}->{label},
        $self->{result_values}->{prct},
        $self->{result_values}->{used},
        $self->{result_values}->{total}
    );
}

sub custom_page_calc {
    my ($self, %options) = @_;

    my $total = $options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} };
    my $total_diff = $options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} } -  $options{old_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} };
    my $page = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref} . '_fault'};
    my $page_diff = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref} . '_fault'} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref} . '_fault'};

    $self->{result_values}->{prct} = 0;
    $self->{result_values}->{used} = $page_diff;
    $self->{result_values}->{total} = $total_diff;
    if ($self->{instance_mode}->{option_results}->{units} eq 'percent_delta') {
        $self->{result_values}->{prct} = $page_diff * 100 / $total_diff if ($total_diff > 0);
    } elsif ($self->{instance_mode}->{option_results}->{units} eq 'percent') {
        $self->{result_values}->{prct} = $page * 100 / $total if ($total > 0);
        $self->{result_values}->{used} = $page;
        $self->{result_values}->{total} = $total;
    } elsif ($self->{instance_mode}->{option_results}->{units} eq 'delta') {
        $self->{result_values}->{prct} = $page_diff * 100 / $total_diff if ($total_diff > 0);
        $self->{result_values}->{used} = $page_diff;
    } else {
        $self->{result_values}->{prct} = $page * 100 / $total if ($total > 0);
        $self->{result_values}->{used} = $page;
        $self->{result_values}->{total} = $total;
    }

    $self->{result_values}->{label} = $options{extra_options}->{label};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 }  }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'pagefaults-database', nlabel => 'pagefaults.database.ratio.count', set => {
                key_values => [ { name => 'db_page', diff => 1 }, { name => 'db_page_fault', diff => 1 } ],
                closure_custom_calc => $self->can('custom_page_calc'), closure_custom_calc_extra_options => { label => 'database', label_ref => 'db_page' },
                closure_custom_output => $self->can('custom_page_output'), output_error_template => 'database page faults: %s',
                closure_custom_perfdata => $self->can('custom_page_perfdata'),
                closure_custom_threshold_check => $self->can('custom_page_threshold')
            }
        },
        { label => 'pagefaults-nondatabase', nlabel => 'pagefaults.nondatabase.ratio.count', set => {
                key_values => [ { name => 'non_db_page', diff => 1 }, { name => 'non_db_page_fault', diff => 1 } ],
                closure_custom_calc => $self->can('custom_page_calc'), closure_custom_calc_extra_options => { label => 'nondatabase', label_ref => 'non_db_page' },
                closure_custom_output => $self->can('custom_page_output'), output_error_template => 'nondatabase page faults: %s',
                closure_custom_perfdata => $self->can('custom_page_perfdata'),
                closure_custom_threshold_check => $self->can('custom_page_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'units:s' => { name => 'units', default => 'percent' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{units} = 'percent'
        if (!defined($self->{option_results}->{units}) ||
            $self->{option_results}->{units} eq '' ||
            $self->{option_results}->{units} eq '%');
    if ($self->{option_results}->{units} !~ /^(?:percent|percent_delta|delta|counter)$/) {
        $self->{output}->add_option_msg(short_msg => 'Wrong option --units.');
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $pools = $options{custom}->request_api(command => 'pageFault');

    my ($db_page_fault, $db_page, $non_db_page_fault, $non_db_page) = (0, 0, 0, 0);
    foreach my $entry (@{$pools->{result}}) {
        $db_page_fault += $entry->{dbPageFault};
        $db_page += $entry->{dbPage};
        $non_db_page_fault += $entry->{nonDbPageFault};
        $non_db_page += $entry->{nonDbPage};
    }

    $self->{global} = {
        db_page => $db_page,
        db_page_fault => $db_page_fault,
        non_db_page_fault => $non_db_page_fault,
        non_db_page => $non_db_page
    };

    $self->{cache_name} = 'as400_' . $options{custom}->get_hostname() . '_' . $self->{mode} . '_' .
        md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '')
        );
}

1;

__END__

=head1 MODE

Check page faults.

=over 8

=item B<--units-errors>

Units of thresholds (default: 'percent') ('percent_delta', 'percent', 'delta', 'counter').

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'pagefaults-database', 'pagefaults-nondatabase'.

=back

=cut
