private define _tabcallback (rl)
{
}

private define _assign_ (line)
{
  variable retval = NULL, _v_ = strchop (line, '=', 0);

  if (1 == length (_v_))
    return retval;

  _v_ = _v_[0];

  try
    {
    eval (line);
    send_msg (string (eval (string (_v_))), 0); % split and return the var?
    retval = 1;
    }
  catch AnyError:
    send_msg (__get_exception_info.message, 0);

  return retval;
}

private define _evalstr_ (line)
{
  variable res, retval = NULL;

  try
    {
    ifnot ('=' == line[0])
      res = string (eval (line));
    else
      return NULL;

    retval = res;
    }
  catch AnyError:
    res = __get_exception_info.message;

  if (qualifier_exists ("send_msg"))
    send_msg (res, 0);

  return retval;
}

define __eval ()
{
  variable rl = rline->init (NULL;pchar = ">");
  rline->set (rl);

  variable histfile = sprintf ("%s/%devalhistory", Dir->Vget ("HISTDIR"), getuid ());
  variable history = String_Type[0];
  variable tabcb = qualifier ("tabhook", &_tabcallback);

  ifnot (access (histfile, F_OK|R_OK))
    history = IO.readfile (histfile);

  send_msg ("Type an expression" , 0);

  rl.argv = [""];

  variable
    res = NULL,
    index = -1;

  forever
    {
    rl._lin = ">" + rl.argv[0];
    rline->prompt (rl, rl._lin, rl._col);
    rl._chr = getch ();

    if ('\t' == rl._chr)
      {
      (@tabcb) (rl);
      continue;
      }

    if (keys->CTRL_r == rl._chr)
      {
      variable chr = getch ();

      if ('%' == chr)
        {
        variable absfn = get_cur_buf ()._abspath;
        rl.argv[0] = substr (rl.argv[0], 1, rl._col - 1) + absfn +
                     substr (rl.argv[0], rl._col, -1);
        }

      if (keys->CTRL_w == chr)
        {
        variable buf = get_cur_buf ();
        variable line = __vline (buf, '.');
        variable col = buf._index;
        variable start, end;
        variable word = __vfind_word (buf, line, col, &start, &end);
        rl.argv[0] = substr (rl.argv[0], 1, rl._col - 1) + word +
                     substr (rl.argv[0], rl._col, -1);
        }

      if ('/' == chr)
        {
        if (assoc_key_exists (REG, "/"))
          if (1 == length (strtok (REG["/"])))
            rl.argv[0] = substr (rl.argv[0], 1, rl._col - 1) + REG["/"] +
                         substr (rl.argv[0], rl._col, -1);
        }

      continue;
      }

    if (any (keys->rmap.histup == rl._chr))
      {
      ifnot (length (history))
        continue;

      index++;
      if (index >= length (history))
        index = 0;

      rl.argv[0] = history[index];
      rl._col = strlen (rl.argv[0]) + 1;
      () = _evalstr_ (rl.argv[0];send_msg);
      continue;
      }

    if (any (keys->rmap.histdown == rl._chr))
      {
      ifnot (length (history))
        continue;

      index--;
      if (index < 0)
        index = length (history) - 1;
      rl.argv[0] = history[index];
      rl._col = strlen (rl.argv[0]) + 1;
      () = _evalstr_ (rl.argv[0];send_msg);
      continue;
      }

    if (rl._chr == 033)
      break;

    if ('\r' == rl._chr)
      {
      if ('=' == rl.argv[0][0])
        res = _assign_ (substr (rl.argv[0], 2, -1));
      else
        res = _evalstr_ (rl.argv[0];send_msg);

      ifnot (NULL == res)
        history = [rl.argv[0], history];

      if (qualifier_exists ("return_str"))
        break;

      rl.argv[0] = "";
      rl._col = 1;
      continue;
      }

    rline->routine (rl;insert_ws);

    ifnot (strlen (rl.argv[0]))
      continue;

    () = _evalstr_ (rl.argv[0];send_msg);
    }

  if (length (history))
    () = String.write (histfile, strjoin (history, "\n"));

  send_msg (" ", 0);

  if (qualifier_exists ("return_str"))
    return res;
}

define my_eval ()
{
  __eval (;;__qualifiers ());
}

