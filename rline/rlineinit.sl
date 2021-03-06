private variable msgwritten = 0;
private variable holdedcommand = NULL;
private variable historyseparator = repeat (char (166), 2);

static define restore (cmp_lnrs, ptr, refresh, columns)
{
  ifnot (NULL == cmp_lnrs)
    smg->restore (cmp_lnrs, ptr, refresh;columns = columns);
}

static define addlcmp (list, arg)
{
  list_insert (list, arg);

  if (10 < length (list))
    list = list[[:9]];
}

static define addhistory (hist, argv, force)
{
  argv = strjoin (argv, historyseparator);

  if (2 > strlen (argv))
    if (NULL == force)
      return hist;

  variable list = hist[wherenot (hist == argv)];

  list = [argv, length (list) > 100 ?
    list[[:99]] : list];

  return list;
}

static define writehistory (hist, histfile)
{
  ifnot (length (hist))
    return;

  if (NULL == histfile)
    return;

  ifnot (access (histfile, F_OK))
    if (-1 == access (histfile, W_OK))
      return;

  variable fp = fopen (histfile, "w");
  () = array_map (Integer_Type, &fprintf, fp, "%s\n", hist);
  () = fclose (fp);
}

static define readhistory (histfile)
{
  if (NULL == histfile)
    return String_Type[0];

  if (-1 == access (histfile, F_OK|R_OK))
    return String_Type[0];

  IO.readfile (histfile);
}

private define _execFunc_Type_ (func, argv)
{
  variable list = {};

  array_map (Void_Type, &list_append, list, argv[[1:]]);

  (@func) (__push_list (list);;struct {@__qualifiers (), argv0 = argv[0]});
}

private define _execline_ (s)
{
  ifnot (strlen (s.argv[0]))
    {
    ifnot (NULL == s.onnolength)
      ifnot (NULL == s.onnolengthargs)
        (@s.onnolength) (__push_list (s.onnolengthargs));
      else
        (@s.onnolength);
    return;
    }

  ifnot (any (assoc_get_keys (s.argvlist) == s.argv[0]))
    return;

  variable _addhistory = 1;

  if (1 < length (s.argv))
    ifnot (strlen (s.argv[-1]))
      s.argv = s.argv[[:-2]];

  if (NULL == s.argvlist[s.argv[0]].func)
    return;

  variable origargv = @s.argv;

  ifnot (NULL == s.argvlist[s.argv[0]].type)
    if (s.argvlist[s.argv[0]].type == "Proc_Type")
      (@exec->proctype) (s.argvlist[s.argv[0]].func, s.argv;;
        struct {@__qualifiers (), rl = s});
    else if (s.argvlist[s.argv[0]].type == "Func_Type")
      _execFunc_Type_ (s.argvlist[s.argv[0]].func, s.argv;;
        struct {@__qualifiers (), rl = s});
    else
      _addhistory = 0;
  else
    if (s.totype == "Proc_Type")
      (@exec->proctype) (s.argvlist[s.argv[0]].func, s.argv;;
        struct {@__qualifiers (), rl = s});
    else if (s.totype == "Func_Type")
      _execFunc_Type_ (s.argvlist[s.argv[0]].func, s.argv;;
        struct {@__qualifiers (), rl = s});
    else
      _addhistory = 0;

  if (_addhistory)
    {
    s.history = addhistory (s.history, origargv, s.historyaddforce);
    addlcmp (s.lcmp, origargv[-1]);
    }
}

static define set (s)
{
  s._state = 1;
  s._row = s._prow;
  s._col = qualifier ("col", strlen (s._pchar));
  s.ptr = qualifier ("ptr", [s._prow, 1]);
  s._lin = s._pchar + qualifier ("line", "");
  s._ind = qualifier ("ind", 0);
  s._chr = 0;
  s.lnrs = [s._prow];
  s.argv = qualifier ("argv", [""]);
}

private define _Null ()
{
  loop (_NARGS) pop ();
}

private define null_argtype ()
{
  loop (_NARGS) pop ();
  0;
}

static define init (getcommands)
{
  variable rl = @Rline_Type;

  % code needs to be written to check funcrefs
  rl.execline = qualifier ("execline", &_execline_);
  rl._pchar = qualifier ("pchar", ":");
  rl._prow = qualifier ("prow", PROMPTROW);
  rl._pclr = qualifier ("pclr", COLOR.prompt);
  rl.totype = qualifier ("totype", "Proc_Type");
  rl.filtercommands = qualifier ("filtercommands");
  rl.filterargs = qualifier ("filterargs");
  rl.tabhook = qualifier ("tabhook");
  rl.starthook = qualifier ("starthook"),
  rl.on_lang = qualifier ("on_lang", &_Null);
  rl.on_lang_args = qualifier ("on_lang_args", {});
  rl.histfile = qualifier ("histfile");
  rl.history = qualifier ("history", String_Type[0]);
  rl.historyaddforce = qualifier ("historyaddforce");
  rl.lcmp = qualifier ("lcmp", {});
  rl._lines = qualifier ("lines", LINES);
  rl._columns = qualifier ("columns", COLUMNS);
  rl.onnolength = qualifier ("onnolength");
  rl.onnolengthargs = qualifier ("onnolengthargs");
  rl.osappnew = qualifier ("osappnew");
  rl.osapprec = qualifier ("osapprec");
  rl.wind_mang = qualifier ("wind_mang");
  rl.parse_argtype = qualifier ("parse_argtype", &null_argtype);

  if (0 == length (rl.history) && NULL != rl.histfile)
    rl.history = readhistory (rl.histfile);

  ifnot (NULL == getcommands)
    rl.argvlist = (@getcommands);

  rl._row = rl._prow;

  rl;
}

private define find_col (col, columns)
{
  variable i = 0;
  while ((i + 1) * columns <= col)
    i++;

  i, col - (columns * i);
}

static define prompt (s, line, col)
{
  variable
    i,
    len = strlen (line),
    state = (len / s._columns) + 1,
    rows = Integer_Type[state],
    ar = String_Type[state];

  _for i (0, state - 1)
    (ar[i], rows[i]) = substr (line, int (sum (strlen (ar))) + 1, s._columns),
      s._prow - (state - i - 1);

  variable lcol;

  (i, lcol) = find_col (col, s._columns);

  s._row = rows[i];;

  if (state < s._state)
    restore (s.lnrs[[:state -1]], NULL, NULL, s._columns);

  s.lnrs = rows;
  s._state = state;

  if (msgwritten)
    {
    smg->atrcaddnstr (" ", 0, MSGROW, 0, s._columns);
    msgwritten = 0;
    }

  smg->aratrcaddnstrdr (ar, s._pclr, rows, 0, s._row, lcol, s._columns);
}

