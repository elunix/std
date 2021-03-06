public variable NEEDSWINDDRAW = 0;

define _scratch_ (ved)
{
  if (qualifier_exists ("draw") && qualifier ("draw") == 0)
    return;

  viewfile (SCRATCH_VED, "SCRATCH", [1, 0], 0);
  __vsetbuf (ved._abspath);
  ved.draw ();

  NEEDSWINDDRAW = 1;
}

define __scratch (argv)
{
  variable ved = @get_cur_buf ();

  _scratch_ (ved);

  NEEDSWINDDRAW = 0;
  __vdraw_wind ();
}
