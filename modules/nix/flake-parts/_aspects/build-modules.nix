# modules/nix/flake-parts/_aspects/build-modules.nix
################################################################################
# Builds flake.modules.<class> from the aspect tree. flake-parts' flake.modules
# is fixed at two levels (class -> name -> module), so namespaces are encoded in
# the dotted name key: flake.aspects.overlays.master -> modules.<class>."overlays.master".
# Every namespace also gets a synthesized "<namespace>.all" that imports every
# aspect beneath it. The root has no "all".
################################################################################
lib: tree:
let
  helpers = import ./aggregate-all.nix lib;
  inherit (helpers)
    isAspectNode
    childrenOf
    descendantAspects
    namespaceHasClass
    allModuleFor
    assertNoReserved
    reservedName
    ;

  # Options an aspect node carries; anything left over is one of its classes.
  metaOptionNames = [
    "name"
    "description"
    "includes"
    "provides"
    "__functor"
    "modules"
    "resolve"
  ];
  classKeysOf = aspect: lib.subtractLists metaOptionNames (lib.attrNames (childrenOf aspect));

  allClasses = lib.unique (lib.concatMap classKeysOf (descendantAspects tree));

  joinPath = prefix: name: if prefix == "" then name else "${prefix}.${name}";

  # Flatten the tree to { "<dotted name>" = module; } for one class, adding an
  # "<namespace>.all" entry for every namespace encountered.
  flatModulesForClass =
    class:
    let
      collect =
        prefix: node:
        lib.concatLists (
          lib.mapAttrsToList (
            name: value:
            let
              path = joinPath prefix name;
            in
            if isAspectNode value then
              lib.optional (value ? ${class}) (
                lib.nameValuePair path (
                  value.resolve {
                    inherit class;
                    name = path;
                  }
                )
              )
            else
              collect path value
              ++ lib.optional (namespaceHasClass class value) (
                lib.nameValuePair "${path}.${reservedName}" (allModuleFor path class value)
              )
          ) (childrenOf node)
        );
    in
    lib.listToAttrs (collect "" tree);
in
assert assertNoReserved tree;
lib.genAttrs allClasses flatModulesForClass
