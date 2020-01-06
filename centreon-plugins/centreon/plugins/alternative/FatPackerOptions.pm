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

package centreon::plugins::alternative::FatPackerOptions;

use base qw(centreon::plugins::options);

use strict;
use warnings;
use Pod::Usage;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    return $self;
}

sub display_help {
    my ($self, %options) = @_;
    
    my $stdout;
    foreach (@{$self->{pod_package}}) {
        
        {
            my $pp = $_->{package} . ".pm";
            $pp =~ s{::}{/}g;
            my $content_class = $INC{$pp}->{$pp};
            open my $str_fh, '<', \$content_class;
            
            local *STDOUT;
            open STDOUT, '>', \$stdout;
            pod2usage(-exitval => 'NOEXIT', -input => $str_fh,
                      -verbose => 99, 
                      -sections => $_->{sections});
            
            close $str_fh;
        }
        
        $self->{output}->add_option_msg(long_msg => $stdout) if (defined($stdout));
    }
}

1;

__END__
