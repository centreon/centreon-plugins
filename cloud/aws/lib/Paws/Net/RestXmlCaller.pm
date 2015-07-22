package Paws::Net::RestXmlCaller {
  use Moose::Role;
  use HTTP::Request::Common;
  use POSIX qw(strftime); 
  use URI::Template;

  sub array_flatten_string {
    my $self = shift;
    return ($self->flattened_arrays)?'%s.%d':'%s.member.%d';
  }

  sub _is_internal_type {
    my ($self, $att_type) = @_;
    return ($att_type eq 'Str' or $att_type eq 'Int' or $att_type eq 'Bool' or $att_type eq 'Num');
  }

  # converts the objects that represent the call into parameters that the API can understand
  sub _to_querycaller_params {
    my ($self, $params) = @_;
    my %p;
    foreach my $att (grep { $_ !~ m/^_/ } $params->meta->get_attribute_list) {
      my $key = $params->meta->get_attribute($att)->does('Net::AWS::Caller::Attribute::Trait::NameInRequest')?$params->meta->get_attribute($att)->request_name:$att;
      if (defined $params->$att) {
        my $att_type = $params->meta->get_attribute($att)->type_constraint;

        if ($self->_is_internal_type($att_type)) {
          $p{ $key } = $params->{$att};
        } elsif ($att_type =~ m/^ArrayRef\[(.*)\]/) {
          if ($self->_is_internal_type("$1")){
            my $i = 1;
            foreach my $value (@{ $params->$att }){
              $p{ sprintf($self->array_flatten_string, $key, $i) } = $value;
              $i++
            }
          } else {
            my $i = 1;
            foreach my $value (@{ $params->$att }){
              my %complex_value = $self->_to_querycaller_params($value);
              map { $p{ sprintf($self->array_flatten_string . ".%s", $key, $i, $_) } = $complex_value{$_} } keys %complex_value;
              $i++
            }
          }
        } else {
          my %complex_value = $self->_to_querycaller_params($params->$att);
          map { $p{ "$key.$_" } = $complex_value{$_} } keys %complex_value;
        }
      }
    }
    return %p;
  }

  sub _call_uri {
    my ($self, $call) = @_;
    my $uri_template = $call->meta->name->_api_uri;
    my $t = URI::Template->new( $uri_template );

    my $vars = {};
    my $qparams = {};

    foreach my $attribute ($call->meta->get_all_attributes) {
      my $att_name = $attribute->name;
      if ($attribute->does('Paws::API::Attribute::Trait::ParamInURI')) {
        $vars->{ $attribute->uri_name } = $call->$att_name
      }
      if ($attribute->does('Paws::API::Attribute::Trait::ParamInQuery')) {
        $qparams->{ $attribute->query_name } = $call->$att_name if (defined $call->$att_name);
      }
    }

    my $uri = $t->process($vars);
    $uri->query_form(%$qparams);
    return $uri->as_string;
  }

  # URI escaping adapted from URI::Escape
  #c.f. http://www.w3.org/TR/html4/interact/forms.html#h-17.13.4.1
  # perl 5.6 ready UTF-8 encoding adapted from JSON::PP
  our %escapes = map { chr($_) => sprintf("%%%02X", $_) } 0..255;
  our $unsafe_char = qr/[^A-Za-z0-9\-\._~]/;

  sub _uri_escape {
    my ($self, $str) = @_;
    if ( $] ge '5.008' ) {
        utf8::encode($str);
    }
    else {
        $str = pack("U*", unpack("C*", $str)) # UTF-8 encode a byte string
            if ( length $str == do { use bytes; length $str } );
        $str = pack("C*", unpack("C*", $str)); # clear UTF-8 flag
    }
    $str =~ s/($unsafe_char)/$escapes{$1}/ge;
    $str =~ s/ /+/go;
    return $str;
  }

  sub prepare_request_for_call {
    my ($self, $call) = @_;

    my $request;
    if ($self->isa('Paws::S3')){
      require Paws::Net::S3APIRequest;
      $request = Paws::Net::S3APIRequest->new();
    } else {
      $request = Paws::Net::APIRequest->new();
    }

    my $uri = $self->_call_uri($call);
    $request->uri($uri);

    my $url = $self->_api_endpoint . $uri;
    $request->parameters({ $self->_to_querycaller_params($call) });
    $request->url($url);

    $request->method($call->_api_method);

    #$request->headers->header( 'content-length' => $self->content_length ) if $content;
    #$request->headers->header( 'content-type'   => $self->content_type ) if $content;
    #$request->content();

    $self->sign($request);

    return $request;
  }
}

1;
