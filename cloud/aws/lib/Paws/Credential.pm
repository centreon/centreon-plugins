package Paws::Credential {
  use Moose::Role;

  requires 'access_key';
  requires 'secret_key';
  requires 'session_token';

  sub are_set {
    my $self = shift;
    return (defined $self->access_key && defined $self->secret_key);
  }

  no Moose;
}

1;
