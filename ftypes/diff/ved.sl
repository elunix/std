define diff_ved (s, fname)
{
  ifnot (SCRATCH == fname)
    diff_settype (s, fname, VED_ROWS, NULL);
 
  setbuf (s._absfname);
 
  write_prompt (" ", 0);

  s.draw ();

  preloop (s);
 
  toplinedr (" -- pager --");

  s.vedloop ();
}