private define appendslash (file)
{
  if ('/' != file[-1] && 0 == (1 == strlen (file) && '.' == file[0]))
    return __isdirectory (file) ? "/" : "";

  "";
}

static define parse_args (s)
{
  variable
    i,
    found = NULL;

  (s._lin, s._ind) = s._pchar, NULL;

  _for i (0, length (s.argv) - 1)
    ifnot (NULL == s.argv[i])
      ifnot (strlen (s.argv[i]))
        if (i)
          if (NULL == found)
            found = 1;
          else
            {
            found = NULL;
            s.argv[i] = NULL;
            s._col--;
            }

  s.argv = s.argv[wherenot (_isnull (s.argv))];

  _for i (0, length (s.argv) - 1)
    {
    s._lin = sprintf ("%s%s%s", s._lin, i > 0 ? " " : "", s.argv[i]);

    if (NULL == s._ind)
      if (s._col <= strlen (s._lin))
        s._ind = i - (s._col == strlen (s._lin) - strlen (s.argv[i]) - 1);
    }

  ifnot (strlen (s._lin))
    (s.argv, s._ind) = [""], 0;

  if (NULL == s._ind)
    s._ind = length (s.argv) - 1;

  if (s._col == strlen (s._lin) && 2 == length (s.argv) - s._ind)
    s.argv = s.argv[[:-2]];

  if (s._col > strlen (s._lin) + 1)
    s._col = strlen (s._lin) + 1;
}

private define delete_at (s)
{
  variable
    i,
    arglen,
    len = 0;

  ifnot (qualifier_exists ("is_delete"))
    s._col--;

  _for i (0, s._ind)
    {
    arglen = strlen (s.argv[i]);
    len += arglen + strlen (s._pchar);
    }

  len = s._col - (len - arglen);

  if (0 > len)
    {
    if (arglen)
      s.argv[i-1] += s.argv[i];

    s.argv[i] = NULL;
    s.argv = s.argv[wherenot (_isnull (s.argv))];
    }
  else
    ifnot (len)
      s.argv[i] = substr (s.argv[i], 2, -1);
    else
      if (len + strlen (s._pchar) == arglen)
        s.argv[i] = substr (s.argv[i], 1, len);
      else
        s.argv[i] = substr (s.argv[i], 1, len) +
          substr (s.argv[i], len + 2, -1);
}

private define insert_at (s)
{
  variable
    i,
    arglen,
    len = 0,
    chr = char (qualifier ("chr", s._chr));

  s._col++;

  _for i (0, s._ind)
    {
    arglen = strlen (s.argv[i]);
    len += arglen + strlen (s._pchar);;
    }

  len = s._col - (len - arglen);

  if (s._col == len)
    s.argv[i] += chr;
  else
    ifnot (len)
      if (i > 0)
        s.argv[i-1] += chr;
      else
        s.argv[i] = chr + s.argv[i];
    else
      s.argv[i] = sprintf ("%s%s%s", substr (s.argv[i], 1, len - 1), chr,
        substr (s.argv[i], len, -1));
}

static define routine (s)
{
  if (any ([keys->rmap.backspace] == s._chr))
    {
    if (s._col > strlen (s._pchar))
      delete_at (s);
    return;
    }

  if (any (keys->rmap.delete == s._chr))
    {
    if (s._col <= strlen (s._lin))
      ifnot (s._col == strlen (strjoin (s.argv[[:s._ind]], " ")) + 1)
        delete_at (s;is_delete);
      else
        if (s._ind < length (s.argv) - 1)
          {
          s.argv[s._ind] += s.argv[s._ind+1];
          s.argv[s._ind+1] = NULL;
          s.argv = s.argv[wherenot (_isnull (s.argv))];
          }

    return;
    }

  if (any (keys->rmap.left == s._chr))
    {
    if (s._col > strlen (s._pchar))
      {
      s._col--;
      smg->setrcdr (s._row, s._col);
      }

    return;
    }

  if (any (keys->rmap.right == s._chr))
    {
    if (s._col < strlen (s._lin))
      {
      s._col++;
      smg->setrcdr (s._row, s._col);
      }

    return;
    }

  if (any (keys->rmap.home == s._chr))
    {
    s._col = strlen (s._pchar);
    smg->setrcdr (s._row, s._col);
    return;
    }

  if (any (keys->rmap.end == s._chr))
    {
    s._col = strlen (s._lin);
    smg->setrcdr (s._row, s._col);
    return;
    }


  if (' ' == s._chr)
    {
    if (qualifier_exists ("insert_ws"))
      {
      insert_at (s);
      return;
      }

    ifnot (s._ind)
      {
      if (1 == s._col)
        if (qualifier_exists ("accept_ws"))
          {
          insert_at (s);
          return;
          }
        else
          return;

      ifnot (length (s.argv) - 1)
        s.argv = [
          substr (s.argv[0], 1, s._col - 1),
          substr (s.argv[0], s._col, -1)];
      else
        s.argv = [
          substr (s.argv[0], 1, s._col - 1),
          substr (s.argv[0], s._col, -1),
          s.argv[[1:]]];

      s._col++;
      return;
      }

    if (' ' == smg->char_at ())
      {
      if (s._ind == length (s.argv) - 1)
        (s.argv = [s.argv, ""], s._col++);
      else if (strlen (strjoin (s.argv[[:s._ind]], " ")) == s._col - 1)
        (s.argv = [s.argv[[:s._ind]], "", s.argv[[s._ind + 1:]]],
        s._col++);
      else
        insert_at (s);

      return;
      }
    }

  if (' ' < s._chr <= 126 || 902 <= s._chr <= 974)
    insert_at (s);
}

private define write_completion_routine (s, ar)
{
  variable
    i,
    _prow = qualifier ("_prow", s._prow),
    _lin = qualifier ("_lin", s._lin),
    len = length (ar),
    clrs = Integer_Type[len],
    cols = Integer_Type[len];

  s.cmp_lnrs = Integer_Type[len];

  clrs[*] = 11;
  cols[*] = 0;

  len = _prow - 1 - (strlen (_lin) / s._columns) - len + 1;

  _for i (0, length (ar) - 1)
    s.cmp_lnrs[i] = len + i;

  smg->aratrcaddnstr (ar, clrs, s.cmp_lnrs, cols, s._columns);
}

private define printout (s, ar, col, len)
{
  variable lrow = s._prow - (strlen (s._lin) / s._columns);
  variable lar = widg->printtoscreen (ar, lrow, len, &s.cmp_lnrs;;__qualifiers ());
  variable lcol;
  (, lcol) = find_col (col, s._columns);

  smg->setrcdr (s._row, lcol);

  lar;
}

