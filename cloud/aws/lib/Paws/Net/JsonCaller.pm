package Paws::Net::JsonCaller {
  use Moose::Role;
  use JSON;
  use POSIX qw(strftime);
  requires 'json_version';

  sub _is_internal_type {
    my ($self, $att_type) = @_;
    return ($att_type eq 'Str' or $att_type eq 'Int' or $att_type eq 'Bool' or $att_type eq 'Num');
  }

  # converts the objects that represent the call into parameters that the API can understand
  sub _to_jsoncaller_params {
    my ($self, $params) = @_;
    my %p;
    foreach my $att (grep { $_ !~ m/^_/ } $params->meta->get_attribute_list) {
      my $key = $params->meta->get_attribute($att)->does('Paws::Net::Caller::Attribute::Trait::NameInRequest')?$params->meta->get_attribute($att)->request_name:$att;
      if (defined $params->$att) {
        my $att_type = $params->meta->get_attribute($att)->type_constraint;
        if ($att_type eq 'Bool') {
          $p{ $key } = ($params->$att)?\1:\0;
        } elsif ($att_type eq 'Int') {
          $p{ $key } = int($params->$att);
        } elsif ($self->_is_internal_type($att_type)) {
          $p{ $key } = $params->$att;
        } elsif ($att_type =~ m/^ArrayRef\[(.*)\]/) {
          if ($self->_is_internal_type("$1")){
            $p{ $key } = $params->$att;
          } else {
            $p{ $key } = [ map { $self->_to_jsoncaller_params($_) } @{ $params->$att } ];
          }
        } elsif ($att_type->isa('Moose::Meta::TypeConstraint::Enum')) {
          $p{ $key } = $params->$att;
        } elsif ($params->$att->does('Paws::API::StrToNativeMapParser')){ 
          $p{ $key } = { %{ $params->$att->Map }  };
        } else {
          $p{ $key } = $self->_to_jsoncaller_params($params->$att);
        }
      }
    }
    return \%p;
  }

  sub prepare_request_for_call {
    my ($self, $call) = @_;

    my $request = Paws::Net::APIRequest->new();

    $request->url($self->_api_endpoint . '/');
    $request->uri('/');
    $request->method('POST');

    $request->parameters({ Action => $call->_api_call,
                           Version => $self->version,
                           AWSAccessKeyId => $self->access_key,
                           Timestamp => strftime("%Y-%m-%dT%H:%M:%SZ",gmtime),
                        });
    $request->header('X-Amz-Target', sprintf('%s.%s', $self->target_prefix, $call->_api_call));

    my $j_version = $self->json_version;
    $request->headers->content_type("application/x-amz-json-$j_version");

    #$request->header('Content-Encoding', 'amz-1.0');
    $request->header( 'X-Amz-Date' => strftime( '%Y%m%dT%H%M%SZ', gmtime) );
    $request->header( Host => $self->endpoint_host );

    my $data = $self->_to_jsoncaller_params($call);
    $request->content(to_json($data));

    $self->sign($request);

    return $request;
  }
}

1;
