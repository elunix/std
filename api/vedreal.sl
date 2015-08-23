variable VED_CLINE = Assoc_Type[Ref_Type];

define addfname (fname)
{
  variable absfname;
  variable s;

  ifnot (path_is_absolute (fname))
    absfname = getcwd + fname;
  else
    absfname = fname;

  if (_isdirectory (fname))
    return;

  variable w = get_cur_wind ();

  ifnot (any (w.bufnames == absfname))
    {
    variable ft = get_ftype (fname);
    s = init_ftype (ft);
    variable func = __get_reference (sprintf ("%s_settype", ft));
    (@func) (s, fname, w.frame_rows[get_cur_frame ()], NULL);
    setbuf (s._absfname);

    write_prompt (" ", 0);

    s.draw ();

    w.frame_names[get_cur_frame ()] = s._absfname;
    }
  else
    {
    s = w.buffers[absfname];
 
    w.frame_names[get_cur_frame ()] = s._absfname;
    setbuf (s._absfname);

    write_prompt (" ", 0);
    s._i = s._ii;
    s.draw ();
    }
}

private define _edit_other ()
{
  ifnot (_NARGS)
    return;

  variable fname = ();

  addfname (fname);
}

private define _bdelete ()
{
  variable bufname;
  variable s = get_cur_buf ();

  ifnot (_NARGS)
    bufname = s._absfname;
  else
    bufname = ();

  bufdelete (s, bufname, 0);
}

VED_CLINE["e"] = &_edit_other;
VED_CLINE["b"] = &_edit_other;
VED_CLINE["bd"] = &_bdelete;

private define my_commands ()
{
  variable i;
  variable a = (@__get_reference ("init_commands")) (;ex);
  variable keys = assoc_get_keys (VED_CLINE);

  _for i (0, length (keys) - 1)
    {
    a[keys[i]] = @Argvlist_Type;
    a[keys[i]].func = VED_CLINE[keys[i]];
    a[keys[i]].type = "Func_Type";
    }

  return a;
}

private define tabhook (s)
{
  ifnot (any (s.argv[0] == ["b", "bd"]))
    return -1;
 
  variable v = qualifier ("ved");
  variable w = get_cur_wind ();
  variable bufnames = w.bufnames[wherenot (v._absfname == w.bufnames)];
  variable args = array_map (String_Type, &sprintf, "%s void ", bufnames);
  return rline->argroutine (s;args = args, accept_ws);
}

define rlineinit ()
{
  variable rl;

   rl = rline->init (&my_commands;;struct {
      histfile = HISTDIR + "/" + string (getuid ()) + "vedhistory",
      historyaddforce = 1,
      tabhook = &tabhook,
      %totype = "Func_Type",
      @__qualifiers
      }
      );

  (@__get_reference ("iarg")) = length (rl.history);

  return rl;
}

define __write_buffers ()
{
  variable
    w = get_cur_wind (),
    bts,
    s,
    i,
    fn,
    abort = 0,
    hasnewmsg = 0,
    chr;

  _for i (0, length (w.bufnames) - 1)
    {
    fn = w.bufnames[i];
    s = w.buffers[fn];

    if (s._flags & VED_RDONLY)
      ifnot (qualifier_exists ("force_rdonly"))
        continue;
      else
        if (-1 == access (fn, W_OK))
          {
          tostderr (fn + " is not writable by you " + USER);
          hasnewmsg = 1;
          continue;
          }

    ifnot (s._flags & VED_MODIFIED)
      continue;
   
    ifnot (qualifier_exists ("force"))
      {   
      send_msg_dr (sprintf ("%s: save changes? y[es]/n[o]/c[cansel]", fn), 0, NULL, NULL);

      while (chr = getch (), 0 == any (chr == ['y', 'n', 'c']));
 
      if ('n' == chr)
        continue;

      if ('c' == chr)
        {
        tostderr ("writting " + fn + " aborted\n");
        hasnewmsg = 1;
        abort = -1;
        continue;
        }
      }
    
    bts = 0;
    variable retval = __writetofile (s._fname, s.lines, s._indent, &bts);
    
    ifnot (0 == retval)
      {
      send_msg_dr (sprintf ("%s, q to continue, without canseling function call", errno_string (retval)),
        1, NULL, NULL);

      if ('q' == getch ())
        continue;
      else
        {
        tostderr (sprintf ("%s, q to continue, without canseling function call", errno_string (retval)));
        hasnewmsg = 1;
        abort = -1;
        }
      }
    }
  
  if (hasnewmsg)
    send_msg_dr ("you have new error messages", 1, NULL, NULL);

  return abort;
}

