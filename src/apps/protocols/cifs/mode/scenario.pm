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

package apps::protocols::cifs::mode::scenario;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Time::HiRes qw(gettimeofday tv_interval);
use JSON::XS;

sub custom_step_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s [message: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{message}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Scenario ';
}

sub prefix_step_output {
    my ($self, %options) = @_;

    return "Step '" . $options{instance_value}->{label} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'steps', type => 1, cb_prefix_output => 'prefix_step_output', message_multiple => 'All steps are ok', sort_method => 'num' }
    ];

    $self->{maps_counters}->{global} = [
        { 
            label => 'status', 
            type => 2,
            critical_default => '%{status} ne "success"',
            set => {
                key_values => [ { name => 'status' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'total-time', nlabel => 'scenario.execution.time.milliseconds', set => {
                key_values => [ { name => 'time_taken' } ],
                output_template => 'execution time: %d ms',
                perfdatas => [
                    { template => '%d', min => 0, unit => 'ms' }
                ]
            }
        },
        { label => 'total-steps', nlabel => 'scenario.steps.count', display_ok => 0, set => {
                key_values => [ { name => 'total_steps' } ],
                output_template => 'total steps: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'errors', nlabel => 'scenario.errors.count', set => {
                key_values => [ { name => 'errors' } ],
                output_template => 'errors: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{steps} = [
        { label => 'step-time', nlabel => 'step.execution.time.milliseconds', set => {
                key_values => [ { name => 'time_taken' }, { name => 'label' } ],
                output_template => 'execution time: %d ms',
                perfdatas => [
                    { template => '%d', min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'label' }
                ]
            }
        },
        { 
            label => 'step-status', 
            type => 2,
            set => {
                key_values => [ { name => 'status' }, { name => 'message' } ],
                closure_custom_output => $self->can('custom_step_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'scenario:s' => { name => 'scenario' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    # Example of a scenario file:
    # [
    #  {"cmd": "write", "label": "write", "options": { "file": "/test/test.txt", "content": "my string 1" } },
    #  {"cmd": "read", "options": { "file": "/test/test.txt", "match": "string" } },
    #  {"cmd": "delete", "options": { "file": "/test/test.txt" } }
    #]
    if (!defined($self->{option_results}->{scenario})) { 
        $self->{output}->add_option_msg(short_msg => 'Please specify scenario option');
        $self->{output}->option_exit();
    }
}

sub slurp_file {
    my ($self, %options) = @_;

    my $content = do {
        local $/ = undef;
        if (!open my $fh, '<', $options{file}) {
            $self->{output}->add_option_msg(short_msg => "Could not open file $options{file}: $!");
            $self->{output}->option_exit();
        }
        <$fh>;
    };

    return $content;
}

sub read_scenario {
    my ($self, %options) = @_;

    my $content;
    if ($self->{option_results}->{scenario} =~ /\n/m || ! -f "$self->{option_results}->{scenario}") {
        $content = $self->{option_results}->{scenario};
    } else {
        $content = $self->slurp_file(file => $self->{option_results}->{scenario});
    }

    eval {
        $self->{scenario} = JSON::XS->new->decode($content);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => "json config error: $@", debug => 1);
        $self->{output}->add_option_msg(short_msg => 'Cannot decode json config');
        $self->{output}->option_exit();
    }

    if (ref($self->{scenario}) ne 'ARRAY') {
        $self->{output}->add_option_msg(short_msg => 'scenario format error: expected an array');
        $self->{output}->option_exit();
    }
    foreach (@{$self->{scenario}}) {
        if ($_->{cmd} =~ /^(?:read|write|delete)$/) {
            if (!defined($_->{options}->{file}) || $_->{options}->{file} eq '') {
                $self->{output}->add_option_msg(short_msg => 'scenario format error: set file option');
                $self->{output}->option_exit();
            }
        } else {
            $self->{output}->add_option_msg(short_msg => 'scenario format error: unknown command ' . $_->{cmd});
            $self->{output}->option_exit();
        }
    }
}

sub failed {
    my ($self, %options) = @_;

    $self->{global}->{status} = 'failed';
    $self->{global}->{errors}++;
    $self->{steps}->{ $options{num} }->{status} = 'failed';
    $self->{steps}->{ $options{num} }->{message} = $options{message};
}

sub read {
    my ($self, %options) = @_;

    my ($rv, $message, $data) = $options{custom}->read_file(file => $options{file});
    if ($rv) {
        $self->failed(num => $options{num}, message => $message);
        return ;
    }

    if (defined($options{match}) && $data !~ /$options{match}/) {
        $self->failed(num => $options{num}, message => 'matching failed');
    }
}

sub write {
    my ($self, %options) = @_;

    my ($rv, $message) = $options{custom}->write_file(
        file => $options{file},
        content => $options{content}
    );
    if ($rv) {
        $self->failed(num => $options{num}, message => $message);
        return ;
    }
}

sub delete {
    my ($self, %options) = @_;

    my ($rv, $message) = $options{custom}->delete_file(file => $options{file});
    if ($rv) {
        $self->failed(num => $options{num}, message => $message);
        return ;
    }
}

sub execute_scenario {
    my ($self, %options) = @_;

    $self->{steps} = {};
    my $num = 1;
    foreach my $step (@{$self->{scenario}}) {
        my $label = defined($step->{label}) && $step->{label} ne '' ? $step->{label} : $num;
        $self->{steps}->{$num} = { label => $label, status => 'success', message => '-' };

        my $timing0 = [gettimeofday];
        if ($step->{cmd} eq 'read') {
            $self->read(num => $num, custom => $options{custom}, %{$step->{options}});
        } elsif ($step->{cmd} eq 'write') {
            $self->write(num => $num, custom => $options{custom}, %{$step->{options}});
        } elsif ($step->{cmd} eq 'delete') {
            $self->delete(num => $num, custom => $options{custom}, %{$step->{options}});
        }
        $self->{steps}->{$num}->{time_taken} = tv_interval($timing0, [gettimeofday]) * 1000;

        $num++;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->read_scenario();

    $self->{global} = {
        status => 'success',
        total_steps => scalar(@{$self->{scenario}}),
        errors => 0,
        time_taken => 0
    };

    $self->execute_scenario(custom => $options{custom});

    foreach (values %{$self->{steps}}) {
        $self->{global}->{time_taken} += $_->{time_taken};
    }
}

1;

__END__

=head1 MODE

Execute sftp commands.

=over 8

=item B<--scenario>

Scenario used (required).
Can be a file or json content.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} ne "success"')
You can use the following variables: %{status}

=item B<--warning-step-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{message}

=item B<--critical-step-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{status}, %{message}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-time', 'total-steps', 'errors', 'step-time'.

=back

=cut
