
package Paws::Glacier::UploadMultipartPartOutput {
  use Moose;
  has checksum => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Glacier::UploadMultipartPartOutput

=head1 ATTRIBUTES

=head2 checksum => Str

  

The SHA256 tree hash that Amazon Glacier computed for the uploaded
part.











=cut