private define cl_quit ()
{
  variable retval = 0;
  variable rl = qualifier ("rl");

  rline->writehistory (rl.history, rl.histfile);

  if (qualifier_exists ("force") || "q!" != qualifier ("argv0"))
    retval = __write_buffers ();

  ifnot (retval)
    exit_me (0);
}

private define write_file ()
{
  variable
    s = qualifier ("ved"),
    overwrite = "w!" == qualifier ("argv0"),
    args = __pop_list (_NARGS),
    ptr = s.ptr;
 
  __writefile (s, overwrite, ptr, args);
}

private define _read ()
{
  variable s = qualifier ("ved");
  ifnot (_NARGS)
    return;

  variable file = ();
  if (-1 == access (file, F_OK|R_OK))
    return;

  variable st = stat_file (file);

  ifnot (istype (st.st_mode, "reg"))
    return;

  ifnot (st.st_size)
    return;

  variable ar = getlines (file, s._indent, st);
 
  variable lnr = v_lnr (s, '.');

  s.lines = [s.lines[[:lnr]], ar, s.lines[[lnr + 1:]]];
  s._len = length (s.lines) - 1;
  s.st_.st_size += st.st_size;

  set_modified (s);
  s._i = s._ii;
  s.draw ();
}

private define write_quit ()
{
  variable s = qualifier ("ved");
  variable args = __pop_list (_NARGS);
  % needs to write the current buffer and ask for the rest
  variable retval = __write_buffers ();
  ifnot (retval)
    exit_me (0);
}

private define _messages_ ()
{
  variable keep = get_cur_buf ();
  variable s = (@__get_reference ("ERR_VED"));
  VED_ISONLYPAGER = 1;
  setbuf (s._absfname);
 
  topline (" -- pager -- ( MESSAGES BUF) --";row = s.ptr[0], col = s.ptr[1]);
 
  variable st = fstat (s._fd);
 
  if (s.st_.st_size)
    if (st.st_atime == s.st_.st_atime && st.st_size == s.st_.st_size)
      {
      s._i = s._ii;
      s.draw ();
      return;
      }

  s.st_ = st;
 
  s.lines = getlines (s._absfname, s._indent, st);

  s._len = length (s.lines) - 1;
 
  variable len = length (s.rows) - 1;

  (s.ptr[1] = 0, s.ptr[0] = s._len + 1 <= len ? s._len + 1 : s.rows[-2]);
 
  s._i = s._len + 1 <= len ? 0 : s._len + 1 - len;

  s.draw ();

  s.vedloop ();

  VED_ISONLYPAGER = 0;

  setbuf (keep._absfname);
 
  draw_wind ();
}

define _exit_ ()
{
  cl_quit (;;__qualifiers  ());
}

VED_CLINE["w"] = &write_file;
VED_CLINE["W"] = &write_file;
VED_CLINE["w!"] = &write_file;
VED_CLINE["q"] = &cl_quit;
VED_CLINE["Q"] = &cl_quit;
VED_CLINE["q!"] = &cl_quit;
VED_CLINE["wq"] = &write_quit;
VED_CLINE["Wq"] = &write_quit;
VED_CLINE["r"] = &_read;
VED_CLINE["messages"] = &_messages_;

private define doquit ()
{
  send_msg (" ", 0);
  exit_me (0);
}

private define _ved (t)
{
  return getreffrom ("ftypes/" + t, "ved", NULL, &on_eval_err;fun = t + "_ved"); 
}

define init_ftype (ftype)
{
  ifnot (FTYPES[ftype])
    FTYPES[ftype] = 1;
 
  variable type = @Ftype_Type;
 
  loadfrom ("ftypes/" + ftype, ftype + "_functions", NULL, &on_eval_err);

  type._type = ftype;
  type.ved = _ved (ftype);

  return type;
}
