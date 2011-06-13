use strictures 1;
use Test::More;
use Test::More;

use HTML::Zoom;

my $tmpl =<<END;
<body>
  <form name="main">
    <label for="input_field">Input</label>
    <input data-validate="required" type="text" name="input_field" />
    <label for="input_field2">Input 2</label>
    <input data-validate="required" value="gorch" type="text" name="input_field2" />

    <label for="input_check">Checkbox</label>
    <input data-validate="required" value="0" type="checkbox" name="input_check" />

    <label for="select_field">Select</label>
    <select data-validate="required" name="select_field">
      <option value="1">foo</option>
      <option value="2">bar</option>
      <option value="3" selected="selected">oof</option>
      <option value="4">rab</option>
    </select>
    <label for="select_field">Select 2</label>
    <select data-validate="required" name="select_field2">
      <option value="1">foo</option>
      <option value="2">bar</option>
      <option value="3">oof</option>
      <option value="4">rab</option>
    </select>

  </form>
</body>
END

my $z = HTML::Zoom->from_html($tmpl);

my ($expect);

($expect = $tmpl) =~ s/name="input_field" /name="input_field" value="testval" /;

is(
  $z->select('input[name="input_field"]')->val('testval')->to_html,
  $expect,
  'set value on input=text'
);

($expect = $tmpl) =~ s/name="input_field" /name="input_field" value="testval" /;

is(
  $z->select('input[name="input_check"]')->val(1)->to_html,
  $expect,
  'set value on input=checkbox'
);

# my %rules;
# my $validate_and_fill = sub {
#  $_ = $_->set_attribute("test" => "test");
#  #use Devel::Dwarn;Dwarn \@_;
#  $_;
# };
# 
# print $z->select('form')->validate_form(\%rules, {input_field => "Test", input_field2 => "Moo"})->to_html;
# use Devel::Dwarn;Dwarn \%rules;

