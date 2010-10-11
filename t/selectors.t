use strict;
#use warnings FATAL => 'all';
use Test::More;

use HTML::Zoom;

my $tmpl = <<END;
<body>
  <div class="main">
    <span prop='moo' class="hilight name">Bob</span>
    <span class="career">Builder</span>
    <hr />
  </div>
</body>
END

my $stub = '<div class="waargh"></div>';

# el#id
is( HTML::Zoom->from_html('<div id="yo"></div>'.$stub)
   ->select('div#yo')
      ->replace_content('grg')
   ->to_html,
   '<div id="yo">grg</div>'.$stub,
   'E#id works' );

# el.class1
is( HTML::Zoom->from_html('<div class="yo"></div>'.$stub)
   ->select('div.yo')
      ->replace_content('grg')
   ->to_html,
   '<div class="yo">grg</div>'.$stub,
   'E.class works' );

# el[attr]
is( HTML::Zoom->from_html('<div frew="yo"></div>'.$stub)
   ->select('div[frew]')
      ->replace_content('grg')
   ->to_html,
   '<div frew="yo">grg</div>'.$stub,
   'E[attr] works' );

# el[attr="foo"]
is( HTML::Zoom->from_html('<div frew="yo"></div>'.$stub)
   ->select('div[frew="yo"]')
      ->replace_content('grg')
   ->to_html,
   '<div frew="yo">grg</div>'.$stub,
   'E[attr="val"] works' );

# el[attr=foo]
is( HTML::Zoom->from_html('<div frew="yo"></div>'.$stub)
    ->select('div[frew=yo]')
    ->replace_content('grg')
    ->to_html,
    '<div frew="yo">grg</div>'.$stub,
    'E[attr=val] works' );
 

# el[attr*="foo"]
is( HTML::Zoom->from_html('<div f="frew goog"></div>'.$stub)
   ->select('div[f*="oo"]')
      ->replace_content('grg')
   ->to_html,
   '<div f="frew goog">grg</div>'.$stub,
   'E[attr*="val"] works' );

# el[attr^="foo"]
is( HTML::Zoom->from_html('<div f="foobar"></div>'.$stub)
   ->select('div[f^="foo"]')
      ->replace_content('grg')
   ->to_html,
   '<div f="foobar">grg</div>'.$stub,
   'E[attr^="val"] works' );

# el[attr$="foo"]
is( HTML::Zoom->from_html('<div f="foobar"></div>'.$stub)
   ->select('div[f$="bar"]')
      ->replace_content('grg')
   ->to_html,
   '<div f="foobar">grg</div>'.$stub,
   'E[attr$="val"] works' );

# el[attr*="foo"]
is( HTML::Zoom->from_html('<div f="foo bar"></div>'.$stub)
   ->select('div[f*="bar"]')
      ->replace_content('grg')
   ->to_html,
   '<div f="foo bar">grg</div>'.$stub,
   'E[attr*="val"] works' );

# [attr=bar]
ok( check_select( '[prop=moo]'), '[attr=bar]' );

# el[attr=bar],[prop=foo]
is( check_select('span[class=career],[prop=moo]'), 2,
    'Multiple selectors: el[attr=bar],[attr=foo]');

TODO:{
    local $TODO = 'Fix selector error messages';
    # selector parse error test:
    eval{
        HTML::Zoom->from_html('<span att="bar"></span>')
          ->select('[att=bar')
          ->replace_content('cats')
          ->to_html;
    };
    like( $@, qr/Error parsing dispatch specification/,
          'Malformed attribute selector results in a helpful error' );
};

=pod

# sel1 sel2
is( HTML::Zoom->from_html('<table><tr></tr><tr></tr></table>')
   ->select('table tr')
      ->replace_content(\'<td></td>')
   ->to_html,
   '<table><tr><td></td></tr><tr><td></td></tr></table>',
   'sel1 sel2 works' );


# sel1 sel2 sel3
is( HTML::Zoom->from_html('<table><tr><td></td></tr><tr><td></td></tr></table>')
   ->select('table tr td')
      ->replace_content('frew')
   ->to_html,
   '<table><tr><td>frew</td></tr><tr><td>frew</td></tr></table>',
   'sel1 sel2 sel3 works' );



=cut

done_testing;


sub check_select{
    # less crude?:
    my $output = HTML::Zoom
    ->from_html($tmpl)
    ->select(shift)->replace("the monkey")->to_html;
    my $count = 0;
    while ( $output =~ /the monkey/g ){
        $count++;
    }
    return $count;
}
