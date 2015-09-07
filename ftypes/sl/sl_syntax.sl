private variable colors = [
% api functins
  11,
% intrinsic functions
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
% api public functions and vars
  pcre_compile ("\
((?<=\s|\[\()(keys(?=(->)))\
|(?<=&|\s|\[|\()(which(?=\s|,))\
|(?<=&|\s|\[|\()(getch(?=\s|,))\
|(?<=&|\s|\[|\()(fstat(?=\s|,))\
|(?<=&|\s|\[|\()(COLOR(?=\s|\.))\
|(?<=\s|\[)([P|U|G]+ID\s*(?=\s))\
|(?<=&|\s|\[|\()(repeat(?=\s|,))\
|(?<=&|\s|\[|\()(readfile(?=\s|,))\
|(?<=&|\s|\[|\(|^)(send_msg(_dr)?(?=\s|,))\
|(?<=&|\s|\[|\(|^)(tostd[out|err]+(?=\s|,))\
|(?<=&|\s|\[|\()(exception_to_array(?=\s|,))\
|(?<=\s|\[|^)((PERM|FILE_FLAGS)+\s*(?==|\[))\
|(?<=\s|\[|:)((LINES|COLUMNS)(?=\s|:|\]|\)))\
|(?<=&|\s|\[|\(|^)((getref|load|import)+f...(?=\s|,))\
|(?<=\s|\[|\(|^)((LCL|USR|STD|MDL|A|HIST|ROOT)+(DATA)?DIR(?=\s|,|\]|\[|;|\))))+"R, 0),
% intrinsic functions
  pcre_compile ("\
((evalfile(?=\s))\
|(?<=&|\s|\[|\()(int(?=\s|,))\
|(?<=&|\s|\[|\()(sum(?=\s|,))\
|(?<=&|\s|\[|\()(max(?=\s|,))\
|(?<=&|\s|\[|\()(any(?=\s|,))\
|(?<=&|\s|\[|\()(pop(?=\s|,))\
|(?<!\w)(\(\)(?=\s|,|\.|;|\)))\
|(?<=&|\s|\[|\()(atoi(?=\s|,))\
|(?<=&|\s|\[|\()(fork(?=\s|,))\
|(?<=&|\s|\[|\()(bind(?=\s|,))\
|(?<=&|\s|\[|\()(pipe(?=\s|,))\
|(?<=&|\s|\[|\()(char(?=\s|,))\
|(?<=&|\s|\[|\()(open(?=\s|,))\
|(?<=&|\s|\[|\()(fopen(?=\s|,))\
|(?<=&|\s|\[|\()(where(?=\s|,))\
|(?<=&|\s|\[|\()(execv(?=\s|,))\
|(?<=&|\s|\[|\()(chdir(?=\s|,))\
|(?<=&|\s|\[|\()(mkdir(?=\s|,))\
|(?<=&|\s|\[|\()(sleep(?=\s|,))\
|(?<=&|\s|\[|\()(__tmp(?=\s|,))\
|(?<=&|\s|\[|\()(uname(?=\s|,))\
|([s|g]et_\w*_\w*_path(?=\s|,))\
|(?<=&|\s|\[|\()(sscanf(?=\s|,))\
|(?<=&|\s|\[|\()(string(?=\s|,))\
|(?<=&|\s|\[|\()(substr(?=\s|,))\
|(?<=&|\s|\[|\()(strlen(?=\s|,))\
|(?<=&|\s|\[|\()(f?read(?=\s|,))\
|(?<=&|\s|\[|\()(access(?=\s|,))\
|(?<=&|\s|\[|\()(typeof(?=\s|,))\
|(?<=&|\s|\[|\()(getcwd(?=\s|,))\
|(?<=&|\s|\[|\()(cumsum(?=\s|,))\
|(?<=&|\s|\[|\()(length(?=\s|,))\
|(?<=&|\s|\[|\()(execve(?=\s|,))\
|(?<=&|\s|\[|\()(socket(?=\s|,))\
|(?<=&|\s|\[|\()(strtok(?=\s|,))\
|(?<=&|\s|\[|\()(listen(?=\s|,))\
|(?<=&|\s|\[|\()(getenv(?=\s|,))\
|(?<=&|\s|\[|\()(getuid(?=\s|,))\
|(?<=&|\s|\[|\()(_isnull(?=\s|,))\
|(?<=&|\s|\[|\()(listdir(?=\s|,))\
|(?<=&|\s|\[|\()(isblank(?=\s|,))\
|(?<=&|\s|\[|\()(integer(?=\s|,))\
|(?<=&|\s|\[|\()(strjoin(?=\s|,))\
|(?<=&|\s|\[|\()(f?close(?=\s|,))\
|(?<=&|\s|\[|\()(f?write(?=\s|,))\
|(?<=&|\s|\[|\()(connect(?=\s|,))\
|(?<=&|\s|\[|\()(strchop(?=\s|,))\
|(?<=&|\s|\[|\()(sprintf(?=\s|,))\
|(?<=&|\s|\[|\()(strn?cmp(?=\s|,))\
|(?<=&|\s|\[|\()(f?printf(?=\s|,))\
|(?<=&|\s|\[|\()(wherenot(?=\s|,))\
|(?<=&|\s|\[|\()(realpath(?=\s|,))\
|(?<=&|\s|\[|\()(array_map(?=\s|,))\
|(?<=&|\s|\[|\()(qualifier(?=\s|,))\
|(?<=&|\s|\[|\()([l|f]seek(?=\s|,))\
|(?<=&|\s|\[|\()(_stkdepth(?=\s|,))\
|(?<=&|\s|\[|\()(get[gpu]id(?=\s|,))\
|(?<=&|\s|\[|\()(wherefirst(?=\s|,))\
|(?<=&|\s|\[|\()(array_sort(?=\s|,))\
|(?<=&|\s|\[|\()(strbytelen(?=\s|,))\
|(?<=&|\s|\[|\()(__p\w*_list(?=\s|,))\
|(?<=&|\s|\[|\()(strtrim_\w*(?=\s|,))\
|(?<=&|\s|\[|\()(list_insert(?=\s|,))\
|(?<=&|\s|\[|\()(substrbytes(?=\s|,))\
|(?<=&|\s|\[|\()(list_append(?=\s|,))\
|(?<=&|\s|\[|\()(errno_string(?=\s|,))\
|(?<=&|\s|\[|\()(string_match(?=\s|,))\
|(?<=&|\s|\[|\(|^)(sigprocmask(?=\s|,))\
|(?<=&|\s|\[|\()(list_to_array(?=\s|,))\
|(?<=&|\s|\[|\()(l?stat_\w*[e|s](?=\s|,))\
|(?<=&|\s|\[|\(|;|@)(__qualifiers(?=\s|,))\
|(?<=&|\s|\[|\()(qualifier_exists(?=\s|,))\
|(?<=&|\s|\[|\(|@)(__get_reference(?=\s|,))\
|(?<=&|\s|\[|\()(assoc_\w*_\w*[s,y](?=\s|,))\
|(?<=&|\s|\[|\()(f(get|put)s[lines]*(?=\s|,))\
|(?<=&|\s|\[|\()(__get_exception_info(?=\s|,|\.))\
|(?<=&|\s|\[|\()(path_\w*(nam|(i.*t)|conca)[e|t](?=\s|,)))+"R, 0),
%conditional
  pcre_compile ("\
(^\s*(if(?=\s))\
|^\s*(else if(?=\s))\
|^\s*(while(?=\s))\
|^\s*(else)(?=$|\s{2,}%)\
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
|((?<=\w|\])--(?=;|\)|,))\
|((?<=\w|\])\+\+(?=;|\)|,))\
|((?<=\s)[\&\|]+=? ~?)\
|((?<=\s)\?(?=\s))\
|((?<=\s):(?=\s))\
|((?<=\s)\+(?=\s))\
|((?<=\s)-(?=\s))\
|((?<=\s)\*(?=\s))\
|((?<=\s)/(?=\s))\
|((?<=\s)\&\&(?=\s|$))\
|((?<=\s)\|\|(?=[\s|$]))\
|((?<=').(?='))\
|((?<=\s)(mod|xor)(?=\s))\
|((?<=\s)\+=(?=\s))\
|((?<=\s)!=(?=\s))\
|((?<=\s)>=(?=\s))\
|((?<=\s)<=(?=\s))\
|((?<=\s)<(?=\s))\
|((?<=\s)>(?=\s))\
|((?<=\w)->(?=\w))\
|(?<=:|\s|\[)-?\d+(?=:|\s|\]|,|\)|;)\
|(?<=\s)(0x\d+)(?=;|,)\
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
|((?<!\w)finally(?=\s|$))\
|((?<!\w)return(?=[\s;]))\
|((?<!\w)break(?=;))\
|((?<!\w)exit .*(?=;))\
|((?<!\w)import(?=\s))\
|((?<!\w)continue(?=;))\
|((?<=[\(|\s])errno(?=[;|\)]))\
|(__arg[vc])\
|(SEEK_...)\
|(_NARGS|__FILE__|NULL)\
|((?<!\w)stderr(?=[,\)\.]))\
|((?<!\w)stdin(?=[,\)\.]))\
|((?<!\w)stdout(?=[,\)\.]))\
|((?<!\w)stdout(?=[,\)\.]))\
|((?<=\s|\|)[F|R|W]_OK(?=[,\|;\)]+))\
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
|((?<=\(|\s|\[|}|@)\w+_Type(?=[,\s\]\[;\)]))\
|((?<!\w)[\w]+Error(?=[:|,])))+"R, 0),
%errors
  pcre_compile ("\
((?<=\S)\s+$\
|(^\s+$))+"R, 0),
%comments
  pcre_compile ("((^\s*%.*)|((?<=[\)|;|\s])% .*))"R, 0),
];

define sl_lexicalhl (s, lines, vlines)
{
  __hl_groups (lines, vlines, colors, regexps);
}

