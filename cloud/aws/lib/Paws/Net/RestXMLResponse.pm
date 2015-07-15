package Paws::Net::RestXMLResponse {
  use Moose::Role;
  use XML::Simple qw//;
  use Carp qw(croak);
  use HTTP::Status;
  use Paws::Exception;

  sub unserialize_response {
    my ($self, $data) = @_;

    return {} if ($data eq '');

    my $xml = XML::Simple::XMLin( $data,
            ForceArray    => [ qr/(?:^item$|Errors)/i, ],
            KeyAttr       => '',
            SuppressEmpty => undef,
    );
    return $xml;
  }

  sub error_to_exception {
    my ($self, $struct, $call_object, $http_status, $content, $headers) = @_;

    my ($message, $code, $request_id, $host_id);

    $message = status_message($http_status);
    $code = $http_status;
    $request_id = $headers->{ 'x-amz-request-id' };
    $host_id = $headers->{ 'x-amz-id-2' };

    # Find in the body if it's not in headers
    $request_id = $struct->{ RequestId } if (not defined $request_id);

    Paws::Exception->new(
      message => $message,
      code => $code,
      request_id => $request_id,
      host_id => $host_id,
    );
  }

}

1;
