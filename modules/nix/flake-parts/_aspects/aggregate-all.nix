# modules/nix/flake-parts/_aspects/aggregate-all.nix
################################################################################
# Synthesizes the per-namespace `all` aggregate and guards its reserved name.
# A namespace's `all` resolves to a module importing every aspect beneath it.
# build-modules.nix bakes `all` into the flake.modules output; aspect-type.nix
# injects it into the `aspects` fixpoint so `includes = [ ns.all ]` works too.
# Both derive `all` from the real descendant aspects, never from a nested `all`.
################################################################################
lib:
let
  reservedName = "all";

  isAspectNode = value: lib.isAttrs value && value ? resolve;

  # The module system adds `_module`; it is never an aspect or a namespace.
  childrenOf = node: removeAttrs node [ "_module" ];

  descendantAspects =
    node:
    lib.concatLists (
      lib.mapAttrsToList (
        _: value:
        if isAspectNode value then
          [ value ]
        else if lib.isAttrs value then
          descendantAspects value
        else
          [ ]
      ) (childrenOf node)
    );

  # Aspects beneath `node` that actually define `class` (skip e.g. nixos-only
  # aspects when building the darwin tree).
  descendantsOfClass = class: node: lib.filter (aspect: aspect ? ${class}) (descendantAspects node);
  namespaceHasClass = class: node: descendantsOfClass class node != [ ];

  allModuleFor = class: node: {
    imports = map (aspect: aspect.resolve { inherit class; }) (descendantsOfClass class node);
  };

  allProvider =
    node:
    {
      class,
      aspect-chain ? [ ],
    }:
    {
      ${class} = allModuleFor class node;
    };

  augmentFixpoint =
    tree:
    let
      go =
        isRoot: node:
        let
          rebuilt = lib.mapAttrs (_: value: if isAspectNode value then value else go false value) (
            childrenOf node
          );
        in
        if isRoot then rebuilt else rebuilt // { ${reservedName} = allProvider node; };
    in
    go true tree;

  assertNoReserved =
    tree:
    let
      offending =
        path: node:
        lib.concatLists (
          lib.mapAttrsToList (
            name: value:
            let
              here = path ++ [ name ];
            in
            lib.optional (name == reservedName) (lib.concatStringsSep "." here)
            ++ (if lib.isAttrs value && !isAspectNode value then offending here value else [ ])
          ) (childrenOf node)
        );
      bad = offending [ ] tree;
    in
    if bad == [ ] then
      true
    else
      throw "flake.aspects: '${reservedName}' is a reserved name (auto-synthesized per namespace); offending: ${lib.concatStringsSep ", " bad}";
in
{
  inherit
    reservedName
    isAspectNode
    childrenOf
    descendantAspects
    namespaceHasClass
    allModuleFor
    augmentFixpoint
    assertNoReserved
    ;
}
