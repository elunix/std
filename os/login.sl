static define getloginname ()
{
  variable name;
  variable prompt = "login: ";
  
  smg->atrcaddnstrdr (prompt, 0, MSGROW - 2, 0, MSGROW - 2, strlen (prompt), COLUMNS);

  () = fgets (&name, stdin);
  
  smg->atrcaddnstrdr (" ", 0, MSGROW - 2, 0, MSGROW - 2, strlen (prompt), COLUMNS);

  return strtrim_end (name);
}

static define login ()
{
  variable msg = "";

  USER = getloginname ();

  (UID, GID) = setpwuidgid (USER, &msg);
  
  if (NULL == UID || NULL == GID)
    {
    smg->reset ();
    
    input->at_exit ();

    tostderr (msg);

    exit (1);
    }

  GROUP = setgrname (GID, &msg);
   
  if (NULL == GROUP)
    {
    smg->reset ();
    
    input->at_exit ();

    tostderr (msg);

    exit (1);
    }
  
  variable passwd = getpasswd ();

  if (-1 == authenticate (USER, passwd))
    {
    smg->reset ();

    input->at_exit ();

    tostderr ("authentication error");

    exit (1);
    }

  variable home = "/home/" + USER;
  
  ifnot (access (home, F_OK))
    if (_isdirectory (home))
      HOME = home;
  
  return encryptpasswd (passwd);
}