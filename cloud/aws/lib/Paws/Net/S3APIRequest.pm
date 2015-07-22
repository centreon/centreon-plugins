package Paws::Net::S3APIRequest {
  use Moose;
  extends 'Paws::Net::APIRequest';

  use URI;
  use HTTP::Date 'time2str';
  use MIME::Base64 qw(encode_base64);
  use Digest::MD5 'md5';

  has _uri_obj => (is => 'ro', isa => 'URI', lazy => 1, default => sub {
    return URI->new(shift->url);
  });

  #Code taken from https://metacpan.org/source/LEEJO/AWS-S3-0.10/lib/AWS/S3/Signer.pm
  has 'bucket_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    lazy     => 1,
    default  => sub {
      my $s = shift;

      my $endpoint = $s->_uri_obj->host;
      if ( my ( $name ) = $endpoint =~ m{^(.+?)\.\Q$endpoint\E} ) {
        return $name;
      } else {
        return '';
      }    # end if()
    }
  );

  has 'date' => (
    is       => 'ro',
    isa      => 'Str',
    default  => sub {
      time2str( time );
    }
  );
 
  has 'string_to_sign' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    default  => sub {
      my $s = shift;
      join "\n",
        (
          $s->method, $s->content_md5,
          $s->content ? $s->content_type : '',
          $s->date || '',
          ( join "\n", grep { $_ } ( $s->canonicalized_amz_headers, $s->canonicalized_resource ) )
        );
    }
  );

  has 'canonicalized_amz_headers' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
      my $s = shift;
 
      my @h   = %{ $s->header_hash };
      my %out = ();
      while ( my ( $k, $v ) = splice( @h, 0, 2 ) ) {
        $k = lc( $k );
        if ( exists $out{$k} ) {
          $out{$k} = [ $out{$k} ] unless ref( $out{$k} );
          push @{ $out{$k} }, $v;
        } else {
          $out{$k} = $v;
        }    # end if()
      }    # end while()

      my @parts = ();
        while ( my ( $k, $v ) = each %out ) {
          if ( ref( $out{$k} ) ) {
            push @parts, _trim( $k ) . ':' . join( ',', map { _trim( $_ ) } @{ $out{$k} } );
          } else {
            push @parts, _trim( $k ) . ':' . _trim( $out{$k} );
          }    # end if()
      }    # end while()
 
      return join "\n", @parts;
    }
  );
 
  has 'canonicalized_resource' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
      my $s = shift;
      my $str = $s->bucket_name ? '/' . $s->bucket_name . $s->_uri_obj->path : $s->_uri_obj->path;
 
      if ( my ( $resource ) =
          ( $s->_uri_obj->query || '' ) =~ m{[&]*(acl|website|location|policy|delete|lifecycle)(?!\=)} )
      {
          $str .= '?' . $resource;
      }    # end if()
      return $str;
    }
  );

  has 'content_type' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    default  => sub {
      my $s = shift;
      return '' if $s->method eq 'GET';
      return '' unless $s->content;
      return 'text/plain';
    }
  );
 
  has 'content_md5' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    default  => sub {
      my $s = shift;
      return '' unless $s->content;
      return encode_base64( md5( ${ $s->content } ), '' );
    }
  );

  has 'content_length' => (
    is       => 'ro',
    isa      => 'Int',
    lazy     => 1,
    default  => sub { length( ${ shift->content } ) }
  );

  sub _trim {
    my ( $value ) = @_;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    return $value;
  }
}

1;
