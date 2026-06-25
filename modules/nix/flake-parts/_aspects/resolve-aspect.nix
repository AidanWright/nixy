# modules/nix/flake-parts/_aspects/resolve-aspect.nix
################################################################################
# Resolves one aspect into one module for a given class. The result imports the
# aspect's own config for that class plus every aspect in its `includes` list,
# resolved for the same class — this is how aspect composition expands.
################################################################################
lib:
let
  include =
    class: aspect-chain: provider:
    let
      provided = if lib.isFunction provider then provider { inherit aspect-chain class; } else provider;
    in
    # Included aspects come from the `aspects` fixpoint, which stamps each one's
    # `name` with its full dotted path; that path becomes the dedup key.
    inner class aspect-chain (provided.name or null) provided;

  # A stable key per (aspect, class) lets the module system dedupe an aspect
  # reached through several `includes` paths (a diamond: A includes B and C, and
  # B also includes C). The key is the aspect's full namespace path, so two
  # aspects that merely share a leaf name (e.g. options.base and minimal.base) do
  # not collide. Bare providers without a name keep the old (un-keyed) behaviour.
  inner =
    class: aspect-chain: name: provided:
    lib.optionalAttrs (name != null) { key = "flake-aspect:${class}:${name}"; }
    // {
      imports =
        let
          config = provided.${class} or { };
          includes = provided.includes or [ ];
        in
        lib.flatten [
          config
          (lib.map (include class (aspect-chain ++ [ provided ])) includes)
        ];
    };

  resolve =
    class: aspect-chain: name: aspect:
    let
      provided = if lib.isFunction aspect then aspect { inherit class aspect-chain; } else aspect;
    in
    inner class aspect-chain name provided;
in
resolve
