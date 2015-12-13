static define getloginname ()
{
  variable name = rline->getline (;pchar = "login:");

  return strtrim_end (name);
}

static define login ()
{
  variable msg, uid, gid, group, user;

  user = getloginname ();

  (uid, gid) = setpwuidgid (user, &msg);

  if (NULL == uid || NULL == gid)
    exit_me (1;msg = msg);

  group = setgrname (gid, &msg);

  if (NULL == group)
    exit_me (1;msg = msg);

  variable passwd = getpasswd ();

  if (-1 == authenticate (user, passwd))
    exit_me (1;msg = "authentication error");

  variable home = "/home/" + user;

  ifnot (access (home, F_OK))
    {
    ifnot (_isdirectory (home))
      exit_me (1;msg = home + " is not a directory");
    }
  else
    exit_me (1;msg = home + " is not a directory");

  __.vput ("Env", "user", user);
  __.vput ("Env", "uid", uid);
  __.vput ("Env", "gid", gid);
  __.vput ("Env", "group", group);
  __.vput ("Env", "home", home);

  return encryptpasswd (passwd);
}