private define firstindices (str, ar, pat)
{
  variable
    index = "." == pat ? 0 : strlen (pat),
    len = strlen (ar[0]),
    new_str = len > index ? ar[0][[0:index]] : NULL,
    indices = NULL != new_str ? array_map (Char_Type, &string_match, ar,
        str_quote_string (sprintf ("^%s", new_str), ".+", '\\')) : [0];

  ifnot (length (ar) == length (where (indices)))
    return;

  if ("." != pat)
    @str +=pat;
  else
    @str = "";

  while (NULL != new_str)
    {
    indices = array_map (Char_Type, &string_match, ar,
        str_quote_string (sprintf ("^%s", new_str), ".", '\\'));

    if (length (ar) == length (where (indices)))
      {
      @str += char (new_str[-1]);
      index++;
      new_str = len > index ? ar[0][[0:index]] : NULL;
      }
    else
      return;
    }
}

private define append_dir_indicator (base, files)
{
  variable ar = @files;

  ar[where (array_map (Char_Type, &_isdirectory,
    array_map (String_Type, &path_concat, base, files)))] += "/";

  ar;
}

private define _sort_by_mtime_ (dir, ar)
{
  variable lar = array_map (String_Type, &path_concat, dir, ar);
  variable st = array_map (Struct_Type, &stat_file, lar);
  st = st[wherenot (_isnull (st))];
  array_sort (array_map (ULong_Type, &get_struct_field, st, "st_mtime");dir = -1);
}

private define listdirectory (retval, dir, pat, pos)
{
  variable
    ar = String_Type[0],
    st = stat_file (dir);

  if (NULL == st)
    {
    @retval = -1;
    return ar;
    }

  ifnot (stat_is ("dir", st.st_mode))
    return [dir];

  ar = listdir (dir);

  if (NULL == ar)
    {
    @retval = -1;
    return ar;
    }

  ifnot (NULL == pat)
    ar = ar[wherenot (array_map (Char_Type, &strncmp, ar, pat, pos))];

  variable sort = qualifier ("sort");

  if (NULL != sort && sort == "mtime")
    ar[_sort_by_mtime_ (dir, ar)];
  else
    ar[array_sort (ar)];
}

private define formar (items, fmt, ar, bar)
{
  @bar = String_Type[0];

  ifnot (items)
    return;

  variable i = 0;

  while (i < length (ar))
    {
    if (i + items < length (ar))
      @bar = [@bar, strjoin (array_map (
        String_Type, &sprintf, fmt, ar[[i:i + items - 1]]))];
    else
      @bar = [@bar, strjoin (array_map (String_Type, &sprintf, fmt, ar[[i:]]))];

    i += items;
    }
}

private define hlitem (s, ar, base, acol, item)
{
  variable
    chr,
    car,
    bar,
    len,
    tmp,
    bcol,
    irow,
    lrow = s._prow - (strlen (s._lin) / s._columns),
    items = 1,
    i = 0,
    frow,
    page = 0,
    icol = 0,
    colr = 5,
    index = 0,
    header = qualifier ("header"),
    max_len = max (strlen (ar)) + 2,
    fmt = sprintf ("%%-%ds", max_len),
    lines;

  ifnot (qualifier_exists ("dont_format"))
    if (max_len < s._columns)
      items = s._columns / max_len;
    else
      items = 1;

  ifnot (qualifier_exists ("dont_format"))
    if (max_len < s._columns)
      if ((items - 1) + (max_len * items) > s._columns)
        items--;

  while ((i + 1) * s._columns <= acol)
    i++;

  bcol = acol - (s._columns * i);

  ifnot (qualifier_exists ("dont_format"))
    formar (items, fmt, ar, &bar);
  else
    bar = @ar;

  len = length (bar);
  @item = ar[index];
  lines = lrow - 2;

  car = @bar;

  irow = lrow - (length (car) > lines ? lines : length (car));

  frow = irow - 1;

  bar = printout (s, bar, bcol, &len;lines = lines,
    hl_region = [colr, irow, icol * max_len, 1, max_len], header = header);

  ifnot (NULL == header)
    s.cmp_lnrs = [s.cmp_lnrs[0] - 1, s.cmp_lnrs];

  chr = getch (;disable_langchange);

  ifnot (len || any (['\t', [keys->UP:keys->RIGHT], keys->PPAGE, keys->NPAGE] == chr))
    {
    restore (s.cmp_lnrs, [s._row, s._col], 1, s._columns);
    return chr;
    }

  while ( any (['\t', [keys->UP:keys->RIGHT], keys->PPAGE, keys->NPAGE] == chr))
    {
    if ('\t' == chr)
      if (lines >= length (car) && page == 0)
        chr = keys->RIGHT;
      else
        chr = keys->NPAGE;

    if (keys->NPAGE == chr)
      {
      restore (s.cmp_lnrs, [s._row, s._col], 1, s._columns);
      ifnot (len)
        {
        ifnot (qualifier_exists ("dont_format"))
          formar (items, fmt, ar, &bar);
        else
          bar = @ar;

        page = 0;
        }

      if (len)
        page++;

      len = length (bar);

      index = (page) * ((lines - 1) * items);

      @item = ar[index];

      car = @bar;

      irow = lrow - (length (car) > lines ? lines : length (car));
      icol = 0;

      if (length (bar) < lines)
        restore (s.cmp_lnrs, [s._row, s._col], 1, s._columns);

      frow = irow - 1;

      bar = printout (s, bar, bcol, &len;lines = lines,
        hl_region = [colr, irow, icol * max_len, 1, max_len], header = header);

      ifnot (NULL == header)
        s.cmp_lnrs = [s.cmp_lnrs[0] - 1, s.cmp_lnrs];

      chr = getch (;disable_langchange);
      continue;
      }

    if (keys->UP == chr)
      if ((0 == index || index < items) && 1 < length (car))
        {
        (irow, icol, index) =
          lrow - 1,
          length (car) >= lines
            ? items - 1
            : length (car) mod items
              ? (length (strtok (strjoin (car, " "))) mod items) - 1
              : items - 1,
          length (car) >= lines
            ? ((page) * (lines * items)) + ((lines - 1) * items) + items - 1
            : length (ar) - 1;
        }
      else
        {
        irow--;
        index -= items;
        if (0 == irow || 1 == length (car))
          (irow, icol, index) =
            lrow - 1,
            length (car) >= lines
              ? items - 1
              : length (strtok (strjoin (car, " "))) mod items
                ? (length (strtok (strjoin (car, " "))) mod items) - 1
                : items - 1,
            length (car) >= lines
              ? ((page) * ((lines - 1) * items)) + ((lines - 1) * items) + items - 1
              : length (ar) - 1;
        }

    if (keys->DOWN == chr)
      if (irow > lines || index + items > length (ar) - 1)
        (irow, icol, index) =
          lrow - (length (car) > lines ? lines : length (car)),
          0,
          page * ((lines - 1) * items);
      else
        {
        irow++;
        index += items;
        }

    if (keys->LEFT == chr)
      {
      icol--;
      index--;
      if (-1 == index)
        if (length (car) < lines)
          (irow, icol, index) =
            lrow - 1,
            length (strtok (strjoin (car, " "))) mod items
              ? (length (strtok (strjoin (car, " "))) mod items) - 1
              : items - 1,
              length (ar) - 1;

      if (-1 == icol)
        {
        irow--;
        icol = length (car) mod items
          ? (length (strtok (strjoin (car, " "))) mod items) - 1
          : items - 1;
        }

      ifnot (irow)
        if (lines > length (car))
          {
          irow++;
          icol = 0;
          index++;
          }
        else
          (irow, icol, index) =
            lrow - 1,
            items - 1,
           ((page) * ((lines - 1) * items)) + ((lines - 1) * items) + items - 1;
      }

    if (keys->RIGHT == chr)
      if (index + 1 > length (ar) - 1)
        (irow, icol, index) =
          lrow - (length (car) > lines ? lines : length (car)),
          0,
          (page) * ((lines - 1) * items);
      else if (icol + 1 == items)
        ifnot (irow > lines)
          {
          irow++;
          icol = 0;
          index++;
          }
        else
          (irow, icol, index) =
            lrow - (length (car) > lines ? lines : length (car)),
            0,
            (page) * ((lines - 1) * items);
      else
        {
        index++;
        icol++;
        }

    if (keys->PPAGE== chr)
      {
      restore (s.cmp_lnrs, [s._row, s._col], 1, s._columns);
      ifnot (page)
        {
        if (length (car) > lines)
          page = 0;

        ifnot (qualifier_exists ("dont_format"))
          formar (items, fmt, ar, &car);
        else
          car = @ar;

        len = length (car);

        while (len > lines)
          {
          page++;
          car = car[[lines - 1:]];
          bar = car;
          len = length (car);
          }

        (irow, icol, index) =
          lrow - (length (car) > lines ? lines : length (car)),
          0,
          (page) * ((lines - 1) * items);

        if (length (car) < lines)
          restore (s.cmp_lnrs, [s._row, s._col], 1, s._columns);
        }
      else
        {
        page--;
        ifnot (qualifier_exists ("dont_format"))
          formar (items, fmt, ar, &car);
        else
          car = @ar;

        loop (page)
          {
          len = length (car);
          car = car[[lines - 1:]];
          }

        bar = car[[lines - 1:]];

        (irow, icol, index) =
          lrow - (length (car) > lines ? lines : length (car)),
          0,
          (page) * ((lines - 1) * items);
        }
      }

    @item = ar[index];

    len = length (car);

    restore (s.cmp_lnrs, [s._row, s._col], 1, s._columns);

    frow = irow - 1;

    () = printout (s, car, bcol, &len;lines = lines,
      hl_region = [colr, irow, icol * max_len, 1, max_len], header = header);

    ifnot (NULL == header)
      s.cmp_lnrs = [s.cmp_lnrs[0] - 1, s.cmp_lnrs];

    chr = getch (;disable_langchange);
    }

  chr;
}

