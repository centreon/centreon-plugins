#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package centreon::plugins::options;

use Pod::Usage;
use centreon::plugins::misc qw/exprintf/;
use List::Util qw/any/;
use strict;
use warnings;

my $alternative = 1;

sub new {
    my ($class) = @_;
    my $self  = {};
    bless $self, $class;

    # Template for default validation error messages
    $self->{'validation_error_message'} = { DEFAULT => "Bad value provided for option %{option}: '%{value}'. Constraint '%{value}' %{validation} '%{validation_value}' is not verified.",
                                            not_empty => "Need to specify --%{option} option.",
                                            numeric =>  "Bad value provided for option %{option}: '%{value}'. '%{value}' must be a numeric value."
                                          };

    $self->{pod_where_loaded} = 0;
    $self->{sanity} = 0;
    $self->{options_stored} = {};
    $self->{options} = {};
    @{$self->{pod_package}} = ();
    $self->{pod_packages_once} = {};
    $self->{extra_arguments} = [];
    $self->{validation} = {};

    if ($alternative == 0) {
        require Getopt::Long;
        Getopt::Long->import();
        Getopt::Long::Configure("pass_through");
        Getopt::Long::Configure('bundling');
        Getopt::Long::Configure('no_auto_abbrev');
    } else {
        require centreon::plugins::alternative::Getopt;
        $centreon::plugins::alternative::Getopt::warn_message = 0;
        centreon::plugins::alternative::Getopt->import();
    }

    return $self;
}

sub set_sanity {
    my ($self, %options) = @_;

    if ($alternative == 0) {
        Getopt::Long::Configure('no_pass_through');
    } else {
        $centreon::plugins::alternative::Getopt::warn_message = 1;
    }

    $self->{sanity} = 1;
}

sub set_output {
    my ($self, %options) = @_;

    $self->{output} = $options{output};
}

sub display_help {
    my ($self, %options) = @_;

    my $stdout;
    foreach (@{$self->{pod_package}}) {
        my $where = $self->pod_where(package => $_->{package});

        {
            local *STDOUT;
            open STDOUT, '>', \$stdout;
            pod2usage(
                -exitval => 'NOEXIT', -input => $where,
                -verbose => 99, 
                -sections => $_->{sections}
            ) if (defined($where));
        }

        $self->{output}->add_option_msg(long_msg => $stdout) if (defined($stdout));
    }
}

sub add_help {
    my ($self, %options) = @_;
    # $options{package} = string package
    # $options{sections} = string sections
    # $options{help_first} = put at the beginning
    # $options{once} = put help only one time for a package

    if (defined($options{once}) && defined($self->{pod_packages_once}->{$options{package}})) {
        return ;
    }

    if (defined($options{help_first})) {
        unshift @{$self->{pod_package}}, {package => $options{package}, sections => $options{sections}};
    } else {
        push @{$self->{pod_package}}, { package => $options{package}, sections => $options{sections} };
    }

    $self->{pod_packages_once}->{$options{package}} = 1;
}

