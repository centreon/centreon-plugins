package Paws::Net::S3Signature {
  use Moose::Role;
  requires 'service';

  use MIME::Base64 qw(encode_base64);
  use Digest::HMAC_SHA1;

  sub sign {
    my ($self, $request) = @_;

    my $hmac = Digest::HMAC_SHA1->new( $self->secret_key );
    $hmac->add( $request->string_to_sign() );

    my $headers = $request->headers;
    $headers->header(Authorization  => 'AWS ' . $self->access_key . ':' . encode_base64( $hmac->digest, '' ));
    $headers->header(Date           => $request->date );
    $headers->header(Host           => $self->_api_endpoint );
  }

  sub auth_header {
    my ($self, $request) = @_;
    my $hmac = Digest::HMAC_SHA1->new( $self->secret_key );
    $hmac->add( $request->string_to_sign() );

    return 'AWS ' . $self->access_key . ':' . encode_base64( $hmac->digest, '' );
  }
}

1;
