static define apptable ()
{
  variable i;
  variable ii;
  variable app;
  variable dir;
  variable apps;
  variable dirs = [USRDIR, STDDIR, LCLDIR];

  _for i (0, length (dirs) - 1)
    {
    dir = dirs[i];
    apps = listdir (dir + "/app");
    if (NULL == apps || (NULL != apps && 0 == length (apps)))
      continue;

    apps = apps[where (array_map (Integer_Type, &_isdirectory,
      array_map (String_Type, &path_concat, dir + "/app/", apps)))];

    _for ii (0, length (apps) - 1)
      {
      app = apps[ii];
      if (-1 == access (dir + "/app/" + app + "/" + app + "Init.sl", F_OK)
        &&-1 == access (dir + "/" + app + "/" + app + "Init.slc", F_OK))
        continue;

      APPSINFO[app] = @AppInfo_Type;
      
      APPSINFO[app].init = app + "Init";
      
      ifnot (access (dir + "/app/" + app + "help.txt", F_OK))
        APPSINFO[app].help = dir + "/app/" + app + "/help.txt";

      ifnot (access (dir + "/app/" + app + "info.txt", F_OK))
        APPSINFO[app].info = dir + "/app/" + app + "/info.txt";

      APPS[app] = Assoc_Type[App_Type];
      }
    }
}

static define addflags (p, s)
{
  p.stderr.file = TEMPDIR + "/" + string (PID) + "Srv" + s._appname + "err";
  p.stderr.wr_flags = ">|";
}

static define init_app (name, dir, argv)
{
  variable s = @App_Type;

  s._state = 0;
  s._appdir = dir;
  s._procfile = dir + "/proc";;
  s._appname = name;
  s.argv = argv;
  s._sockaddr = TEMPDIR + "/" + string (PID) + name + ".sock";

  return s;
}

static define getargvenv (p, s, argv)
{
  argv = [SLSH_BIN, p.loadfile, s._procfile, argv];

  variable env = [proc->defenv (), sprintf ("SOCKADDR=%s", s._sockaddr)];

  ifnot (NULL == DISPLAY)
    env = [env, "DISPLAY=" + DISPLAY];

  ifnot (NULL == XAUTHORITY)
    env = [env, "XAUTHORITY=" + XAUTHORITY];

  return argv, env;
}

static define app_atexit (s)
{
  ifnot (s._state & IDLED)
    {
    variable status = waitpid (s.p_.pid, 0);

    s.p_.atexit ();

    () = close (s._fd);
    
    assoc_delete_key (APPS[s._appname], string (s.p_.pid));
    
    _log_ (s._appname +": exited", LOGERR);

    return 0;
    }
  
  _log_ (s._appname +": is in idled state", LOGERR);

  return 1;
}

static define apploop (s)
{
  variable retval;

  forever
    {
    retval = sock->get_int (s._fd);
 
    ifnot (Integer_Type == typeof (retval))
      {
      _log_ (s._appname + "loop: expected Integer_Type, received " + string (typeof (retval)), LOGERR);
      break;
      }

    if (retval == GO_ATEXIT)
      {
      s._state = s._state & ~CONNECTED;
      break;
      }

    if (retval == GO_IDLED)
      {
      ifnot (ALLOWIDLED)
        sock->send_int (s._fd, 0);
      else
        s._state = s._state | IDLED;

      break;
      }
    }
}

static define connect_to_child (s)
{
  s._fd = s.p_.connect (s._sockaddr);

  if (NULL == s._fd)
    {
    s.p_.atexit ();

    () = kill (s.p_.pid, SIGKILL);
    
    _log_ (s._appname +": failed to connect to socket", LOGERR);
    
    return;
    }
 
  s._state = s._state | CONNECTED;
  
  _log_ (s._appname + ": connected to socket", LOGNORM);

  APPS[s._appname][string (s.p_.pid)] = s;
  
  apploop (s);
}

static define doproc (s, argv)
{
  variable p, env;

  if (p = proc->init (0, 0, 1;;__qualifiers ()), p == NULL)
    return NULL;

  addflags (p, s);

 (argv, env) = getargvenv (p, s, argv);
  
  s.p_ = p;

  if (NULL == p.execve (argv, env, 1))
    return -1;

  return 0;
}