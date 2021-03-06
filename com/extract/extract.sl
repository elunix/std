load.from ("file", "extract", NULL;err_handler = &__err_handler__);

private variable VERBOSE = 0;

private define _verbose_ ()
{
  verboseon ();
  VERBOSE = 1;
}

define main ()
{
  variable
    i,
    files,
    dir = NULL,
    strip = NULL,
    exit_code = 0,
    noverbose = NULL,
    c = cmdopt_new (&_usage);

  c.add ("to-dir", &dir;type = "string");
  c.add ("strip", &strip);
  c.add ("v|verbose", &_verbose_);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  if (i == __argc)
    {
    IO.tostderr (sprintf ("%s: additional argument is required", __argv[0]));
    exit_me (1);
    }

  files = __argv[[i:]];
  files = files[where (strncmp (files, "--", 2))];

  noverbose = NULL == noverbose ? "1" : "0";
 
  ifnot (NULL == dir)
    _for i (0, length (files) - 1)
      ifnot (path_is_absolute (files[i]))
        files[i] = getcwd () + files[i];

  dir = NULL == dir ? getcwd () : dir;

  exit_code = array_map (Integer_Type, &extract, files, VERBOSE, dir, strip);
 
  exit_me (any (exit_code));
}
