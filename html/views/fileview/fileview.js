var showFile = function(txt, fileName) {
  $("source").style.display = "";
  var suffix_map = {
    "objc": ["m", "h"],
    "ruby": ["rb", "rbx", "rjs", "Rakefile", "rake", "gemspec", "irbrc", "capfile"],
    "xml": ['xml', 'tld', 'jsp', 'pt', 'cpt', 'dtml', 'rss', 'opml', 'xsl', 'xslt'],
    "javascript": ['js', 'htc', 'jsx', 'jscript', 'javascript'],
    "sql": ['sql', 'ddl', 'dml'],
    "sass": ['sass', 'scss'],
    "bash": ['sh', 'bash', 'zsh', 'bashrc', 'bash_profile', 'bash_login', 'profile', 'bash_logout'],
    "diff": ['diff', 'patch'],
    "java": ['java', 'bsh'],
    "css": ['css', 'css.erb'],
    "perl": ['pl', 'pm', 'pod', 't', 'PL'],
    "erlang": ['erl', 'hrl'],
    "php": ['php'],
    "python": ['py', 'rpy', 'pyw', 'cpy', 'SConstruct', 'Sconstruct', 'sconstruct', 'SConscript'],
    "cpp": ['cc', 'cpp', 'cp', 'cxx', 'c++', 'C', 'h', 'hh', 'hpp', 'h++', 'c']
  }
  var brush = "objc";
  var suffix = "";
  if (fileName && fileName != '') {
    suffix = fileName.substr(fileName.lastIndexOf('.') + 1);
  }
  var keys = get_keys(suffix_map);
  for (var key in keys) {
    var suffixes = suffix_map[key];
    for (var possible_suffix in suffixes) {
      if (possible_suffix == suffix) {
        brush = key;
      }
    }
  }
  
  $("source").innerHTML="<pre class='first-line: 1;brush: " + brush + "'>" + txt + "</pre>";

  SyntaxHighlighter.defaults['toolbar'] = false;
  SyntaxHighlighter.highlight();

  return;
}

var test=function(txt) {
  SyntaxHighlighter.defaults['toolbar'] = false;
  SyntaxHighlighter.highlight();

  return;
}

var get_keys = function(obj) {
  var keys = [];
  for (var key in obj) {
    keys.push(key);
  }
  return keys;
}