private define lcmpcompletion (s)
{
  ifnot (length (s.lcmp))
    return 0;

  variable
    chr,
    line,
    i = 0,
    lcmp = s.lcmp[i],
    len = strlen (lcmp),
    col = s._col;

  forever
    {
    line = sprintf ("%s%s%s", strjoin (s.argv[[0:s._ind]], " "),
      lcmp, s._ind == length (s.argv) ? "" :
      " " + strjoin (s.argv[[s._ind+1:]], " "));

    prompt (s, ":" + line, col + len);

    chr = getch ();

    if (any (keys->rmap.lastcmp == chr))
      {
      i = (i + 1) == length (s.lcmp) ? 0 : i + 1;
      lcmp = s.lcmp[i];
      len = strlen (lcmp);
      continue;
      }

    if ('\r' == chr || 1 == (' ' <= chr <= '~') || any (keys->rmap.backspace == chr))
      {
      if (0 == strlen (s.argv[s._ind])
        || " " == s.argv[s._ind])
        s.argv[s._ind] = lcmp;
      else
        s.argv[s._ind] += lcmp;

      parse_args (s);

      s._col += strlen (lcmp);

      if ('\r' == chr)
        return 1;
      }

    if (' ' == chr)
      {
      if (s._ind == length (s.argv) - 1)
        (s.argv = [s.argv, ""], s._col++);
      else if (strlen (strjoin (s.argv[[:s._ind]], " ")) == s._col - 1)
        (s.argv = [s.argv[[:s._ind]], "", s.argv[[s._ind + 1:]]],
        s._col++);

      parse_args (s);

      prompt (s, s._lin, s._col);

      return 0;
      }

    if (any (keys->rmap.backspace == chr))
      {
      delete_at (s);
      parse_args (s);
      prompt (s, s._lin, s._col);
      return 0;
      }

    insert_at (s;chr = chr);

    parse_args (s);

    prompt (s, s._lin, s._col);

    return 0;
    }
}

