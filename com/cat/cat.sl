variable
  EXIT_CODE = 0;

verboseon ();

define main ()
{
  variable
    i,
    files,
    ar = String_Type[0],
    c = cmdopt_new (&_usage);
 
  c.add ("help", &_usage);
  c.add ("info", &info);
 
  i = c.process (__argv, 1);
 
  if (i == __argc)
    {
    tostderr (sprintf ("%s: it requires at least a filename", __argv[0]));
    exit_me (1);
    }

  files = __argv[[i:]];

  _for i (0, length (files) - 1)
    {
    if (-1 == access (files[i], F_OK))
      {
      tostderr (sprintf ("%s: No such file", files[i]));
      EXIT_CODE = 1;
      continue;
      }
 
    if (-1 == access (files[i], R_OK))
      {
      tostderr (sprintf ("%s: is not readable", files[i]));
      EXIT_CODE = 1;
      continue;
      }
 
    ar = [ar, readfile (files[i])];
    }

  if (length (ar))
    array_map (Void_Type, &tostdout, ar);

  exit_me (EXIT_CODE);
}
