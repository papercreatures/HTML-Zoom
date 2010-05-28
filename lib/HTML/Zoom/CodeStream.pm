package HTML::Zoom::CodeStream;

use strict;
use warnings FATAL => 'all';
use base qw(HTML::Zoom::StreamBase);

sub new {
  my ($class, $args) = @_;
  bless({ _code => $args->{code}, _zconfig => $args->{zconfig} }, $class);
}

sub _next {
  $_[0]->{_code}->();
}

1;

