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

package centreon::plugins::mode;

use strict;
use warnings;
use centreon::plugins::perfdata;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    $self->{perfdata} = centreon::plugins::perfdata->new(output => $options{output});
    
    %{$self->{option_results}} = ();
    $self->{output} = $options{output};
    $self->{output}->use_new_perfdata(value => 1)
        if (defined($options{force_new_perfdata}) && $options{force_new_perfdata} == 1);
    $self->{mode} = $options{mode};
    $self->{version} = '1.0';

    return $self;
}

sub init {
    my ($self, %options) = @_;
    # options{default} = { mode_xxx => { option_name => option_value }, }

    %{$self->{option_results}} = %{$options{option_results}};
    # Manage default value
    return if (!defined($options{default}));
    foreach (keys %{$options{default}}) {
        if ($_ eq $self->{mode}) {
            foreach my $value (keys %{$options{default}->{$_}}) {
                if (!defined($self->{option_results}->{$value})) {
                    $self->{option_results}->{$value} = $options{default}->{$_}->{$value};
                }
            }
        }
    }
}

sub version {
    my ($self, %options) = @_;
    
    $self->{output}->add_option_msg(short_msg => "Mode Version: " . $self->{version});
}

sub disco_format {
    my ($self, %options) = @_;

}

sub disco_show {
    my ($self, %options) = @_;

}

1;

__END__

