use strict;
#use warnings FATAL => 'all';
use Test::More;

use HTML::Zoom;

# el#id
is( HTML::Zoom->from_html('<div id="yo"></div>')
   ->select('div#yo')
      ->replace_content('grg')
   ->to_html,
   '<div id="yo">grg</div>',
   'E#id works' );

# el.class1
is( HTML::Zoom->from_html('<div class="yo"></div>')
   ->select('div.yo')
      ->replace_content('grg')
   ->to_html,
   '<div class="yo">grg</div>',
   'E.class works' );

# el[attr]
is( HTML::Zoom->from_html('<div frew="yo"></div>')
   ->select('div[frew]')
      ->replace_content('grg')
   ->to_html,
   '<div frew="yo">grg</div>',
   'E[attr] works' );

# el[attr="foo"]
is( HTML::Zoom->from_html('<div frew="yo"></div>')
   ->select('div[frew="yo"]')
      ->replace_content('grg')
   ->to_html,
   '<div frew="yo">grg</div>',
   'E[attr="val"] works' );

# el[attr*="foo"]
is( HTML::Zoom->from_html('<div f="frew goog"></div>')
   ->select('div[f*="oo"]')
      ->replace_content('grg')
   ->to_html,
   '<div f="frew goog">grg</div>',
   'E[attr*="val"] works' );

# el[attr^="foo"]
is( HTML::Zoom->from_html('<div f="foobar"></div>')
   ->select('div[f^="foo"]')
      ->replace_content('grg')
   ->to_html,
   '<div f="foobar">grg</div>',
   'E[attr^="val"] works' );

# el[attr$="foo"]
is( HTML::Zoom->from_html('<div f="foobar"></div>')
   ->select('div[f$="bar"]')
      ->replace_content('grg')
   ->to_html,
   '<div f="foobar">grg</div>',
   'E[attr$="val"] works' );

# el[attr*="foo"]
is( HTML::Zoom->from_html('<div f="foo bar"></div>')
   ->select('div[f*="bar"]')
      ->replace_content('grg')
   ->to_html,
   '<div f="foo bar">grg</div>',
   'E[attr*="val"] works' );

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

done_testing;
