package Paws::SES::Content {
  use Moose;
  has Charset => (is => 'ro', isa => 'Str');
  has Data => (is => 'ro', isa => 'Str', required => 1);
}
1;
