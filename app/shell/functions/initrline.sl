define _shell_ (argv)
{
  shell_pre_header ("shell");
  runapp ([argv], NULL;;__qualifiers ());
  shell_post_header ();
  draw (get_cur_buf ());
}

private define _intro_ (argv)
{
  intro (get_cur_rline (), get_cur_buf ());
}

private define my_commands ()
{
  variable a = init_commands ();

  a["intro"] = @Argvlist_Type;
  a["intro"].func = &_intro_;

  a["shell"] = @Argvlist_Type;
  a["shell"].func = &_shell_;

  return a;
}

private define filtercommands (s, ar)
{
  ar = ar[where (1 < strlen (ar))];
  return ar;
}

private define filterargs (s, args, type, desc)
{
  return [args, "--sudo", "--pager"], [type, "void", "void"],
    [desc, "execute command as superuser", "viewoutput in a scratch buffer"];
}

private define tabhook (s)
{
  ifnot (s._ind)
    return -1;

  ifnot (s.argv[0] == "killbgjob")
    return -1;

  variable pids = assoc_get_keys (BGPIDS);

  ifnot (length (pids))
    return -1;

  variable i;
  _for i (0, length (pids) - 1)
    pids[i] = pids[i] + " void " + strjoin (BGPIDS[pids[i]].argv, " ");

  return rline->argroutine (s;args = pids, accept_ws);
}

define rlineinit ()
{
  variable rl = rline->init (&my_commands;;struct
    {
    @__qualifiers (),
    histfile = Dir->Vget ("HISTDIR") + "/" + string (getuid ()) + "shellhistory",
    filtercommands = &filtercommands,
    filterargs = &filterargs,
    tabhook = &tabhook,
    onnolength = &toplinedr,
    onnolengthargs = {""},
    on_lang = &toplinedr,
    on_lang_args = {" -- shell --"}
    });

  iarg = length (rl.history);

  return rl;
}
