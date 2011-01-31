package HTML::Zoom::FilterBuilder;

use strict;
use warnings FATAL => 'all';
use base qw(HTML::Zoom::SubObject);
use HTML::Zoom::CodeStream;

sub _stream_from_code {
  shift->_zconfig->stream_utils->stream_from_code(@_)
}

sub _stream_from_array {
  shift->_zconfig->stream_utils->stream_from_array(@_)
}

sub _stream_from_proto {
  shift->_zconfig->stream_utils->stream_from_proto(@_)
}

sub _stream_concat {
  shift->_zconfig->stream_utils->stream_concat(@_)
}

sub _flatten_stream_of_streams {
  shift->_zconfig->stream_utils->flatten_stream_of_streams(@_)
}

sub set_attribute {
  my $self = shift;
  my ($name, $value) = $self->_parse_attribute_args(@_);
  sub {
    my $a = (my $evt = $_[0])->{attrs};
    my $e = exists $a->{$name};
    +{ %$evt, raw => undef, raw_attrs => undef,
       attrs => { %$a, $name => $value },
      ($e # add to name list if not present
        ? ()
        : (attr_names => [ @{$evt->{attr_names}}, $name ]))
     }
   };
}

sub _parse_attribute_args {
  my $self = shift;
  # allow ->add_to_attribute(name => 'value')
  #    or ->add_to_attribute({ name => 'name', value => 'value' })
  my ($name, $value) = @_ > 1 ? @_ : @{$_[0]}{qw(name value)};
  return ($name, $self->_zconfig->parser->html_escape($value));
}

sub add_attribute {
    die "renamed to add_to_attribute. killing this entirely for 1.0";
}

sub add_to_attribute {
  my $self = shift;
  my ($name, $value) = $self->_parse_attribute_args(@_);
  sub {
    my $a = (my $evt = $_[0])->{attrs};
    my $e = exists $a->{$name};
    +{ %$evt, raw => undef, raw_attrs => undef,
       attrs => {
         %$a,
         $name => join(' ', ($e ? $a->{$name} : ()), $value)
      },
      ($e # add to name list if not present
        ? ()
        : (attr_names => [ @{$evt->{attr_names}}, $name ]))
    }
  };
}

sub remove_attribute {
  my ($self, $args) = @_;
  my $name = (ref($args) eq 'HASH') ? $args->{name} : $args;
  sub {
    my $a = (my $evt = $_[0])->{attrs};
    return $evt unless exists $a->{$name};
    $a = { %$a }; delete $a->{$name};
    +{ %$evt, raw => undef, raw_attrs => undef,
       attrs => $a,
       attr_names => [ grep $_ ne $name, @{$evt->{attr_names}} ]
    }
  };
}

sub collect {
  my ($self, $options) = @_;
  my ($into, $passthrough, $content, $filter, $flush_before) =
    @{$options}{qw(into passthrough content filter flush_before)};
  sub {
    my ($evt, $stream) = @_;
    # We wipe the contents of @$into here so that other actions depending
    # on this (such as a repeater) can be invoked multiple times easily.
    # I -suspect- it's better for that state reset to be managed here; if it
    # ever becomes painful the decision should be revisited
    if ($into) {
      @$into = $content ? () : ($evt);
    }
    if ($evt->{is_in_place_close}) {
      return $evt if $passthrough || $content;
      return;
    }
    my $name = $evt->{name};
    my $depth = 1;
    my $_next = $content ? 'peek' : 'next';
    $stream = do { local $_ = $stream; $filter->($stream) } if $filter;
    my $collector = $self->_stream_from_code(sub {
      return unless $stream;
      while (my ($evt) = $stream->$_next) {
        $depth++ if ($evt->{type} eq 'OPEN');
        $depth-- if ($evt->{type} eq 'CLOSE');
        unless ($depth) {
          undef $stream;
          return if $content;
          push(@$into, $evt) if $into;
          return $evt if $passthrough;
          return;
        }
        push(@$into, $evt) if $into;
        $stream->next if $content;
        return $evt if $passthrough;
      }
      die "Never saw closing </${name}> before end of source";
    });
    if ($flush_before) {
      if ($passthrough||$content) {
        $evt = { %$evt, flush => 1 };
      } else {
        $evt = { type => 'EMPTY', flush => 1 };
      }
    }
    return ($passthrough||$content||$flush_before)
             ? [ $evt, $collector ]
             : $collector;
  };
}