private define fnamecmp (s, start)
{
  variable
    ar,
    st,
    str,
    tmp,
    file,
    isdir,
    retval,
    chr = 0,
    sort = "name",
    pat = "";

 if (' ' != start[0])
    {
    tmp = appendslash (start);
    if ("/" == tmp)
      {
      s.argv[s._ind] += tmp;
      s._col += strlen (tmp);
      parse_args (s);
      prompt (s, s._lin, s._col);
      }
    }

  forever
    {
    pat = "";
    tmp = strlen (s._lin) ? s.argv[s._ind] : "";

    file = ' ' == (s._lin)[-1] ? getcwd () :
      sprintf ("%s%s", Dir.eval (tmp;dont_change), appendslash (tmp));

    if (2 < strlen (file))
      if ("./" == file[[0:1]] && 0 == strlen (s.argv[s._ind]))
        file = file[[2:]];

    if (access (file, F_OK) || '/' != (s._lin)[-1])
      {
      pat = path_basename (file);
      file = path_dirname (file);
      }

    retval = 0;
    ar = listdirectory (&retval, file, pat, strlen (pat);sort = sort);

    if (-1 == retval || 0 == length (ar))
      {
      restore (s.cmp_lnrs, [s._row, s._col], 1, s._columns);
      prompt (s, s._lin, s._col);
      return 0;
      }

    ifnot (1 == length (ar))
      {
      str = "";

      firstindices (&str, ar, pat);

      if (strlen (str))
        {
        str = path_concat (file, str);
        s.argv[s._ind] = sprintf ("%s%s", str, appendslash (str));
        if ("./" == s.argv[s._ind][[0:1]])
          s.argv[s._ind] = substr (s.argv[s._ind], 3, -1);

        s._col = strlen (strjoin (s.argv[[:s._ind]], " ")) + 1;

        parse_args (s);
        prompt (s, s._lin, s._col);
        }
      }

    tmp = "";
    chr = hlitem (s, append_dir_indicator (file, ar), file, s._col, &tmp);

    if (keys->CTRL_n == chr)
      {
      sort = "mtime";
      continue;
      }

    if (033 == chr)
      {
      restore (s.cmp_lnrs, NULL, NULL, s._columns);
      prompt (s, s._lin, s._col);

      return 0;
      }

    if (' ' == chr)
      {
      file = path_concat (file, tmp[-1] == '/' ? substr (tmp, 1, strlen (tmp) - 1) : tmp);
      st = stat_file (file);

      ifnot (NULL == st)  % THIS SHOULD NOT FAIL
        {
        isdir = stat_is ("dir", st.st_mode);
        s.argv[s._ind] = sprintf ("%s%s", file, isdir ? "/" : "");

        if ("./" == s.argv[s._ind][[0:1]])
          s.argv[s._ind] = substr (s.argv[s._ind], 3, -1);
        s._col = strlen (strjoin (s.argv[[:s._ind]], " ")) + 1;

        parse_args (s);

        if (isdir)
          {
          restore (s.cmp_lnrs, [s._row, s._col], 1, s._columns);
          prompt (s, s._lin, s._col);
          continue;
          }
        }
      }

    if (any (keys->rmap.backspace == chr) && strlen (s._lin))
      {
      delete_at (s);
      parse_args (s);
      restore (s.cmp_lnrs, [s._row, s._col], 1, s._columns);
      prompt (s, s._lin, s._col);
      return 0;
      }

    if (' ' == chr)
      if (length (ar))
        {
        ar = array_map (String_Type, &path_concat, file, ar);
        ar = ar[wherenot (array_map (Char_Type, &strncmp, ar,
          s.argv[s._ind] + " ", strlen (s.argv[s._ind]) + 1))];

        if (length (ar))
          {
          s.argv[s._ind] = sprintf ("%s%s", ar[0], appendslash (ar[0]));
          s._col = strlen (strjoin (s.argv[[:s._ind]], " ")) + 1;
          parse_args (s);
          }
        }
      else
        {
        restore (s.cmp_lnrs, [s._row, s._col], 1, s._columns);
        prompt (s, s._lin, s._col);
        return 0;
        }

    if ('\r' == chr || 0 == chr || 0 == (' ' < chr <= '~'))
      {
      restore (s.cmp_lnrs, '\r' == chr ? s.ptr : [s._row, s._col], 1, s._columns);
      ifnot ('\r' == chr)
        prompt (s, s._lin, s._col);

      return '\r' == chr;
      }

    insert_at (s;chr = chr);

    if (strlen (appendslash (s.argv[s._ind])))
      insert_at (s;chr = '/');

    parse_args (s);
    restore (s.cmp_lnrs, NULL, NULL, s._columns);
    prompt (s, s._lin, s._col);
    }
}

static define commandcmp (s, commands)
{
  variable
    i,
    ar,
    str,
    col,
    len,
    fmt,
    bar,
    chr,
    tmp,
    help,
    indices,
    orighelp = qualifier ("help");

  commands = commands[array_sort (commands)];

  forever
    {
    indices = strlen (s.argv[0])
      ? wherenot (strncmp (commands, s.argv[0], strlen (s.argv[0])))
      : [0:length (commands) - 1];

    ar = commands[[indices]];

    ifnot (NULL == s.filtercommands)
      ar = (@s.filtercommands) (s, ar);

    ifnot (length (ar))
      {
      restore (s.cmp_lnrs, [s._row, s._col], 1, s._columns);
      return 0;
      }

    if (1 == length (ar) && 0 == qualifier_exists ("accept_one_len"))
      {
      restore (s.cmp_lnrs, NULL, NULL, s._columns);
      s.argv[0] = ar[0];
      s._col = strlen (ar[0]) + 1;
      parse_args (s);
      prompt (s, s._lin, s._col);
      return 0;
      }

    ifnot (NULL == orighelp)
      help = orighelp[[indices]];

    str = "";
    firstindices (&str, ar, s.argv[0]);

    if (strlen (str))
      {
      s.argv[0] = str;
      s._col = strlen (str) + 1;
      parse_args (s);
      prompt (s, s._lin, s._col);
      }

    bar = @ar;

    ifnot (NULL == orighelp)
      {
      fmt = sprintf ("%%-%ds  %%s", max (strlen (bar)));
      bar = array_map (String_Type, &sprintf, fmt, bar, help);
      }

    tmp = "";
    chr = hlitem (s, bar, s.argv[0], s._col, &tmp);

    if (' ' == chr)
      {
      restore (s.cmp_lnrs, NULL, NULL, s._columns);

      s.argv[s._ind] = strchop (tmp, ' ', 0)[0];
      s._col = strlen (s.argv[0]) + 1;
      parse_args (s);
      prompt (s, s._lin, s._col);

      return 0;
      }

    if (any (keys->rmap.backspace == chr) && s._col > 1)
      {
      delete_at (s);
      parse_args (s);
      restore (s.cmp_lnrs, [s._row, s._col], 1, s._columns);
      return 0;
      }

    if (033 == chr && qualifier_exists ("return_on_esc"))
      return chr;

    if (any ([' ', '\r'] == chr) || 0 == ('!' <= chr <= 'z'))
      {
      restore (s.cmp_lnrs, '\r' == chr ? s.ptr : [s._row, s._col], 1, s._columns);
      return '\r' == chr;
      }

    s.argv[0] += char (chr);

    s._col = strlen (s.argv[0]) + 1;
    parse_args (s);
    prompt (s, s._lin, s._col);
    }
}

