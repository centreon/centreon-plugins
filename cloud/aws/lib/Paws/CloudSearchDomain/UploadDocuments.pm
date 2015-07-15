
package Paws::CloudSearchDomain::UploadDocuments {
  use Moose;
  has contentType => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'Content-Type' , required => 1);
  has documents => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UploadDocuments');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2013-01-01/documents/batch?format=sdk');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'POST');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudSearchDomain::UploadDocumentsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'UploadDocumentsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearchDomain::UploadDocuments - Arguments for method UploadDocuments on Paws::CloudSearchDomain

=head1 DESCRIPTION

This class represents the parameters used for calling the method UploadDocuments on the 
Amazon CloudSearch Domain service. Use the attributes of this class
as arguments to method UploadDocuments.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UploadDocuments.

As an example:

  $service_obj->UploadDocuments(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> contentType => Str

  

The format of the batch you are uploading. Amazon CloudSearch supports
two document batch formats:

=over

=item * application/json

=item * application/xml

=back










=head2 B<REQUIRED> documents => Str

  

A batch of documents formatted in JSON or HTML.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UploadDocuments in L<Paws::CloudSearchDomain>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

