package Paws::Glacier::UploadListElement {
  use Moose;
  has ArchiveDescription => (is => 'ro', isa => 'Str');
  has CreationDate => (is => 'ro', isa => 'Str');
  has MultipartUploadId => (is => 'ro', isa => 'Str');
  has PartSizeInBytes => (is => 'ro', isa => 'Int');
  has VaultARN => (is => 'ro', isa => 'Str');
}
1;