sub add_options {
    my ($self, %options) = @_;
    # $options{arguments} = ref to hash table with string and name to store (example: { 'mode:s' => { name => 'mode', default => 'defaultvalue' )

    foreach my $arg (keys %{$options{arguments}}) {
        if (defined($options{arguments}->{$arg}->{redirect})) {
            $self->{options}->{$arg} = \$self->{options_stored}->{$options{arguments}->{$arg}->{redirect}};
            next;
        }
        my $opt_name = $options{arguments}->{$arg}->{name};

        # handle option validation hints
        for my $control ('greater_than', 'less_than', 'greater_than_or_equal', 'less_than_or_equal', 'regexp_match', 'is_in', 'error_message', 'not_empty', 'numeric' ) {
            if (defined($options{arguments}->{$arg}->{$control})) {
                $self->{validation}->{$opt_name} //= {};
                # store the control to perform as key and the reference value as value
                $self->{validation}->{$opt_name}->{$control} = $options{arguments}->{$arg}->{$control};
            }
        }

        if (defined($options{arguments}->{$arg}->{default})) {
            $self->{options_stored}->{$opt_name} = $options{arguments}->{$arg}->{default};
        } else {
            $self->{options_stored}->{$opt_name} = undef;
        }
        
        $self->{options}->{$arg} = \$self->{options_stored}->{$opt_name};
    }
}
sub perform_validation {
    my ($value, $operation, $reference) = @_;
    # if all info is not given, skip the control
    return 0 if $operation && $operation eq 'not_empty' && (!defined $value || $value eq '');
    return 1 unless defined($value) && $value ne ''
                   && defined($operation) && $operation ne ''
                   && defined($reference) && $reference ne '';

    # cases of numeric check
    if ($operation =~ /_than/) {
        # not numeric => not valid
        return 0 if $value !~ /^-?[0-9\.]*$/;
        # control ranges
        return 0 if $operation eq 'greater_than' && $value <= $reference;
        return 0 if $operation eq 'greater_than_or_equal' && $value < $reference;
        return 0 if $operation eq 'less_than' && $value >= $reference;
        return 0 if $operation eq 'less_than_or_equal' && $value > $reference;
        # no range trespassing => valid
        return 1;
    }
    # case of regex check
    return 0 if $operation eq 'regexp_match' && $value !~ /$reference/;
    return 0 if $operation eq 'is_in' && ! any { $value eq $_ } @$reference;
    return 0 if $operation eq 'numeric' && $value !~ /^\d*$/;
    return 1;
}

sub validate_options {
    my ($self, %options) = @_;

    for my $option (sort keys %{$self->{validation}}) {
        next if $option eq 'error_message';
        for my $validation (sort keys %{$self->{validation}->{$option}} ) {
            my $value = $self->{options_stored}->{$option};
            unless (perform_validation($value, $validation, $self->{validation}->{$option}->{$validation})) {
                my $validation_value = ref $self->{validation}->{$option}->{$validation} eq 'ARRAY'
                                         ? join ', ', @{$self->{validation}->{$option}->{$validation}}
                                         : $self->{validation}->{$option}->{$validation};
                my $data = { option => $option =~ s/_/-/gr, value => $value, $option => $value,
                             validation => $validation,
                             validation_value => $validation_value };
                my $msg = exprintf( $self->{validation}->{$option}->{error_message}
                                    // $self->{validation_error_message}->{$validation}
                                    // $self->{validation_error_message}->{'DEFAULT'},
                                    $data );

                $self->{output}->option_exit(short_msg => $msg);
            }
        }
    }
}

sub parse_options {
    my $self = shift;
    #%{$self->{options_stored}} = ();

    my $save_warn_handler;
    if ($self->{sanity} == 1) {
        $save_warn_handler = $SIG{__WARN__};
        $SIG{__WARN__} = sub {
            $self->{output}->add_option_msg(short_msg => $_[0]);
            $self->{output}->option_exit(nolabel => 1);
        };
    }

    # Store all arguments placed after the special argument "--" in the 'extra_arguments' list
    $self->{options}->{'_double_dash_'} = \$self->{extra_arguments};

    GetOptions(
       %{$self->{options}}
    );
    %{$self->{options}} = ();
    $self->validate_options(); # if $self->{sanity};
    $SIG{__WARN__} = $save_warn_handler if ($self->{sanity} == 1);
}

sub pod_where {
    my ($self, %options) = @_;

    if ($self->{pod_where_loaded} == 0) {
        $self->{pod_where_loaded} = 1;
        my ($code) = centreon::plugins::misc::mymodule_load(
            module => 'Pod::Find',
            no_quit => 1
        );
        if ($code) {
            $code = centreon::plugins::misc::mymodule_load(
                module => 'Pod::Simple::Search',
                no_quit => 1
            );
            die "Cannot load module 'Pod::Simple::Search'" if ($code);
            $self->{pod_where_loaded} = 2;
            $self->{pod_simple_search} = Pod::Simple::Search->new();
            $self->{pod_simple_search}->inc(1);
        }
    }

    if ($self->{pod_where_loaded} == 1) {
        return Pod::Find::pod_where({-inc => 1}, $options{package});
    }
    
    return $self->{pod_simple_search}->find($options{package});
}

sub get_option {
    my ($self, %options) = @_;

    return $self->{options_stored}->{$options{argument}};
}

