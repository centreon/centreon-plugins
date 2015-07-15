package Paws::Support::Attachment {
  use Moose;
  has data => (is => 'ro', isa => 'Str');
  has fileName => (is => 'ro', isa => 'Str');
}
1;
