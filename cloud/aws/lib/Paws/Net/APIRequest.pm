package Paws::Net::APIRequest {
  use Moose;
  use HTTP::Headers;
  use URI;

  has parameters => (is => 'rw', isa => 'HashRef', default => sub { {} });
  has headers    => (is => 'rw', isa => 'HTTP::Headers', default => sub { HTTP::Headers->new });
  has content    => (is => 'rw', isa => 'Str');
  has method     => (is => 'rw', isa => 'Str');
  has uri        => (is => 'rw', isa => 'Str');
  has url        => (is => 'rw', isa => 'Str');

  sub header {
    my ($self, $header, $value) = @_;
    $self->headers->header($header, $value) if (defined $value);
    return $self->headers->header($header);
  }

   sub header_hash {
     my $self = shift;
     my $headers = {};
     $self->headers->scan(sub { $headers->{ $_[0] } = $_[1] });
     return $headers;
   }
}

1;
