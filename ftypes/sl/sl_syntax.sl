private variable colors = [
%functions
  14,
%conditional
  13,
%type
  12,
%errors
  17,
%comments
  3,
];

private variable regexps = [
%functions
  pcre_compile ("\
((evalfile(?=\s))\
|(?<!\w)(\(\)(?=\s|,))\
|(?<=&|\s|\[|\()(any(?=\s|,))\
|(?<=&|\s|\[|\()(realpath(?=\s|,))\
|(?<=&|\s|\[|\()(chdir(?=\s|,))\
|(?<=&|\s|\[|\()(__tmp(?=\s|,))\
|(?<=&|\s|\[|\()(array_sort(?=\s|,))\
|(?<=&|\s|\[|\()(errno_string(?=\s|,))\
|(?<=&|\s|\[|\(|@)(__get_reference(?=\s|,))\
|(?<=&|\s|\[|\()(l?stat_file(?=\s|,))\
|(?<=&|\s|\[|\()(access(?=\s|,))\
|(?<=&|\s|\[|\()(assoc_\w*_\w*[s,y](?=\s|,))\
|(?<=&|\s|\[|\()(strn?cmp(?=\s|,))\
|(?<=&|\s|\[|\()(strchop(?=\s|,))\
|(?<=&|\s|\[|\()(strtok(?=\s|,))\
|(?<=&|\s|\[|\()(sigprocmask(?=\s|,))\
|(?<=&|\s|\[|\()(loadfile(?=\s|,))\
|(?<=&|\s|\[|\()(loadfrom(?=\s|,))\
|(?<=&|\s|\[|\()(importfrom(?=\s|,))\
|(?<=&|\s|\[|\()(loadfile(?=\s|,))\
|(?<=&|\s|\[|\()(fork(?=\s|,))\
|(?<=&|\s|\[|\()(pipe(?=\s|,))\
|(?<=&|\s|\[|\()(execv(?=\s|,))\
|(?<=&|\s|\[|\()(execve(?=\s|,))\
|(?<=&|\s|\[|\()(socket(?=\s|,))\
|(?<=&|\s|\[|\()(bind(?=\s|,))\
|(?<=&|\s|\[|\()(listen(?=\s|,))\
|(?<=&|\s|\[|\()(connect(?=\s|,))\
|(?<=&|\s|\[|\()(char(?=\s|,))\
|(?<=&|\s|\[|\()([l|f]seek(?=\s|,))\
|(?<=&|\s|\[|\()(f?read(?=\s|,))\
|(?<=&|\s|\[|\()(open(?=\s|,))\
|(?<=&|\s|\[|\()(fopen(?=\s|,))\
|(?<=&|\s|\[|\()(f?close(?=\s|,))\
|(?<=&|\s|\[|\()(f?write(?=\s|,))\
|(?<=&|\s|\[|\()(f?printf(?=\s|,))\
|(?<=&|\s|\[|\()(string(?=\s|,))\
|(?<=&|\s|\[|\()(substr(?=\s|,))\
|(?<=&|\s|\[|\()(strlen(?=\s|,))\
|(?<=&|\s|\[|\()(sprintf(?=\s|,))\
|(?<=&|\s|\[|\()(where(?=\s|,))\
|(?<=&|\s|\[|\()(wherenot(?=\s|,))\
|(?<=&|\s|\[|\()(wherefirst(?=\s|,))\
|(?<=&|\s|\[|\()(qualifier(?=\s|,))\
|(?<=&|\s|\[|\(|;)(__qualifiers(?=\s|,))\
|(?<=&|\s|\[|\()(qualifier_exists(?=\s|,))\
|(?<=&|\s|\[|\()(_isnull(?=\s|,))\
|(?<=&|\s|\[|\()(length(?=\s|,))\
|(?<=&|\s|\[|\()(array_map(?=\s|,))\
|(?<=&|\s|\[|\()(path_\w*(nam|(i.*t))e(?=\s|,))\
|(?<=&|\s|\[|\()(getlinestr(?=\s|,))\
|(?<=&|\s|\[|\()(waddlineat(?=\s|,))\
|(?<=&|\s|\[|\()(waddline(?=\s|,)))+"R, 0),
%conditional
  pcre_compile ("\
(^\s*(if(?=\s))\
|^\s*(else if(?=\s))\
|^\s*(while(?=\s))\
|^\s*(else$)\
|^\s*(do$)\
|^\s*(for(?=\s))\
|((?<!\w)ifnot(?=\s))\
|((?<!\w)\{$)\
|((?<!\{)(?<!\w)\}(?=;))\
|((?<!\w)\}$)\
|((?<!\w)loop(?=$|\s))\
|((?<!\w)switch(?=\s))\
|((?<!\w)case(?=\s))\
|((?<!\w)_for(?=\s))\
|((?<!\w)foreach(?=\s))\
|((?<!\w)forever$)\
|((?<!\w)then$)\
|((?<=\w)--(?=;))\
|((?<=\w)\+\+(?=;))\
|((?<=\s)\?(?=\s))\
|((?<=\s):(?=\s))\
|((?<=\s)\+(?=\s))\
|((?<=\s)-(?=\s))\
|((?<=\s)\*(?=\s))\
|((?<=\s)/(?=\s))\
|((?<=\s)&&(?=[\s|$]))\
|((?<=').(?='))\
|((?<=\s)mod(?=\s))\
|((?<=\s)\+=(?=\s))\
|((?<=\s)!=(?=\s))\
|((?<=\s)>=(?=\s))\
|((?<=\s)<=(?=\s))\
|((?<=\s)<(?=\s))\
|((?<=\s)>(?=\s))\
|((?<=\D)\d+(?=\D))\
|((?<=\s)==(?=\s)))+"R, 0),
%type
  pcre_compile ("\
(((?<!\w)define(?=\s))\
|(^\{$)\
|(^\}$)\
|((?<!\w)variable(?=[\s]*))\
|((?<!\w)private(?=\s))\
|((?<!\w)public(?=\s))\
|((?<!\w)static(?=\s))\
|((?<!\w)typedef struct$)\
|((?<!\w)struct(?=[\s]*))\
|((?<!\w)try(?=[\s]*))\
|((?<!\w)catch(?=\s))\
|((?<!\w)throw(?=\s))\
|((?<!\w)finally(?=\s))\
|((?<!\w)return(?=[\s;]))\
|((?<!\w)break(?=;))\
|((?<!\w)continue(?=;))\
|((?<=[\(|\s])errno(?=[;|\)]))\
|(NULL)\
|(__argv)\
|(__argc)\
|(SEEK_SET)\
|(SEEK_CUR)\
|(SEEK_END)\
|(_NARGS)\
|((?<!\w)stderr(?=[,\)\.]))\
|((?<!\w)stdin(?=[,\)\.]))\
|((?<!\w)stdout(?=[,\)\.]))\
|((?<!\w)stdout(?=[,\)\.]))\
|((?<=\s|\||\()S_IRGRP(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IROTH(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRUSR(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRWXG(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRWXO(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRWXU(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IWGRP(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IWOTH(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IWUSR(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IXGRP(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IXOTH(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IXUSR(?=[,\|;\)]+))\
|((?<=\s|\||\()S_ISUID(?=[,\|;\)]+))\
|((?<=\s|\||\()S_ISGID(?=[,\|;\)]+))\
|((?<=\s|\||\()S_ISVTX(?=[,\|;\)]+))\
|((?<=\s|\|)O_APPEND(?=[,\|;\)]+))\
|((?<=\s|\|)O_BINARY(?=[,\|;\)]+))\
|((?<=\s|\|)O_NOCTTY(?=[,\|;\)]+))\
|((?<=\s|\|)O_RDONLY(?=[,\|;\)]+))\
|((?<=\s|\|)O_WRONLY(?=[,\|;\)]+))\
|((?<=\s|\|)O_CREAT(?=[,\|;\)]+))\
|((?<=\s|\|)O_EXCL(?=[,\|;\)]+))\
|((?<=\s|\|)O_RDWR(?=[,\|;\)]+))\
|((?<=\s|\|)O_TEXT(?=[,\|;\)]+))\
|((?<=\s|\|)O_TRUNC(?=[,\|;\)]+))\
|((?<=\s|\|)O_NONBLOCK(?=[,\|;\)]+))\
%|((?<=[\s|@|\[])[\w]+_Type(?=[\[;,\]]))\
|((?<=\()[\w]+_Type(?=[,\s]))\
|((?<!\w)[\w]+Error(?=[:|,])))+"R, 0),
%errors
  pcre_compile ("\
((?<=\w)(\s{1,}$))+"R, 0),
%comments
  pcre_compile ("((^\s*%.*)|((?<=[\)|;|\s])% .*))"R, 0),
];

define sl_lexicalhl (s, lines, vlines)
{
  __hl_groups (lines, vlines, colors, regexps);
}