sub get_options {
    my $self = shift;

    return $self->{options_stored};
}

sub clean {
    my $self = shift;

    $self->{options_stored} = {};
}

1;

__END__

=head1 NAME

centreon::plugins::options - Command-line option management and validation

=head1 DESCRIPTION

This module wraps L<Getopt::Long> (or its alternative implementation) to provide
option registration, parsing, and constraint-based validation for Centreon plugins.

=head1 VALIDATION

Constraints are declared alongside options in C<add_options> and evaluated
automatically at the end of C<parse_options>.

    $options->add_options(arguments => {
        'count=i' => {
            name                  => 'count',
            default               => 10,
            greater_than          => 0,
            less_than_or_equal    => 100,
        },
        'pattern=s' => {
            name         => 'pattern',
            regexp_match => '^[a-z]+$',
        },
    });

The following constraint keys are supported:

=over 4

=item B<greater_than> I<number>

The option value must be strictly greater than I<number>.

=item B<greater_than_or_equal> I<number>

The option value must be greater than or equal to I<number>.

=item B<less_than> I<number>

The option value must be strictly less than I<number>.

=item B<less_than_or_equal> I<number>

The option value must be less than or equal to I<number>.

=item B<regexp_match> I<pattern>

The option value must match the regular expression I<pattern>.

=back

For numeric constraints (C<*_than*>), the value is first tested against
C<^-?[0-9\.]*$>; a value that does not look numeric is rejected outright before
the comparison is performed.

If the option value, the constraint key, or the reference value is C<undef> or
an empty string, the constraint is silently skipped (considered valid).

=head1 METHODS

=head2 add_options

    $self->add_options(arguments => \%arguments);

Registers command-line options and their metadata. C<%arguments> is a hash whose
keys are L<Getopt::Long> option specifiers and whose values are hashrefs
describing each option.

    $self->add_options(arguments => {
        'hostname=s' => {
            name    => 'hostname',
        },
        'port=i' => {
            name    => 'port',
            default => 443,
            greater_than => 0,
            less_than => 65536
        },
        'timeout=i' => {
            name                => 'timeout',
            default             => 30,
            greater_than        => 0,
            less_than_or_equal  => 300,
        },
        'pattern=s' => {
            name         => 'pattern',
            regexp_match => '^[a-z]',
        },
        'user=s' => {
            name     => 'user',
            redirect => 'username',   # stores value under 'username' instead
        },
    });

Each option descriptor accepts the following keys:

=over 4

=item B<name> I<string> (required)

The key under which the parsed value is stored and later retrieved via
C<get_option> or C<get_options>.

=item B<default> I<scalar>

Default value assigned before parsing. If omitted the stored value is C<undef>
until the option is provided on the command line.

=item B<redirect> I<string>

Store the value under a different name than the one given by C<name>. When
C<redirect> is set, no default and no validation constraints are registered for
this specifier; it simply aliases to the target key.

=item B<greater_than>, B<greater_than_or_equal>, B<less_than>, B<less_than_or_equal>, B<regexp_match>

Validation constraints evaluated after parsing. See L</VALIDATION> for the full
description of each constraint.

=back

=head2 validate_options

    $self->validate_options();

Iterates over every constraint registered by C<add_options> and calls
C<< $self->{output}->option_exit >> for the first violated constraint.
The error message includes the option name, the offending value, and the
constraint that was not satisfied.

This method is called automatically at the end of C<parse_options>; it does
not need to be called directly in normal usage.

=head1 FUNCTIONS

=head2 perform_validation

    my $ok = centreon::plugins::options::perform_validation($value, $operation, $reference);

Low-level validation primitive used internally by C<validate_options>.
Returns B<1> if the value satisfies the constraint, B<0> otherwise.

If any argument is C<undef> or an empty string, the function returns B<1>
immediately (the check is skipped).

=over 4

=item B<$value>

The value to validate.

=item B<$operation>

The constraint to apply. One of: C<greater_than>, C<greater_than_or_equal>,
C<less_than>, C<less_than_or_equal>, C<regexp_match>.

=item B<$reference>

The threshold (numeric constraints) or pattern (C<regexp_match>) to validate
against.

=back

=cut
