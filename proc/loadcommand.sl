variable com = __argv[1];

__set_argc_argv (__argv[[1:]]);

() = evalfile (path_dirname (__FILE__) + "/../load");

variable openstdout = 1;
variable COMDIR;
variable _exit_me_;
variable PPID = getenv ("PPID");
variable BG = getenv ("BG");
variable BGPIDFILE;
variable BGX = 0;
variable WRFIFO = Dir->Vget ("TEMPDIR") + "/" + string (PPID) + "_SRV_FIFO.fifo";
variable RDFIFO = Dir->Vget ("TEMPDIR") + "/" + string (PPID) + "_CLNT_FIFO.fifo";
variable RDFD = NULL;
variable WRFD = NULL;
variable stdoutfile = getenv ("stdoutfile");
variable stdoutflags = getenv ("stdoutflags");
variable stdoutfd;

define sigalrm_handler (sig)
{
  if (NULL == WRFD)
    WRFD = open (WRFIFO, O_WRONLY);

  () = write (WRFD, "exit");

  variable ref = __get_reference ("input->at_exit");
  ifnot (NULL == ref)
    (@ref);

  exit (BGX);
}

if (NULL == BG)
  {
  RDFD = open (RDFIFO, O_RDONLY);
  WRFD = open (WRFIFO, O_WRONLY);
  }

ifnot (NULL == BG)
  {
  BGPIDFILE = BG + "/" + string (Env->Vget ("PID")) + ".RUNNING";
  () = open (BGPIDFILE, O_CREAT|O_TRUNC, S_IRUSR|S_IWUSR);

  signal (SIGALRM, &sigalrm_handler);
  }

define at_exit ()
{
  variable msg = qualifier ("msg");

  ifnot (NULL == msg)
    if (String_Type == typeof (msg) ||
       (Array_Type == typeof (msg) && _typeof (msg) == String_Type))
      IO.tostderr (msg);
}

define exit_me_bg (x)
{
  at_exit (;;__qualifiers);

  () = rename (BGPIDFILE, substr (
    BGPIDFILE, 1, strlen (BGPIDFILE) - strlen (".RUNNING")) + ".WAIT");

  BGX = x;

  forever
    sleep (86400);
}

define exit_me (x)
{
  variable ref = __get_reference ("input->at_exit");
  (@ref);

  at_exit (;;__qualifiers);

  ifnot (NULL == BG)
    exit_me_bg (x);

  variable buf;

  () = write (WRFD, "exit");
  () = read (RDFD, &buf, 1024);

  exit (x);
}

_exit_me_ = NULL == BG ? &exit_me : &exit_me_bg;

private define tostdout ()
{
  loop (_NARGS) pop ();
}

IO->Fun ("tostdout?", &tostdout);

public define __err_handler__ (__r__)
{
  variable code = 1;
  if (Integer_Type == typeof (__r__))
    code = __r__;

  (@_exit_me_) (code;;__qualifiers);
}

ifnot (access (stdoutfile, F_OK))
  stdoutfd = open (stdoutfile, File->Vget ("FLAGS")[stdoutflags]);
else
  stdoutfd = open (stdoutfile, File->Vget ("FLAGS")[stdoutflags], File->Vget ("PERM")["__PUBLIC"]);

if (NULL == stdoutfd)
  (@_exit_me_) (1;msg = errno_string (errno));

load.from ("proc", "getdefenv", 1;err_handler = &__err_handler__);
load.from ("sock", "sock", 0;err_handler = &__err_handler__);
load.from ("input", "inputInit", NULL;err_handler = &__err_handler__);
load.from ("parse", "cmdopt", NULL;err_handler = &__err_handler__);

define verboseon ()
{
  IO->Fun ("tostdout?", NULL;FuncFname = "comtostdout");
}

define verboseoff ()
{
  IO->Fun ("tostdout?", NULL;FuncFname = "null_tostdout");
}

load.from ("api", "comapi", NULL;err_handler = &__err_handler__);

define initproc (p)
{
  p.stdout.file = stdoutfile;
  p.stdout.wr_flags = stdoutflags;
}

if (NULL == BG)
  sigprocmask (SIG_UNBLOCK, [SIGINT]);

define sigint_handler (sig)
{
  IO.tostderr ("process interrupted by the user");
  (@_exit_me_) (130);
}

if (NULL == BG)
  signal (SIGINT, &sigint_handler);

define sigint_handler_null ();
define sigint_handler_null (sig)
{
  signal (sig, &sigint_handler_null);
}

define close_smg ()
{
  Sock.send_str (WRFD, "close_smg");

  () = Sock.get_int (RDFD);
}

define restore_smg ()
{
  Sock.send_str (WRFD, "restore_smg");

  () = Sock.get_int (RDFD);
}

define send_msg_dr (msg)
{
  Sock.send_str (WRFD, "send_msg_dr");

  () = Sock.get_int (RDFD);

  Sock.send_str (WRFD, msg);

  () = Sock.get_int (RDFD);
}

define ask (questar, charar)
{
  if (NULL == BG)
    {
    signal (SIGINT, &sigint_handler_null);

    sigprocmask (SIG_BLOCK, [SIGINT]);
    }

  variable i = 0;
  variable hl_reg = qualifier ("hl_region");

  ifnot (NULL == hl_reg)
    if (Array_Type == typeof (hl_reg))
      if (Integer_Type == _typeof (hl_reg))
        {
        variable tmp = @hl_reg;
        hl_reg = Array_Type[1];
        hl_reg[0] = tmp;
        i = 1;
        }
      else
        if (Array_Type == _typeof (hl_reg))
          if (length (hl_reg))
            if (Integer_Type == _typeof (hl_reg[0]))
              i = length (hl_reg);

  Sock.send_str (WRFD, "ask");

  () = Sock.get_int (RDFD);

  Sock.send_str (WRFD, strjoin (questar, "\n"));

  () = Sock.get_int (RDFD);

  Sock.send_int (WRFD, i);

  if (i)
    {
    () = Sock.get_int (RDFD);

    _for i (0, i - 1)
      {
      Sock.send_int_ar (RDFD, WRFD, hl_reg[i]);
      () = Sock.get_int (RDFD);
      }
    }
  else
    () = Sock.get_int (RDFD);

  variable chr;

  if (qualifier_exists ("get_int"))
    {
    variable
      len,
      retval = "";

    send_msg_dr ("integer: ");

    chr = getch ();

    while ('\r' != chr)
      {
      if  ('0' <= chr <= '9')
        retval+= char (chr);

      if (any ([0x110, 0x8, 0x07F] == chr))
        retval = retval[[:-2]];

      send_msg_dr ("integer: " + retval);

      chr = getch ();
      }

    chr = retval;
    }
  else
    {
    send_msg_dr (strjoin (array_map (String_Type, &char, charar), "/") + " ");
    while (chr = getch (), 0 == any (chr == charar));
    }

  Sock.send_str (WRFD, "restorestate");

  () = Sock.get_int (RDFD);

  if (NULL == BG)
    {
    sigprocmask (SIG_UNBLOCK, [SIGINT]);

    signal (SIGINT, &sigint_handler);
    }

  send_msg_dr (" ");

  chr;
}

try
  load.from ("com/" + com, "comInit", NULL;err_handler = &__err_handler__);
catch AnyError:
  (@_exit_me_) (1;msg = Err.efmt (NULL));
