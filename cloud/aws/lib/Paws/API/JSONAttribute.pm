package Paws::API::JSONAttribute {
  use Moose::Role;
  Moose::Util::meta_attribute_alias('JSONAttribute');

  use JSON qw//;
  use URL::Encode;

  has method    => (is => 'rw', isa => 'Str', required => 1);
  has decode_as => (is => 'rw', isa => 'Str', required => 1);

  after 'install_accessors' => sub {
    my $self = shift;
    my $realclass = $self->associated_class();
    my $closure = $self->name;

    my $coderef;
    if ($self->decode_as eq 'JSON') {
      $coderef = sub {
        my $self = shift;
        return JSON::decode_json($self->$closure());
      };
    } elsif ($self->decode_as eq 'URLJSON') {
      $coderef = sub {
        my $self = shift;
        return JSON::decode_json(URL::Encode::url_decode($self->$closure()));
      };
    } else {
      die "Unrecognized JSONAttribute decode_as attribute";
    }

    $realclass->add_method( $self->method => $coderef );
  };
}

1;
