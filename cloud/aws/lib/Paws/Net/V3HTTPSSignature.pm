package Paws::Net::V3HTTPSSignature {
  use Moose::Role;
  use Net::Amazon::Signature::V3;
  #requires 'region';
  requires 'service';
  use POSIX qw(strftime);

  sub sign {
    my ($self, $request) = @_;

#    $request->header( Date => strftime( '%Y%m%dT%H%M%SZ', gmtime) );
    $request->header( Host => $self->endpoint_host );
    if ($self->session_token) {
      $request->header( 'X-Amz-Security-Token' => $self->session_token );
    }

    my $sig = Net::Amazon::Signature::V3->new(id => $self->access_key, key => $self->secret_key);

    my %headers = $sig->signed_headers;
    foreach my $header (keys %headers) {
      $request->header($header, $headers{ $header });
    }
  }
}

1;
