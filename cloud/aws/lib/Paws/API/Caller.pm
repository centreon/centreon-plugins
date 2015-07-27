package Paws::API::Caller;
  use Moose::Role;
  use Module::Runtime qw//;
  use Carp;
  use Paws::Net::APIRequest;
  use String::Util qw/trim/;

  has caller => (is => 'ro', required => 1);

  has credentials => (
    is => 'ro',
    does => 'Paws::Credential',
    required => 1,
    handles => [ 'access_key', 'secret_key', 'session_token' ],
  );

  # converts the params the user passed to the call into objects that represent the call
  sub new_with_coercions {
    my ($self, $class, %params) = @_;

    Module::Runtime::require_module($class);
    my %p;
    foreach my $att (keys %params){
      my $att_meta = $class->meta->find_attribute_by_name($att);

      if ($class->does('Paws::API::StrToObjMapParser')) {
        my ($subtype) = ($class->meta->find_attribute_by_name('Map')->type_constraint =~ m/^HashRef\[(.*?)\]$/);
        Module::Runtime::require_module($subtype);
        $p{ Map }->{ $att } = $subtype->new(%{ $params{ $att } });
      } elsif ($class->does('Paws::API::StrToNativeMapParser')) {
        $p{ Map }->{ $att } = $params{ $att };
      } else {
        croak "$class doesn't have an $att" if (not defined $att_meta);
        my $type = $att_meta->type_constraint;

        if ($type eq 'Bool') {
          $p{ $att } = ($params{ $att } == 1)?1:0;
        } elsif ($type eq 'Str' or $type eq 'Num' or $type eq 'Int') {
          $p{ $att } = $params{ $att };
        } elsif ($type =~ m/^ArrayRef\[(.*?)\]$/){
          my $subtype = "$1";
          if ($subtype eq 'Str' or $subtype eq 'Num' or $subtype eq 'Int' or $subtype eq 'Bool') {
            $p{ $att } = $params{ $att };
          } else {
            $p{ $att } = [ map { $self->new_with_coercions("$subtype", %{ $_ }) } @{ $params{ $att } } ];
          }
        } elsif ($type->isa('Moose::Meta::TypeConstraint::Enum')){
          $p{ $att } = $params{ $att };
        } else {
          $p{ $att } = $self->new_with_coercions("$type", %{ $params{ $att } });
        }
      }
    }
    return $class->new(%p);
  }

  sub to_hash {
    my ($self, $params) = @_;
    my $refHash = {};
    foreach my $att (grep { $_ !~ m/^_/ } $params->meta->get_attribute_list) {
      my $key = $att;
      if (defined $params->$att) {
        my $att_type = $params->meta->get_attribute($att)->type_constraint;
        if ($att_type eq 'Bool') {
          $refHash->{ $key } = ($params->$att)?1:0;
        } elsif ($self->_is_internal_type($att_type)) {
          $refHash->{ $key } = $params->$att;
        } elsif ($att_type =~ m/^ArrayRef\[(.*)\]/) {
          if ($self->_is_internal_type("$1")){
            $refHash->{ $key } = $params->$att;
          } else {
            $refHash->{ $key } = [ map { $self->to_hash($_) } @{ $params->$att } ];
          }
        } elsif ($att_type->isa('Moose::Meta::TypeConstraint::Enum')) {
          $refHash->{ $key } = $params->$att;
        } elsif ($params->$att->does('Paws::API::StrToNativeMapParser')) {
          $refHash->{$key} = $params->$att->Map;
        } elsif ($params->$att->does('Paws::API::StrToObjMapParser')) {
          $refHash->{$key} = { map { ($_ => $self->to_hash($params->$att->Map->{$_})) } keys %{ $params->$att->Map } };
        } else {
          $refHash->{ $key } = $self->to_hash($params->$att);
        }
      }
    }
    return $refHash;
  }

  sub handle_response {
    my ($self, $call_object, $http_status, $content, $headers) = @_;

    if ( $http_status == 599 ) {
        return Paws::Exception->new(message => $content, code => 'ConnectionError', request_id => '');
    }

    my $unserialized_struct;
    $unserialized_struct = $self->unserialize_response( $content );

    if ( $http_status >= 300 ) {
        return $self->error_to_exception($unserialized_struct, $call_object, $http_status, $content, $headers);
    } else {
        return $self->response_to_object($unserialized_struct, $call_object, $http_status, $content, $headers);
    }
  }

  sub response_to_object {
    my ($self, $unserialized_struct, $call_object, $http_status, $content, $headers) = @_;

    $call_object = $call_object->meta->name;

    if ($call_object->_returns){
      if ($call_object->_result_key){
        $unserialized_struct = $unserialized_struct->{ $call_object->_result_key };
      }

      Module::Runtime::require_module($call_object->_returns);
      my $o_result = $self->new_from_struct($call_object->_returns, $unserialized_struct);
      return $o_result;
    } else {
      return 1;
    }
  }

  sub new_from_struct {
    my ($self, $class, $result) = @_;
    my %args;
 
    foreach my $att ($class->meta->get_attribute_list) {
      next if (not my $meta = $class->meta->get_attribute($att));

      my $key = $meta->does('Paws::API::Attribute::Trait::Unwrapped') ? $meta->xmlname : $att;
      my $att_type = $meta->type_constraint;

      #use Data::Dumper;
      #print STDERR "GOING TO DO AN $att_type\n";
      #print STDERR "VALUE: " . Dumper($result);

      # We'll consider that an attribute without brackets [] isn't an array type
      if ($att_type !~ m/\[.*\]$/) {
        my $value = $result->{ $key };
        my $value_ref = ref($value);

        if ($att_type =~ m/\:\:/) {
          # Make the att_type stringify for module loading
          Module::Runtime::require_module("$att_type");
          if (defined $value) {
            if (not $value_ref) {
              $args{ $att } = $value;
            } else {
              my $att_class = $att_type->class;

              if ($att_class->does('Paws::API::StrToObjMapParser')) {
                my $xml_keys = $att_class->xml_keys;
                my $xml_values = $att_class->xml_values;

                if ($value_ref eq 'HASH') {
                  if (exists $value->{ member }) {
                    $value = $value->{ member };
                  } elsif (exists $value->{ entry }) {
                    $value = $value->{ entry  };
                  } elsif (keys %$value == 1) {
                    $value = $value->{ (keys %$value)[0] };
                  } else {
                    #die "Can't detect the item that has the array in the response hash";
                  }
                  $value_ref = ref($value);
                }
        
                my $inner_class = $att_class->meta->get_attribute('Map')->type_constraint->name;
                ($inner_class) = ($inner_class =~ m/\[(.*)\]$/);
                Module::Runtime::require_module("$inner_class");
                if ($value_ref eq 'ARRAY') {
                  $args{ $att } = $att_class->new(Map => { map { ( $_->{ $xml_keys } => $self->new_from_struct($inner_class, $_->{ $xml_values }) ) } @$value } );
                } elsif ($value_ref eq 'HASH') {
                  $args{ $att } = $att_class->new(Map => { $value->{ $xml_keys } => $self->new_from_struct($inner_class, $value->{ $xml_values }) });
                } elsif (not defined $value){
                  $args{ $att } = $att_class->new(Map => {});
                }  
              } elsif ($att_class->does('Paws::API::StrToNativeMapParser')) {
                my $xml_keys = $att_class->xml_keys;
                my $xml_values = $att_class->xml_values;

                if ($value_ref eq 'HASH') {
                  if (exists $value->{ member }) {
                    $value = $value->{ member };
                  } elsif (exists $value->{ entry }) {
                    $value = $value->{ entry  };
                  } elsif (keys %$value == 1) {
                    $value = $value->{ (keys %$value)[0] };
                  } else {
                    #die "Can't detect the item that has the array in the response hash";
                  }
                  $value_ref = ref($value);
                }
        
                if ($value_ref eq 'ARRAY') {
                  $args{ $att } = $att_class->new(Map => { map { ( $_->{ $xml_keys } => $_->{ $xml_values } ) } @$value } );
                } elsif ($value_ref eq 'HASH') {
                  $args{ $att } = $att_class->new(Map => { $value->{ $xml_keys } => $value->{ $xml_values } } );
                }
              } elsif ($att_class->does('Paws::API::MapParser')) {
                my $xml_keys = $att_class->xml_keys;
                my $xml_values = $att_class->xml_values;

                if ($value_ref eq 'HASH') {
                  if (exists $value->{ member }) {
                    $value = $value->{ member };
                  } elsif (exists $value->{ entry }) {
                    $value = $value->{ entry  };
                  } elsif (keys %$value == 1) {
                    $value = $value->{ (keys %$value)[0] };
                  } else {
                    #die "Can't detect the item that has the array in the response hash";
                  }
                  $value_ref = ref($value);
                }
        

                $args{ $att } = $att_class->new(map { ($_->{ $xml_keys } => $_->{ $xml_values }) } @$value);
              } else {
                $args{ $att } = $self->new_from_struct($att_class, $value);
              }
            }
          }
        } else {
          if (defined $value) {
            if ($att_type eq 'Bool') {
              if ($value eq 'true') {
                $args{ $att } = 1;
              } elsif ($value eq 'false') {
                $args{ $att } = 0;
              } elsif ($value == 1) {
                $args{ $att } = 1;
              } else {
                $args{ $att } = 0;
              }
            } else {
              $args{ $att } = trim($value);
            }
          }
        }
      } elsif (my ($type) = ($att_type =~ m/^ArrayRef\[(.*)\]$/)) {
        my $value = $result->{ $att };
        $value = $result->{ $key } if (not defined $value and $key ne $att);
        my $value_ref = ref($value);

        if ($value_ref eq 'HASH') {
          if (exists $value->{ member }) {
            $value = $value->{ member };
          } elsif (exists $value->{ entry }) {
            $value = $value->{ entry  };
          } elsif (keys %$value == 1) {
            $value = $value->{ (keys %$value)[0] };
          } else {
            #die "Can't detect the item that has the array in the response hash";
          }
          $value_ref = ref($value);
        }
 
        if ($type =~ m/\:\:/) {
          Module::Runtime::require_module($type);
          if (not defined $value) {
            $args{ $att } = [ ];
          } elsif ($value_ref eq 'ARRAY') {
            $args{ $att } = [ map { $self->new_from_struct($type, $_) } @$value ] ;
          } elsif ($value_ref eq 'HASH') {
            $args{ $att } = [ $self->new_from_struct($type, $value) ];
          }
        } else {
          if (defined $value){
            if ($value_ref eq 'ARRAY') {
              $args{ $att } = $value; 
            } else {
              $args{ $att } = [ $value ];
            }
          }
        }
      }
    }
    $class->new(%args);
  }

1;
