package Paws::Net::XMLResponse;
  use Moose::Role;
  use XML::Simple qw//;
  use Carp qw(croak);
  use Paws::Exception;

  sub error_to_exception {
    my ($self, $struct, $call_object, $http_status, $content, $headers) = @_;

    my ($code, $error, $request_id);

    if (exists $struct->{Errors}){
      $error = $struct->{Errors}->[0]->{Error};
    } elsif (exists $struct->{Error}){
      $error = $struct->{Error};
    } else {
      $error = $struct;
    }

    if (exists $error->{Code}){
      $code = $error->{Code};
    } else {
      $code = $http_status;
    }

    if (exists $struct->{RequestId}) {
      $request_id = $struct->{RequestId};
    } elsif (exists $struct->{RequestID}){
      $request_id = $struct->{RequestID};
    } elsif (exists $headers->{ 'x-amzn-requestid' }) {
      $request_id = $headers->{ 'x-amzn-requestid' };
    } else {
      die "Cannot find RequestId in error message"
    }

    Paws::Exception->new(
      message => $error->{Message}, 
      code => $code, 
      request_id => $request_id
    );
  }

  sub unserialize_response {
    my ($self, $data) = @_;
    my $xml = XML::Simple::XMLin( $data,
            ForceArray    => qr/(?:item|Errors)/i,
            KeyAttr       => '',
            SuppressEmpty => undef,
    );
    return $xml;
  }


1;
