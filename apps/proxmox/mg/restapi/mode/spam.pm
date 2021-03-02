package apps::proxmox::mg::restapi::mode::spam;

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
  $self->{spams} = $options{custom}->api_recent_spam();
}

sub run {
  my ($self, %options) = @_;
  $self->manage_selection(%options);
  foreach my $spam_id (max(keys %{$self->{spams}})) {
      $self->{output}->output_add(
          severity => 'OK',
          short_msg =>
              "[spam_in = '" . $self->{spams}->{$spam_id}->{Spam_in} . "']" .
              "[spam_out = '" . $self->{spams}->{$spam_id}->{Spam_out} . "']"
      );
      $self->{output}->perfdata_add(
          label =>'spam_in',
          value =>$self->{spams}->{$spam_id}->{Spam_in},
          unit  => 'mail',
          min   => 0
      );
      $self->{output}->perfdata_add(
          label =>'spam_out',
          value =>$self->{spams}->{$spam_id}->{Spam_out},
          unit  => 'mail',
          min   => 0
      );
  }

  $self->{output}->display(force_long_output => 1);
  $self->{output}->exit();
}

1;

__END__

=head1 MODE

=over 8

=back

=cut
