package apps::proxmox::mg::restapi::mode::version;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    my $result = $options{custom}->get_version();
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Version is " . $result );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
}

1;

__END__

=head1 MODE

=over 8

=back

=cut