static define fnamecmpToprow (s, fname)
{
  variable
    ar,
    st,
    str,
    tmp,
    file,
    isdir,
    retval,
    chr = 0,
    pat = "";

  if (' ' != (@fname)[0])
    @fname += appendslash (@fname);

  forever
    {
    pat = "";
    tmp = strlen (@fname) ? @fname : "";
    file = ' ' == (@fname)[-1] ? getcwd () :
      sprintf ("%s%s", Dir.eval (tmp;dont_change), appendslash (tmp));

    if (2 < strlen (file))
      if ("./" == file[[0:1]] && 0 == strlen (@fname))
        file = file[[2:]];

    if (access (file, F_OK) || '/' != (@fname)[-1])
      {
      pat = path_basename (file);
      file = path_dirname (file);
      }

    retval = 0;
    ar = listdirectory (&retval, file, pat, strlen (pat));

    if (-1 == retval || 0 == length (ar))
      return 0;

    if (length (ar))
      if (qualifier_exists ("only_dirs"))
        ar = ar[where (array_map (Char_Type, &__isdirectory,
          array_map (String_Type, &path_concat, file, ar)))];
      else if (qualifier_exists ("only_blcks"))
        {
        st = array_map (Struct_Type, &stat_file,
          array_map (String_Type, &path_concat, file, ar));
        st = st[wherenot (_isnull (st))];
        st = array_map (Integer_Type, &get_struct_field, st, "st_mode");
        ar = ar[where (array_map (Char_Type, &stat_is, "blk", st))];
        }

    ifnot (length (ar))
      return 0;

    ifnot (1 == length (ar))
      {
      str = "";
      firstindices (&str, ar, pat);

      if (strlen (str))
        {
        str = path_concat (file, str);
        @fname = sprintf ("%s%s", str, appendslash (str));
        if ("./" == (@fname)[[0:1]])
          @fname = substr (@fname, 3, -1);
        }
      }

    tmp = "";

    chr = hlitem (s, append_dir_indicator (file, ar), file, s._col, &tmp;
      header = qualifier ("header", @fname));

    s.cmp_lnrs = [s.cmp_lnrs[0] - 1, s.cmp_lnrs];

    if (033 == chr)
      {
      restore (s.cmp_lnrs, NULL, NULL, s._columns);
      return 033;
      }

    if (' ' == chr)
      {
      file = path_concat (file, tmp[-1] == '/' ? substr (tmp, 1, strlen (tmp) -1) : tmp);
      st = stat_file (file);

      ifnot (NULL == st)  % THIS SHOULD NOT FAIL
        {
        isdir = stat_is ("dir", st.st_mode);
        @fname = sprintf ("%s%s", file, isdir ? "/" : "");
        if ("./" == (@fname)[[0:1]])
          @fname = substr (@fname, 3, -1);

        if (isdir)
          {
          restore (s.cmp_lnrs, [s._row, s._col], 1, s._columns);
          continue;
          }
        }
      }

    if (any (keys->rmap.backspace == chr) && strlen (@fname))
      {
      restore (s.cmp_lnrs, [s._row, s._col], 1, s._columns);
      @fname = substr (@fname, 1, strlen (@fname) - 1);
      continue;
      }

    if (' ' == chr)
      if (length (ar))
        {
        ar = array_map (String_Type, &path_concat, file, ar);
        ar = ar[wherenot (array_map (Char_Type, &strncmp, ar,
          @fname + " ", strlen (@fname) + 1))];
        if (length (ar))
          @fname = sprintf ("%s%s", ar[0], appendslash (ar[0]));
        }
      else
        return 0;

    if ('\r' == chr || 0 == chr || 0 == (' ' < chr <= '~'))
      {
      restore (s.cmp_lnrs, [s._row, s._col], 1, s._columns);
      return '\r' == chr;
      }

    @fname += char (chr);
    @fname += appendslash (@fname);
    }
}

private define _null_ ()
{
  return NULL;
}

% - buggy -
% probably renaming, should be agnostic (pchar, row, col),
% get one line
% grow symmetrically to left and right
% enter accepts
% escape returns (what?) (maybe a reference line var -> rl.argv[0])
% the implementation can be used to replace standard rline routines
% make a type and insert fields on demand,
% add a loadfrom to that point and mark it (under development)
% destroy the object

static define __gettxt (str, row, col)
{
  variable rl = init (&_null_);

  set (rl);

  col = NULL == col ? strlen (rl.argv[0]) + 1 : col;
  rl._pclr = qualifier ("clr", 16);
  rl.argv = [str];
  rl._col = col;
  rl._prow = row;
  rl._ind = 0;
  rl._lin = rl.argv[0];
  rl._pchar = "";

 smg->atrcaddnstrdr (strlen (rl._lin) ? rl._lin : " ", rl._pclr, rl._prow,
   col, rl._prow, rl._col - 1, strlen (rl._lin) ? strlen (rl._lin) : 1);

  forever
    {
    rl._chr = getch ();
    if (033 == rl._chr)
      return rl;

    routine (rl;insert_ws);
    rl._lin = rl.argv[0];
    smg->atrcaddnstrdr (rl._lin, rl._pclr, rl._prow, col, rl._prow,
     rl._col - 1, strlen (rl._lin));
    }
}

private define getpattern (s, pat)
{
  variable pcrepat;
  variable err;
  variable rl = init (&_null_);

  set (rl);

  rl._chr = 0;
  rl.argv = [@pat];
  rl._col = strlen (rl.argv[0]) + 1;
  rl._ind = 0;
  rl._lin = rl.argv[0];

  variable
    ar = IO.readfile (Dir->Vget ("STDDATADIR") + "/Txt_Type/pcresyntax.txt"),
    len = length (ar),
    lines = s._lines - (strlen (s._lin) / s._columns) - 3,
    prow = s._prow - (strlen (s._lin) / s._columns) - (len > lines ? lines : len) - 1;

  () = printout (rl, ar, strlen (rl.argv[0]), &len;lines = lines, _prow = s._prow,
     _lin = s._lin, header = strlen (@pat) ? @pat : " ", headerclr = 7);

  smg->setrcdr (prow, strlen (rl.argv[0]));

  forever
    {
    rl._chr = getch (;on_lang = s.on_lang, on_lang_args = s.on_lang_args);

    if (1 == rl._col)
      smg->atrcaddnstr (" ", 0, MSGROW, 0, s._columns);

    if (any (['\r', 033] == rl._chr))
      {
      @pat = '\r' == rl._chr ? rl.argv[0] : "";
      s.cmp_lnrs = rl.cmp_lnrs;
      return;
      }

    rl._lin = rl.argv[0];
    routine (rl;insert_ws);

    try (err)
      {
      pcrepat = pcre_compile (rl.argv[0], 0);
      smg->atrcaddnstr (" ", 0, MSGROW, 0, s._columns);
      }
    catch ParseError:
      smg->atrcaddnstr (err.descr, 1, MSGROW, 0, s._columns);

    smg->atrcaddnstrdr (rl.argv[0], 7, prow, 0, prow, rl._col - 1, rl._columns);
    }
}