sub collect_content {
  my ($self, $options) = @_;
  $self->collect({ %{$options||{}}, content => 1 })
}

sub add_before {
  my ($self, $events) = @_;
  sub { return $self->_stream_from_array(@$events, $_[0]) };
}

sub add_after {
  my ($self, $events) = @_;
  my $coll_proto = $self->collect({ passthrough => 1 });
  sub {
    my ($evt) = @_;
    my $emit = $self->_stream_from_array(@$events);
    my $coll = &$coll_proto;
    return ref($coll) eq 'HASH' # single event, no collect
      ? [ $coll, $emit ]
      : [ $coll->[0], $self->_stream_concat($coll->[1], $emit) ];
  };
}

sub prepend_content {
  my ($self, $events) = @_;
  sub {
    my ($evt) = @_;
    if ($evt->{is_in_place_close}) {
      $evt = { %$evt }; delete @{$evt}{qw(raw is_in_place_close)};
      return [ $evt, $self->_stream_from_array(
        @$events, { type => 'CLOSE', name => $evt->{name} }
      ) ];
    }
    return $self->_stream_from_array($evt, @$events);
  };
}

sub append_content {
  my ($self, $events) = @_;
  my $coll_proto = $self->collect({ passthrough => 1, content => 1 });
  sub {
    my ($evt) = @_;
    if ($evt->{is_in_place_close}) {
      $evt = { %$evt }; delete @{$evt}{qw(raw is_in_place_close)};
      return [ $evt, $self->_stream_from_array(
        @$events, { type => 'CLOSE', name => $evt->{name} }
      ) ];
    }
    my $coll = &$coll_proto;
    my $emit = $self->_stream_from_array(@$events);
    return [ $coll->[0], $self->_stream_concat($coll->[1], $emit) ];
  };
}

sub replace {
  my ($self, $replace_with, $options) = @_;
  my $coll_proto = $self->collect($options);
  sub {
    my ($evt, $stream) = @_;
    my $emit = $self->_stream_from_proto($replace_with);
    my $coll = &$coll_proto;
    # if we're replacing the contents of an in place close
    # then we need to handle that here
    if ($options->{content}
        && ref($coll) eq 'HASH'
        && $coll->{is_in_place_close}
      ) {
      my $close = $stream->next;
      # shallow copy and nuke in place and raw (to force smart print)
      $_ = { %$_ }, delete @{$_}{qw(is_in_place_close raw)} for ($coll, $close);
      $emit = $self->_stream_concat(
                $emit,
                $self->_stream_from_array($close),
              );
    }
    # For a straightforward replace operation we can, in fact, do the emit
    # -before- the collect, and my first cut did so. However in order to
    # use the captured content in generating the new content, we need
    # the collect stage to happen first - and it seems highly unlikely
    # that in normal operation the collect phase will take long enough
    # for the difference to be noticeable
    return
      ($coll
        ? (ref $coll eq 'ARRAY' # [ event, stream ]
            ? [ $coll->[0], $self->_stream_concat($coll->[1], $emit) ]
            : (ref $coll eq 'HASH' # event or stream?
                 ? [ $coll, $emit ]
                 : $self->_stream_concat($coll, $emit))
          )
        : $emit
      );
  };
}

sub replace_content {
  my ($self, $replace_with, $options) = @_;
  $self->replace($replace_with, { %{$options||{}}, content => 1 })
}

sub repeat {
  my ($self, $repeat_for, $options) = @_;
  $options->{into} = \my @into;
  my @between;
  my $repeat_between = delete $options->{repeat_between};
  if ($repeat_between) {
    $options->{filter} = sub {
      $_->select($repeat_between)->collect({ into => \@between })
    };
  }
  my $repeater = sub {
    my $s = $self->_stream_from_proto($repeat_for);
    # We have to test $repeat_between not @between here because
    # at the point we're constructing our return stream @between
    # hasn't been populated yet - but we can test @between in the
    # map routine because it has been by then and that saves us doing
    # the extra stream construction if we don't need it.
    $self->_flatten_stream_of_streams(do {
      if ($repeat_between) {
        $s->map(sub {
              local $_ = $self->_stream_from_array(@into);
              (@between && $s->peek)
                ? $self->_stream_concat(
                    $_[0]->($_), $self->_stream_from_array(@between)
                  )
                : $_[0]->($_)
            })
      } else {
        $s->map(sub {
              local $_ = $self->_stream_from_array(@into);
              $_[0]->($_)
          })
      }
    })
  };
  $self->replace($repeater, $options);
}

