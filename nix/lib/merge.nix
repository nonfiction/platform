{lib, ...}: let
  inherit (builtins) head length;
  inherit (lib) isAttrs isList last zipAttrsWith;

  # Custom merge function that concatenates lists
  merge = lhs: rhs:
    zipAttrsWith (
      _name: values:
        if length values == 1
        then head values
        else if isList (head values) && isList (last values)
        then (head values) ++ (last values)
        else if isAttrs (head values) && isAttrs (last values)
        then merge (head values) (last values)
        else last values
    ) [lhs rhs];
in
  merge
