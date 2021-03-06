private variable orig_dir = getcwd ();
private variable exists = 0x01;

private define add (self, s, rows)
{
  variable w = get_cur_wind ();

  if (any (s.fname == w.bufnames))
    return exists;

  variable ftype = get_ftype (s.fname);

  variable c;

  ifnot ("list" == ftype)
    {
    w.cur_frame = 0;
    c = init_ftype (ftype);

    load.from ("ftypes/" + ftype, ftype + "_settype", NULL;err_handler = &__err_handler__);
    variable func = __get_reference (sprintf ("%s_settype", ftype));
    (@func) (c, s.fname, rows, NULL);
 
    c._i = c._len >= s.lnr - 1 ? s.lnr - 1 : 0;
    c.ptr[0] = 1;
    c.ptr[1] = s.col - 1 + c._indent;
    c._index = c.ptr[1];
    __vsetbuf (c._abspath);
    return 0;
    }

  c = self;
 
  w.cur_frame = 1;
  variable lines = IO.readfile (s.fname);
  if (NULL == lines)
    lines = [sprintf ("%s\000", c._indent)];

  variable def = deftype ();
  def._autochdir = 0;
  __vinitbuf (c, s.fname, rows, lines, def);
 
  c._len = length (lines) - 1;
  c._i = c._len >= s.lnr - 1 ? s.lnr - 1 : 0;
  c.ptr[0] = qualifier ("row", 1);
  c.ptr[1] = qualifier ("col", s.col - 1);
  c._index = c.ptr[1];
 
  __vsetbuf (c._abspath);

  return 0;
}

private define getitem (s)
{
  variable
    line = __vline (s, '.'),
    tok = strchop (line, '|', 0),
    col = atoi (strtok (tok[1])[2]),
    lnr = atoi (strtok (tok[1])[0]),
    fname;

  ifnot (path_is_absolute (tok[0]))
    fname = path_concat (orig_dir, tok[0]);
  else
    fname = tok[0];

  if (-1 == access (fname, F_OK))
    {
    IO.tostderr (fname + ": No such filename");
    return NULL;
    }

  return struct {lnr = lnr, col = col, fname = fname};
}

public define __pg_on_carriage_return (s)
{
  ifnot (get_cur_frame ())
    return;

  variable l = getitem (s);

  if (NULL == l)
    return;
 
  if (".list" == path_extname (l.fname))
    return;
 
  variable w = get_cur_wind ();

  variable retval = add (NULL, l, w.frame_rows[0];force);

  if (exists == retval)
    {
    w.cur_frame = 0;
    s = get_buf (l.fname);
    __vsetbuf (s._abspath);
    s._i = s._len >= l.lnr - 1 ? l.lnr - 1 : 0;
    s.ptr[0] = 1;
    s.ptr[1] = l.col - 1 + s._indent;
    s._findex = s._indent;
    s._index = s.ptr[1];
    __vset_clr_fg (s, 1);
    }
  else
    s = get_cur_buf ();

  __vset_clr_bg (w.buffers[w.frame_names[1]], 1);

  s.draw ();
  s.vedloop ();
}

define list_set (s, mys)
{
  variable w = get_cur_wind ();
  () = add (s, mys, w.frame_rows[1];row = w.frame_rows[1][0], col = 0);
}