sub repeat_content {
  my ($self, $repeat_for, $options) = @_;
  $self->repeat($repeat_for, { %{$options||{}}, content => 1 })
}

1;

=head1 NAME

HTML::Zoom::FilterBuilder - Add Filters to a Stream

=head1 SYNOPSIS

Create an L<HTML::Zoom> instance:

  use HTML::Zoom;
  my $root = HTML::Zoom
      ->from_html(<<MAIN);
  <html>
    <head>
      <title>Default Title</title>
    </head>
    <body bad_attr='junk'>
      Default Content
    </body>
  </html>
  MAIN

Create a new attribute on the  C<body> tag:

  $root = $root
    ->select('body')
    ->set_attribute(class=>'main');

Add a extra value to an existing attribute:

  $root = $root
    ->select('body')
    ->add_to_attribute(class=>'one-column');

Set the content of the C<title> tag:

  $root = $root
    ->select('title')
    ->replace_content('Hello World');

Set content from another L<HTML::Zoom> instance:

  my $body = HTML::Zoom
      ->from_html(<<BODY);
  <div id="stuff">
      <p>Well Now</p>
      <p id="p2">Is the Time</p>
  </div>
  BODY

  $root = $root
    ->select('body')
    ->replace_content($body);

Set an attribute on multiple matches:

  $root = $root
    ->select('p')
    ->set_attribute(class=>'para');

Remove an attribute:

  $root = $root
    ->select('body')
    ->remove_attribute('bad_attr');

will produce:

=begin testinfo

  my $output = $root->to_html;
  my $expect = <<HTML;

=end testinfo

  <html>
    <head>
      <title>Hello World</title>
    </head>
    <body class="main one-column"><div id="stuff">
      <p class="para">Well Now</p>
      <p id="p2" class="para">Is the Time</p>
  </div>
  </body>
  </html>

=begin testinfo

  HTML
  is($output, $expect, 'Synopsis code works ok');

=end testinfo

=head1 DESCRIPTION

Given a L<HTML::Zoom> stream, provide methods to apply filters which
alter the content of that stream.

=head1 METHODS

This class defines the following public API

=head2 set_attribute

Sets an attribute of a given name to a given value for all matching selections.

    $html_zoom
      ->select('p')
      ->set_attribute(class=>'paragraph')
      ->select('div')
      ->set_attribute(name=>'class', value=>'divider');


Overrides existing values, if such exist.  When multiple L</set_attribute>
calls are made against the same or overlapping selection sets, the final
call wins.

=head2 add_to_attribute

Adds a value to an existing attribute, or creates one if the attribute does not
yet exist.

    $html_zoom
      ->select('p')
      ->set_attribute(class=>'paragraph')
      ->then
      ->add_to_attribute(name=>'class', value=>'divider');

Attributes with more than one value will have a dividing space.

=head2 remove_attribute

Removes an attribute and all its values.

    $html_zoom
      ->select('p')
      ->set_attribute(class=>'paragraph')
      ->then
      ->remove_attribute('class');

Removes attributes from the original stream or events already added.

=head2 collect

Collects and extracts results of L<HTML::Zoom/select>.  It takes the following
optional common options as hash reference.

=over

=item into [ARRAY REFERENCE]

Where to save collected events (selected elements).

    $z1->select('#main-content')
       ->collect({ into => \@body })
       ->run;
    $z2->select('#main-content')
       ->replace(\@body)
       ->memoize;

=item filter [CODE]

Run filter on collected elements (locally setting $_ to stream, and passing
stream as an argument to given code reference).  Filtered stream would be
returned.

    $z->select('.outer')
      ->collect({
        filter => sub { $_->select('.inner')->replace_content('bar!') },
        passthrough => 1,
      })

It can be used to further filter selection.  For example

    $z->select('tr')
      ->collect({
        filter => sub { $_->select('td') },
        passthrough => 1,
      })

is equivalent to (not implemented yet) descendant selector combination, i.e.

    $z->select('tr td')

=item passthrough [BOOLEAN]

Extract copy of elements; the stream is unchanged (it does not remove collected
elements).  For example without 'passthrough'

    HTML::Zoom->from_html('<foo><bar /></foo>')
      ->select('foo')
      ->collect({ content => 1 })
      ->to_html

returns '<foo></foo>', while with C<passthrough> option

    HTML::Zoom->from_html('<foo><bar /></foo>')
      ->select('foo')
      ->collect({ content => 1, passthough => 1 })
      ->to_html