% split to functions so we can call them from the structure
% so they can be binded by the interesting parties
private define __parse_argtype__ (s, arg, type, baselen)
{
  variable col;

  if ("--pat=" == arg || "pattern" == type)
    type = "pcrepattern";

  if (any (["int", "string"] == type))
    {
    (, col) = find_col (s._col, s._columns);
    prompt (s, s._lin, s._col);
    smg->atrcaddnstrdr ("arg type should be " + type, 1, MSGROW, 0, s._row, col, s._columns);
    msgwritten = 1;
    return;
    }

  variable tmp;
  variable pat = qualifier ("pat", strchop (s.argv[s._ind], '=', 0));

  if (Array_Type == typeof (pat))
    if (1 < length (pat))
      pat = pat[1];
    else
      pat = "";

  if ("pcrepattern" == type)
      {
      smg->atrcaddnstr ("arg type should be " + type, 1, MSGROW, 0, s._columns);

      prompt (s, s._lin, s._col);

      getpattern (s, &pat;;__qualifiers ());

      if (strlen (pat))
        {
        s.argv[s._ind] += pat;
        s._col = baselen + strlen (s.argv[s._ind]) + 1;
        parse_args (s);
        }

      s.cmp_lnrs = [s.cmp_lnrs[0] - 1, s.cmp_lnrs];
      restore (s.cmp_lnrs, NULL, NULL, s._columns);
      prompt (s, s._lin, s._col);

      return;
      }

  if (any (["filename", "directory", "device", "mountpoint"] == type))
      {
      prompt (s, s._lin, s._col);

      if ("device" == type)
        tmp = strlen (pat) ? pat : "/dev/sd";
      else if ("mountpoint" == type)
        tmp = strlen (pat) ? pat : "/media/removable/";
      else
        tmp = strlen (pat) ? pat : "";

      if (any (["directory", "mountpoint"]  == type))
        () = fnamecmpToprow (s, &tmp;only_dirs);
      else if ("device" == type)
        () = fnamecmpToprow (s, &tmp;only_blcks);
      else
        () = fnamecmpToprow (s, &tmp);

      s.argv[s._ind] += tmp;
      s._col = baselen + strlen (s.argv[s._ind]) + 1;
      parse_args (s);

      s.cmp_lnrs = [s.cmp_lnrs[0] - 1, s.cmp_lnrs];
      prompt (s, s._lin, s._col);
      }
}

private define parse_argtype (s, arg, type, baselen)
{
  if ("void" == type)
    {
    prompt (s, s._lin, s._col);
    return;
    }

  if (s.parse_argtype (arg, type, baselen;;__qualifiers))
    return;

  __parse_argtype__ (s, arg, type, baselen;;__qualifiers);

}

private define argcompletion (s)
{
  variable
    i,
    col,
    tmp,
    chr = 0,
    ar = NULL,
    args = qualifier ("args");

  ifnot (NULL == args)
    ar = args;
  else
    if (NULL != s.argvlist[s.argv[0]].args)
      ar = s.argvlist[s.argv[0]].args;

  if (ar == NULL == args)
    {
    variable file = qualifier ("file");
    if (NULL == file)
      {
      file = s.argvlist[s.argv[0]].dir;
      if (NULL == file)
        return 0;

      file = file + "/args.txt";

      if (-1 == access (file, F_OK|R_OK))
        return 0;
      }

    ar = IO.readfile (file);
    }

  if (NULL == ar || typeof (ar) != Array_Type || 0 == length (ar))
    return 0;

  variable arg = qualifier ("arg", s.argv[s._ind]);
  variable base = qualifier ("base", strjoin (s.argv[[:s._ind - 1]], " "));
  variable baselen = strlen (base) + 1;
  variable len = length (ar);
  variable type = String_Type[len];
  variable desc = String_Type[len];

  s._col = baselen + ("." != arg ? strlen (arg) : 0) + 1;

  args = String_Type[len];

  _for i (0, len - 1)
    if (3 != sscanf (ar[i], "%s %s %[ -ώ]", &args[i], &type[i], &desc[i]))
      return 0;

  ifnot (NULL == s.filterargs)
    (args, type, desc) = (@s.filterargs) (s, args, type, desc);

  variable bar = array_sort (args);
  args = args[bar];
  type = type[bar];
  desc = desc[bar];

  len = length (args);

  if (1 == len)
    {
    arg = strchop (args[0], ',', 0);
    s.argv[s._ind] = 1 < length (arg) ? arg[-1] : arg[0];
    s._col = baselen + strlen (s.argv[s._ind]) + 1;
    parse_args (s);

    parse_argtype (s, arg[0], type[0], baselen;;__qualifiers ());
    return 0;
    }

  forever
    {
    ifnot (strlen (arg))
      ifnot (qualifier_exists ("accept_ws"))
        {
        prompt (s, s._lin, s._col);
        return 0;
        }

    ar = where (array_map (Char_Type, &string_match, args, sprintf ("^%s", arg), 1));

    ifnot (length (ar))
      return 0;

    if (1 == length (ar))
      {
      arg = strchop (args[ar[0]], ',', 0);
      s.argv[s._ind] = 1 < length (arg) ? arg[-1] : arg[0];
      s._col = baselen + strlen (s.argv[s._ind]) + 1;
      parse_args (s);

      parse_argtype (s, arg[0], type[ar[0]], baselen;;__qualifiers ());
      return 0;
      }

    ifnot (any (keys->rmap.backspace == chr))
      {
      variable b = "";
      firstindices (&b, args[ar], arg);
      if (strlen (b))
        arg = b;
      }

    s._col = baselen + strlen (arg) + 1;
    s.argv[s._ind] = arg;
    parse_args (s);
    prompt (s, s._lin, s._col);

    ar = array_map (String_Type, &sprintf, "%-17s %s", args[ar], desc[ar]);

    tmp = "";
    chr = hlitem (s, ar, arg, s._col, &tmp;dont_format);

    if (033 == chr)
      {
      restore (s.cmp_lnrs, NULL, NULL, s._columns);
      prompt (s, s._lin, s._col);

      return 0;
      }

    if (' ' == chr)
      {
      ar = strchop (tmp, ' ', 0);
      arg = ar[0];
      s.argv[s._ind] = arg;
      s._col = baselen + strlen (arg) + 1;
      restore (s.cmp_lnrs, NULL, NULL, s._columns);
      parse_args (s);

      i = wherefirst (arg == args);

      parse_argtype (s, arg, type[i], baselen;;__qualifiers ());
      return 0;
      }

    if (any (keys->rmap.backspace == chr)
        && s._col > baselen + 1)
      {
      arg = substr (arg, 1, strlen (arg) - 1);
      s.argv[s._ind] = arg;
      s._col = baselen + strlen (arg) + 1;
      parse_args (s);
      prompt (s, s._lin, s._col);
      continue;
      }

    if (' ' == chr)
      {
      s.argv[s._ind] = arg;
      s._col = baselen + strlen (arg) + 1;
      parse_args (s);

      if (length (where (array_map (Char_Type, &string_match, args, arg)))
          && strlen (arg) > 1)
        return 0;

      prompt (s, s._lin, s._col);
      continue;
      }

    if ('\r' == chr || 0 == (' ' < chr <= '~'))
      return '\r' == chr;

    if ("." == arg && qualifier_exists ("base"))
      arg = char (chr);
    else
      {
      restore (s.cmp_lnrs, NULL, NULL, s._columns);
      arg += char (chr);
      }

    s.argv[s._ind] = arg;
    s._col = baselen + strlen (s.argv[s._ind]) + 1;

    parse_args (s);

    prompt (s, s._lin, s._col);
    }
}

