private define new (s, x, y)
{
  variable prefix = {};
  variable suffix = {};
  variable res = {};
  variable xl = length (x);
  variable yl = length (y);
  variable pi;
  variable si;
  variable lcs;

  if (xl == yl)
    ifnot (any (x != y))
      return array_map (String_Type, &sprintf, " %s", x);

  _for pi (0, xl - 1)
    if (x[pi] == y[pi])
      list_append (prefix, sprintf (" %s", x[pi]));
    else
      break;

  _for si (1, xl - 1)
    if (x[xl-si] == y[yl-si])
      list_insert (suffix, sprintf (" %s", x[xl-si]));
    else
      break;

  x = x[[pi:xl-si]];
  y = y[[pi:yl-si]];
  xl = xl-pi-si+1;
  yl = yl-pi-si+1;

  variable i, j;
  lcs = Integer_Type[xl + 1, yl + 1];

  _for i (1, xl)
    _for j (1, yl)
      if (x[i-1] == y[j-1])
        lcs[i, j] = lcs[i-1, j-1] + 1;
      else
        lcs[i, j] = max ([lcs[i, j-1], lcs[i-1, j]]);

  while (xl > 0 || yl > 0)
    {
    if (xl > 0 && yl > 0 && x[xl-1] == y[yl-1])
      {
      xl--;
      yl--;
      list_insert (res, sprintf (" %s", x[xl]));
      continue;
      }

    if (yl > 0 && (xl == 0 || lcs[xl, yl-1] >= lcs[xl-1, yl]))
      {
      yl--;
      list_insert (res, sprintf ("+%s", y[yl]));
      continue;
      }

    if (xl > 0 && (yl == 0 || lcs[xl, yl-1] < lcs[xl-1, yl]))
      {
      xl--;
      list_insert (res, sprintf ("-%s", x[xl]));
      }
    }

  res = list_to_array (res, String_Type);
  prefix = list_to_array (prefix, String_Type);
  suffix = list_to_array (suffix, String_Type);

%  variable pinds = Integer_Type[length (prefix)];
%  variable sinds = Integer_Type[length (suffix)];
%  variable rinds = Integer_Type[length (res)];
%  variable tok;
%   _for i (0, length (res) - 1)
%     rinds[i] = (tok = res[i][0], tok == '-' ? -1 : tok == '+' ? 1 : 0);
%
%  [pinds, rinds, sinds];
  [prefix, res, suffix];
}
