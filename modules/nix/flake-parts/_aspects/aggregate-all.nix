# modules/nix/flake-parts/_aspects/aggregate-all.nix
################################################################################
# Synthesizes the per-namespace `all` aggregate and guards its reserved name.
# A namespace's `all` resolves to a module importing every aspect beneath it.
# build-modules.nix bakes `all` into the flake.modules output; aspect-type.nix
# injects it into the `aspects` fixpoint so `includes = [ ns.all ]` works too.
# Both derive `all` from the real descendant aspects, never from a nested `all`.
# Every aspect is resolved under its full dotted path so dedup keys stay
# namespace-unique (leaves may repeat across namespaces).
################################################################################
lib:
let
  reservedName = "all";

  isAspectNode = value: lib.isAttrs value && value ? resolve;

  # The module system adds `_module`; it is never an aspect or a namespace.
  childrenOf = node: removeAttrs node [ "_module" ];

  joinPath = prefix: name: if prefix == "" then name else "${prefix}.${name}";

  # Every descendant aspect paired with its full dotted path.
  descendantAspectsWithPath =
    prefix: node:
    lib.concatLists (
      lib.mapAttrsToList (
        name: value:
        let
          path = joinPath prefix name;
        in
        if isAspectNode value then
          [
            {
              aspect = value;
              inherit path;
            }
          ]
        else if lib.isAttrs value then
          descendantAspectsWithPath path value
        else
          [ ]
      ) (childrenOf node)
    );

  descendantAspects = node: map (entry: entry.aspect) (descendantAspectsWithPath "" node);

  # Aspects beneath `node` that actually define `class` (skip e.g. nixos-only
  # aspects when building the darwin tree).
  descendantsOfClass = class: node: lib.filter (aspect: aspect ? ${class}) (descendantAspects node);
  namespaceHasClass = class: node: descendantsOfClass class node != [ ];

  # `<namespace>.all`: import every descendant aspect that defines `class`,
  # each resolved under its full path (`prefix.<leaf>`) so its dedup key is
  # namespace-unique.
  allModuleFor = prefix: class: node: {
    imports = lib.concatMap (
      { aspect, path }:
      lib.optional (aspect ? ${class}) (
        aspect.resolve {
          inherit class;
          name = path;
        }
      )
    ) (descendantAspectsWithPath prefix node);
  };

  # The fixpoint's `<namespace>.all` provider. It delegates to the already-built
  # `flake.modules.<class>."<prefix>.all"` (computed by build-modules via
  # `allModuleFor`), so `includes = [ ns.all ]` reuses the exact module the rest
  # of the system imports — instead of re-resolving inside the fixpoint, which
  # evaluates incorrectly in that self-referential context.
  allProvider =
    prefix: builtModules:
    {
      class,
      aspect-chain ? [ ],
    }:
    {
      # Named so `include` keys this `.all` wrapper uniquely; without a key the
      # module system dedupes several keyless `.all` wrappers in one `includes`
      # list down to the first, silently dropping the rest.
      name = joinPath prefix reservedName;
      ${class} = builtModules.${class}."${joinPath prefix reservedName}" or { };
    };

  # The `aspects` fixpoint handed to definitions: stamp each aspect with its
  # full-path `name` (so `includes` resolution keys it by namespace, not leaf)
  # and add each namespace's synthesized `all` (delegating to `builtModules`).
  # The root has no `all`.
  augmentFixpoint =
    builtModules: tree:
    let
      go =
        isRoot: prefix: node:
        let
          rebuilt = lib.mapAttrs (
            name: value:
            let
              path = joinPath prefix name;
            in
            if isAspectNode value then value // { name = path; } else go false path value
          ) (childrenOf node);
        in
        if isRoot then rebuilt else rebuilt // { ${reservedName} = allProvider prefix builtModules; };
    in
    go true "" tree;

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
    descendantsOfClass
    namespaceHasClass
    allModuleFor
    augmentFixpoint
    assertNoReserved
    ;
}