static define argroutine (s)
{
  ifnot (s._ind)
    return 0;

  variable arg = strchop (s.argv[s._ind], '=', 0);

  if (1 < length (arg))
    return argcompletion (s;; struct {arg = arg[0], pat = strjoin (arg[[1:]]),
      @__qualifiers ()});
  else
    return argcompletion (s;;__qualifiers ());
}

private define historycompletion (s)
{
  ifnot (length (s.history))
    return 0;

  variable
    i,
    ar,
    col,
    len,
    chr,
    index = 0;

  forever
    {
    ar = strlen (s._lin)
      ? s.history[where (array_map (Char_Type, &string_match,
          s.history, strjoin (s.argv, historyseparator), 1))]
      : s.history;

    ifnot (length (ar))
      return 0;

    ifnot (index + 1)
      index = length (ar) - 1;

    if (length (ar) <= index)
      index = 0;

    len = 1;

    i = 0;
    while ((i + 1) * s._columns <= s._col)
      i++;

    col = s._col - (s._columns * i);

    () = printout (s, [strjoin (strtok (ar[index], historyseparator), " ")], col, &len;
      lines = s._lines - (strlen (s._lin) / s._columns));

    index++;

    prompt (s, s._lin, s._col);

    chr = getch (;disable_langchange);

    if (any (keys->rmap.histup == chr))
      continue;

    if (any (keys->rmap.histdown == chr))
      {
      index -= 2;
      continue;
      }

    if (any (keys->rmap.backspace == chr) && s._col > 1)
      {
      delete_at (s);
      parse_args (s);
      restore (s.cmp_lnrs, NULL, NULL, s._columns);
      prompt (s, s._lin, s._col);
      continue;
      }

    if (' ' == chr)
      {
      s.argv = strtok (ar[index-1], historyseparator);
      s._col = strlen (strjoin (s.argv, " ")) + 1;
      parse_args (s);
      restore (s.cmp_lnrs, NULL, NULL, s._columns);
      prompt (s, s._lin, s._col);
      return  0;
      }

    if ('\r' == chr)
      {
      s.argv = strtok (ar[index-1], historyseparator);
      return 1;
      }

    if (033 == chr)
      {
      restore (s.cmp_lnrs, NULL, NULL, s._columns);
      prompt (s, s._lin, s._col);
      return 0;
      }

    ifnot (' ' < chr <= '~')
      {
      restore (s.cmp_lnrs, NULL, NULL, s._columns);
      return 0;
      }

    insert_at (s;chr = chr);
    parse_args (s);
    prompt (s, s._lin, s._col);
    }
}

private define _holdcommand_ (s)
{
  holdedcommand = @s;
  set (s);
  prompt (s, s._lin, s._col);
}

static define getline ()
{
  variable s = @Rline_Type;

  s._pchar = qualifier ("pchar", "");;
  s._prow = PROMPTROW;
  s._pclr = qualifier ("clr", 0);
  s.on_lang = &_Null;
  s.on_lang_args = {};
  s._lines = LINES;
  s._columns = COLUMNS;
  s._row = s._prow;

  set (s;;__qualifiers ());

  if (strlen (s._lin))
    prompt (s, s._lin, s._col);
  else
    smg->atrcaddnstrdr (" ", 0, PROMPTROW, 0, PROMPTROW, 0, COLUMNS);

  forever
    {
    s._chr = getch (;on_lang = s.on_lang, on_lang_args = s.on_lang_args);

    if (033 == s._chr)
      {
      restore (s.cmp_lnrs, s.ptr, 1, s._columns);
      return "";
      }

    if ('\r' == s._chr)
      return strjoin (s.argv);

    routine (s;insert_ws);

    parse_args (s);

    prompt (s, s._lin, s._col);
    }
}

static define readline (s)
{
  variable retval;
  variable initdone = 0;

  ifnot (NULL == holdedcommand)
    {
    s = holdedcommand;
    holdedcommand = NULL;
    }

  prompt (s, s._lin, s._col);

  forever
    {
    s._chr = getch (;on_lang = s.on_lang, on_lang_args = s.on_lang_args);

    ifnot (initdone)
      {
      send_msg_dr (" ", 0, s._prow, s._col);
      initdone = 1;
      }

    if (any (keys->rmap.osappnew == s._chr))
      ifnot (NULL == s.osappnew)
        {
        s.osappnew ();
        continue;
        }

    if (any (keys->rmap.osapprec == s._chr))
      ifnot (NULL == s.osapprec)
        {
        s.osapprec ();
        continue;
        }

    if (any (keys->rmap.windmenu == s._chr))
      ifnot (NULL == s.wind_mang)
        {
        s.wind_mang ();
        continue;
        }

    if (033 == s._chr)
      {
      restore (s.cmp_lnrs, s.ptr, 1, s._columns);
      break;
      }

    if ('\r' == s._chr)
      {
      s.execline (;;__qualifiers ());
      return;
      }

    if (any (keys->rmap.lastcur == s._chr))
      {
      _holdcommand_ (s);
      continue;
      }

    if (any (keys->rmap.histup == s._chr))
      if (1 == historycompletion (s))
        {
        s.execline (;;__qualifiers ());
        return;
        }
      else
        continue;

    if (any (keys->rmap.lastcmp == s._chr))
      if (1 == lcmpcompletion (s))
        {
        s.execline (;;__qualifiers ());
        return;
        }
      else
        continue;

    ifnot (NULL == s.starthook)
      {
      retval = (@s.starthook) (s;;__qualifiers ());
      ifnot (retval)
        continue;

      if (retval == 1)
        {
        s.execline (;;__qualifiers ());
        return;
        }
      }

    if ('\t' == s._chr)
      {
      ifnot (NULL == s.tabhook)
        {
        retval = (@s.tabhook) (s;;__qualifiers ());
        ifnot (retval)
          continue;

        if (retval == 1)
          {
          s.execline (;;__qualifiers ());
          return;
          }
        }

      if (s._ind && length (s.argv))
        {
        if (strlen (s.argv[s._ind]) && '-' == s.argv[s._ind][0])
          {
          ifnot (argroutine (s))
            continue;
          else
            {
            s.execline (;;__qualifiers ());
            return;
            }
          }
        else
          {
          variable start = 0 == strlen (s.argv[s._ind]) ? " " : s.argv[s._ind];
          if (fnamecmp (s, start) == 1)
            {
            s.execline (;;__qualifiers ());
            return;
            }

          continue;
          }
        }
      else
        if (commandcmp (s, assoc_get_keys (s.argvlist)) == 1)
          {
          s.execline (;;__qualifiers ());
          return;
          }
        else
          continue;
      }

    routine (s);

    parse_args (s);

    prompt (s, s._lin, s._col);
    }
}
