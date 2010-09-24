use strict;
use warnings FATAL => 'all';
use Test::More qw(no_plan);

use HTML::Zoom;
my $root = HTML::Zoom
    ->from_html(<<MAIN);
<html>
  <head>
    <title>Default Title</title>
  </head>
  <body>
    Default Content
  </body>
</html>
MAIN

my $body = HTML::Zoom
    ->from_html(<<BODY);
<div id="stuff">
    <p>Stuff</p>
</div>
BODY

my $output =  $root
->select('title')
->replace_content('Hello World')
->select('body')
->replace_content($body)
->to_html;


my $expect = <<HTML;
<html>
  <head>
    <title>Hello World</title>
  </head>
  <body><div id="stuff">
    <p>Stuff</p>
</div>
</body>
</html>
HTML
is($output, $expect, 'Synopsis code works ok');

