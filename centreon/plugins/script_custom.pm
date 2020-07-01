#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package centreon::plugins::script_custom;

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;
    $self->{options} = $options{options};
    $self->{output} = $options{output};
    
    $self->{options}->add_options(
        arguments => {
            'mode:s'            => { name => 'mode_name' },
            'dyn-mode:s'        => { name => 'dynmode_name' },
            'list-mode'         => { name => 'list_mode' },
            'custommode:s'      => { name => 'custommode_name' },
            'list-custommode'   => { name => 'list_custommode' },
            'multiple'          => { name => 'multiple' },
            'no-sanity-options' => { name => 'no_sanity_options' },
            'pass-manager:s'    => { name => 'pass_manager' }
        }
    );
    $self->{version} = '1.0';
    $self->{modes} = {};
    $self->{custom_modes} = {};
    $self->{default} = undef;
    $self->{customdefault} = {};
    $self->{custommode_current} = undef;
    $self->{custommode_stored} = [];
    
    $self->{options}->parse_options();
    $self->{option_results} = $self->{options}->get_options();
    foreach (keys %{$self->{option_results}}) {
        $self->{$_} = $self->{option_results}->{$_};
    }
    $self->{options}->clean();

    $self->{options}->add_help(package => $options{package}, sections => 'PLUGIN DESCRIPTION');
    $self->{options}->add_help(package => __PACKAGE__, sections => 'GLOBAL OPTIONS');
    $self->{output}->mode(name => $self->{mode_name});

    return $self;
}

sub load_custom_mode {
    my ($self, %options) = @_;
    
    $self->is_custommode(custommode => $self->{custommode_name});
    centreon::plugins::misc::mymodule_load(
        output => $self->{output}, module => $self->{custom_modes}->{$self->{custommode_name}}, 
        error_msg => 'Cannot load module --custommode.'
    );
    $self->{custommode_current} = $self->{custom_modes}->{$self->{custommode_name}}->new(
        options => $self->{options},
        output => $self->{output},
        custommode_name => $self->{custommode_name},
        mode_name => $self->{mode_name}
    );
}

sub init {
    my ($self, %options) = @_;

    # add meta mode
    $self->{modes}->{multi} = 'centreon::plugins::multi';
    if (defined($options{help}) && !defined($self->{mode_name}) && !defined($self->{dynmode_name})) {
        $self->{options}->display_help();
        $self->{output}->option_exit();
    }
    if (defined($options{version}) && !defined($self->{mode_name})&& !defined($self->{dynmode_name})) {
        $self->version();
    }
    if (defined($self->{list_mode})) {
        $self->list_mode();
    }
    if (defined($self->{list_custommode})) {
        $self->list_custommode();
    }
    $self->{options}->set_sanity() if (!defined($self->{no_sanity_options}));

    # Output HELP
    $self->{options}->add_help(package => 'centreon::plugins::output', sections => 'OUTPUT OPTIONS');
    
    $self->load_password_mgr();

    if (defined($self->{custommode_name}) && $self->{custommode_name} ne '') {
        $self->load_custom_mode();
    } elsif (scalar(keys %{$self->{custom_modes}}) == 1) {
        $self->{custommode_name} = (keys(%{$self->{custom_modes}}))[0];
        $self->load_custom_mode();
    } else {
        $self->{output}->add_option_msg(short_msg => "Need to specify '--custommode'.");
        $self->{output}->option_exit();
    }
    
    # Load mode
    if (defined($self->{mode_name}) && $self->{mode_name} ne '') {
        $self->is_mode(mode => $self->{mode_name});
        centreon::plugins::misc::mymodule_load(output => $self->{output}, module => $self->{modes}{$self->{mode_name}}, 
                                               error_msg => "Cannot load module --mode.");
        $self->{mode} = $self->{modes}{$self->{mode_name}}->new(options => $self->{options}, output => $self->{output}, mode => $self->{mode_name});
    } elsif (defined($self->{dynmode_name}) && $self->{dynmode_name} ne '') {
        (undef, $self->{dynmode_name}) = centreon::plugins::misc::mymodule_load(output => $self->{output}, module => $self->{dynmode_name}, 
                                                                                error_msg => "Cannot load module --dyn-mode.");
        $self->{mode} = $self->{dynmode_name}->new(options => $self->{options}, output => $self->{output}, mode => $self->{dynmode_name});
    } else {
        $self->{output}->add_option_msg(short_msg => "Need to specify '--mode' or '--dyn-mode' option.");
        $self->{output}->option_exit();
    }

    if (defined($options{help})) {
        if (defined($self->{mode_name}) && $self->{mode_name} ne '') {
            $self->{options}->add_help(package => $self->{modes}{$self->{mode_name}}, sections => 'MODE');
        } else {
            $self->{options}->add_help(package => $self->{dynmode_name}, sections => 'MODE');
        }
        $self->{options}->display_help();
        $self->{output}->option_exit();
    }
    if (defined($options{version})) {
        $self->{mode}->version();
        $self->{output}->option_exit(nolabel => 1);
    }
    
    $self->{options}->parse_options();
    $self->{option_results} = $self->{options}->get_options();
    $self->{pass_mgr}->manage_options(option_results => $self->{option_results}) if (defined($self->{pass_mgr}));

    push @{$self->{custommode_stored}}, $self->{custommode_current};
    $self->{custommode_current}->set_options(option_results => $self->{option_results});
    $self->{custommode_current}->set_defaults(default => $self->{customdefault});

    while ($self->{custommode_current}->check_options()) {
        $self->{custommode_current} = $self->{custom_modes}->{$self->{custommode_name}}->new(noptions => 1, options => $self->{options}, output => $self->{output}, mode => $self->{custommode_name});
        $self->{custommode_current}->set_options(option_results => $self->{option_results});
        push @{$self->{custommode_stored}}, $self->{custommode_current};
    }
    $self->{mode}->check_options(
        option_results => $self->{option_results},
        default => $self->{default},
        modes => $self->{modes} # for meta mode multi
    );
}

