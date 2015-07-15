package Paws::Support::AttachmentDetails {
  use Moose;
  has attachmentId => (is => 'ro', isa => 'Str');
  has fileName => (is => 'ro', isa => 'Str');
}
1;
