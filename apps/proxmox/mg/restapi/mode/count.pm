package apps::proxmox::mg::restapi::mode::count;

use base qw(centreon::plugins::mode);

use List::Util qw(max);

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

sub manage_selection {
  my ($self, %options) = @_;
  $self->{counts} = $options{custom}->api_recent_count();
}

sub run {
  my ($self, %options) = @_;
  $self->manage_selection(%options);
  foreach my $count_id (max(keys %{$self->{counts}})) {
      $self->{output}->output_add(
          severity => 'OK',
          short_msg =>
              "[count_in = '" . $self->{counts}->{$count_id}->{Count_in} . "']" .
              "[count_out = '" . $self->{counts}->{$count_id}->{Count_out} . "']"
      );
      $self->{output}->perfdata_add(
          label =>'mail_in',
          value =>$self->{counts}->{$count_id}->{Count_in},
          unit  => 'B',
          min   => 0
      );
      $self->{output}->perfdata_add(
          label =>'mail_out',
          value =>$self->{counts}->{$count_id}->{Count_out},
          unit  => 'B',
          min   => 0
      );
  }

  $self->{output}->display( force_long_output => 1);
  $self->{output}->exit();
}

1;

__END__

=head1 MODE

=over 8

=back

=cut