returns '<foo><bar /></foo>'.

=item content [BOOLEAN]

Collect content of the element, and not the element itself.

For example

    HTML::Zoom->from_html('<h1>Title</h1><p>foo</p>')
      ->select('h1')
      ->collect
      ->to_html

would return '<p>foo</p>', while

    HTML::Zoom->from_html('<h1>Title</h1><p>foo</p>')
      ->select('h1')
      ->collect({ content => 1 })
      ->to_html

would return '<h1></h1><p>foo</p>'.

See also L</collect_content>.

=item flush_before [BOOLEAN]

Generate C<flush> event before collecting, to ensure that the HTML generated up
to selected element being collected is flushed throught to the browser.  Usually
used in L</repeat> or L</repeat_content>.

=back

=head2 collect_content

Collects contents of L<HTML::Zoom/select> result.

    HTML::Zoom->from_file($foo)
              ->select('#main-content')
              ->collect_content({ into => \@foo_body })
              ->run;
    $z->select('#foo')
      ->replace_content(\@foo_body)
      ->memoize;

Equivalent to running L</collect> with C<content> option set.

=head2 add_before

Given a L<HTML::Zoom/select> result, add given content (which might be string,
array or another L<HTML::Zoom> object) before it.

    $html_zoom
        ->select('input[name="foo"]')
        ->add_before(\ '<span class="warning">required field</span>');

=head2 add_after

Like L</add_before>, only after L<HTML::Zoom/select> result.

    $html_zoom
        ->select('p')
        ->add_after("\n\n");

You can add zoom events directly

    $html_zoom
        ->select('p')
        ->add_after([ { type => 'TEXT', raw => 'O HAI' } ]);

=head2 prepend_content

    TBD

=head2 append_content

    TBD

=head2 replace

Given a L<HTML::Zoom/select> result, replace it with a string, array or another
L<HTML::Zoom> object.  It takes the same optional common options as L</collect>
(via hash reference).

=head2 replace_content

Given a L<HTML::Zoom/select> result, replace the content with a string, array
or another L<HTML::Zoom> object.

    $html_zoom
      ->select('title, #greeting')
      ->replace_content('Hello world!');

=head2 repeat

    $zoom->select('.item')->repeat(sub {
      if (my $row = $db_thing->next) {
        return sub { $_->select('.item-name')->replace_content($row->name) }
      } else {
        return
      }
    }, { flush_before => 1 });

Run I<$repeat_for>, which should be iterator (code reference) returning
subroutines, reference to array of subroutines, or other zoom-able object
consisting of transformations.  Those subroutines would be run with $_
local-ized to result of L<HTML::Zoom/select> (of collected elements), and with
said result passed as parameter to subroutine.

You might want to use iterator when you don't have all elements upfront

    $zoom = $zoom->select('.contents')->repeat(sub {
      while (my $line = $fh->getline) {
        return sub {
          $_->select('.lno')->replace_content($fh->input_line_number)
            ->select('.line')->replace_content($line)
        }
      }
      return
    });

You might want to use array reference if it doesn't matter that all iterations
are pre-generated

    $zoom->select('table')->repeat([
      map {
        my $elem = $_;
        sub {
          $_->select('td')->replace_content($e);
        }
      } @list
    ]);

In addition to common options as in L</collect>, it also supports

=over

=item repeat_between [SELECTOR]

Selects object to be repeated between items.  In the case of array this object
is put between elements, in case of iterator it is put between results of
subsequent iterations, in the case of streamable it is put between events
(->to_stream->next).

See documentation for L</repeat_content>

=back

=head2 repeat_content

Given a L<HTML::Zoom/select> result, run provided iterator passing content of
this result to this iterator.  Accepts the same options as L</repeat>.

Equivalent to using C<contents> option with L</repeat>.

    $html_zoom
       ->select('#list')
       ->repeat_content(
          [
             sub {
                $_->select('.name')->replace_content('Matt')
                  ->select('.age')->replace_content('26')
             },
             sub {
                $_->select('.name')->replace_content('Mark')
                  ->select('.age')->replace_content('0x29')
             },
             sub {
                $_->select('.name')->replace_content('Epitaph')
                  ->select('.age')->replace_content('<redacted>')
             },
          ],
          { repeat_between => '.between' }
       );


=head1 ALSO SEE

L<HTML::Zoom>

=head1 AUTHORS

See L<HTML::Zoom> for authors.

=head1 LICENSE

See L<HTML::Zoom> for the license.

=cut

