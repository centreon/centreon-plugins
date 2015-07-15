package Paws::Exception {
  use Moose;
  extends 'Throwable::Error';

  has code => (
    is => 'ro',
    isa => 'Str',
    required => 1,
  );

  has request_id => (
    is => 'ro',
    isa => 'Str',
    required => 1,
  );
}
1;
