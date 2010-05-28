package HTML::Zoom::ArrayStream;

use strict;
use warnings FATAL => 'all';
use base qw(HTML::Zoom::StreamBase);

sub new {
  my ($class, $args) = @_;
  bless(
    { _zconfig => $args->{zconfig}, _array => [ @{$args->{array}} ] },
    $class
  );
}

sub _next {
  my $ary = $_[0]->{_array};
  return unless @$ary;
  return shift @$ary;
}

1;