sub load_password_mgr {
    my ($self, %options) = @_;
    
    return if (!defined($self->{option_results}->{pass_manager}) || $self->{option_results}->{pass_manager} eq '');

    (undef, my $pass_mgr_name) = centreon::plugins::misc::mymodule_load(
        output => $self->{output}, module => "centreon::plugins::passwordmgr::" . $self->{option_results}->{pass_manager}, 
        error_msg => "Cannot load module 'centreon::plugins::passwordmgr::" . $self->{option_results}->{pass_manager} . "'"
    );
    $self->{pass_mgr} = $pass_mgr_name->new(options => $self->{options}, output => $self->{output});
}

sub run {
    my $self = shift;

    if ($self->{output}->is_disco_format()) {
        $self->{mode}->disco_format();
        $self->{output}->display_disco_format();
        $self->{output}->exit(exit_litteral => 'ok');
    }

    if ($self->{output}->is_disco_show()) {
        if (defined($self->{multiple})) {
            $self->{mode}->disco_show(custom => $self->{custommode});
        } else {
            $self->{mode}->disco_show(custom => $self->{custommode_stored}[0]);
        }
        $self->{output}->display_disco_show();
        $self->{output}->exit(exit_litteral => 'ok');
    } else {
        if (defined($self->{multiple})) {
            $self->{mode}->run(custom => $self->{custommode_stored});
        } else {
            $self->{mode}->run(custom => $self->{custommode_stored}[0]);
        }
    }
}

sub is_mode {
    my ($self, %options) = @_;
    
    if (!defined($self->{modes}{$options{mode}})) {
        $self->{output}->add_option_msg(short_msg => "mode '" . $options{mode} . "' doesn't exist (use --list-mode option to show available modes).");
        $self->{output}->option_exit();
    }
}

sub is_custommode {
    my ($self, %options) = @_;
    
    if (!defined($self->{custom_modes}->{$options{custommode}})) {
        $self->{output}->add_option_msg(short_msg => "mode '" . $options{custommode} . "' doesn't exist (use --list-custommode option to show available modes).");
        $self->{output}->option_exit();
    }
}

sub version {
    my $self = shift;    
    $self->{output}->add_option_msg(short_msg => "Plugin Version: " . $self->{version});
    $self->{output}->option_exit(nolabel => 1);
}

sub list_mode {
    my $self = shift;
    $self->{options}->display_help();
    
    $self->{output}->add_option_msg(long_msg => 'Modes Meta:');
    $self->{output}->add_option_msg(long_msg => '   multi');
    $self->{output}->add_option_msg(long_msg => '');
    $self->{output}->add_option_msg(long_msg => 'Modes Available:');
    foreach (sort keys %{$self->{modes}}) {
        next if ($_ eq 'multi');
        $self->{output}->add_option_msg(long_msg => '   ' . $_);
    }
    $self->{output}->option_exit(nolabel => 1);
}

sub list_custommode {
    my $self = shift;
    $self->{options}->display_help();
    
    $self->{output}->add_option_msg(long_msg => "Custom Modes Available:");
    foreach (keys %{$self->{custom_modes}}) {
        $self->{output}->add_option_msg(long_msg => "   " . $_);
    }
    $self->{output}->option_exit(nolabel => 1);
}

1;

__END__

=head1 NAME

-

=head1 SYNOPSIS

-

=head1 GLOBAL OPTIONS

=over 8

=item B<--mode>

Choose a mode.

=item B<--dyn-mode>

Specify a mode with the path (separated by '::').

=item B<--list-mode>

List available modes.

=item B<--mode-version>

Check minimal version of mode. If not, unknown error.

=item B<--version>

Display plugin version.

=item B<--custommode>

Choose a custom mode.

=item B<--list-custommode>

List available custom modes.

=item B<--multiple>

Multiple custom mode objects (required by some specific modes)

=item B<--pass-manager>

Use a password manager.

=back

=head1 DESCRIPTION

B<>.

=cut
