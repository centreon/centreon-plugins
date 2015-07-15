package Paws::Signin {
  use Moose;
  sub service { 'signin.aws' }
  sub version { '2010-05-08' }
  sub flattened_arrays { 0 }

  with 'Paws::API::Caller', 'Paws::API::SigninEndpointCaller', 'Paws::Net::NoSignature', 'Paws::Net::SigninCaller', 'Paws::Net::JsonResponse';
  
  sub GetSigninToken {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Signin::GetSigninToken', @_);
    return $self->caller->do_call($self, $call_object);
  }

  sub Login {
    my $self = shift;

    my $call_object = $self->new_with_coercions('Paws::Signin::Login', @_);
    my $requestObj = $self->prepare_request_for_call($call_object); 

    my $url = $requestObj->url;
    my @param;
    for my $p (keys %{ $requestObj->parameters }) {
      push @param , join '=' , map { $self->caller->_uri_escape($_,"^A-Za-z0-9\-_.~") } ($p, $requestObj->parameters->{$p});
    }
    $url .= '?' . (join '&', @param) if (@param);
    $requestObj->url($url);


    return $self->response_to_object({ URL => $requestObj->url }, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Signin - Perl Interface to AWS Console Signin service

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('...');
  my $res = $obj->Method(Arg1 => $val1, Arg2 => $val2);

=cut
