# modules/nix/flake-parts/_aspects/aspect-type.nix
################################################################################
# The type of the flake.aspects tree. A node is either an aspect (a submodule
# carrying per-class config, `includes`, and an internal `resolve`) or a
# namespace (a plain attrset of further nodes). The `aspects` fixpoint handed to
# each definition is the nested tree augmented with each namespace's `all`, so
# `includes = with aspects; [ ns.aspect ]` and `[ ns.all ]` both resolve.
################################################################################
lib:
let
  resolve = import ./resolve-aspect.nix lib;

  ignoredType = lib.types.mkOptionType {
    name = "ignored type";
    description = "ignored values";
    merge = _loc: _defs: null;
    check = _: true;
  };

  mkInternal =
    desc: type: fn:
    lib.mkOption {
      internal = true;
      visible = false;
      readOnly = true;
      description = desc;
      inherit type;
      apply = fn;
    };

  # Makes an aspect callable so `resolve` can invoke it; by default it returns
  # itself, so calling an aspect just yields its config.
  functorType = lib.types.mkOptionType {
    name = "aspectFunctor";
    description = "aspect functor function";
    check = lib.isFunction;
    merge =
      _loc: defs:
      let
        lastDef = lib.last defs;
      in
      {
        __functionArgs = lib.functionArgs lastDef.value;
        __functor =
          _: callerArgs:
          let
            result = lastDef.value callerArgs;
          in
          if builtins.isFunction result then result else _: result;
      };
  };

  isSubmoduleFn =
    m:
    let
      args = lib.functionArgs m;
    in
    args ? lib || args ? config || args ? options || args ? aspect;

  isProviderFn =
    f:
    let
      args = lib.functionArgs f;
      n = builtins.length (builtins.attrNames args);
    in
    (args ? class && n == 1)
    || (args ? aspect-chain && n == 1)
    || (args ? class && args ? aspect-chain && n == 2);

  directProviderFn =
    cnf: lib.types.addCheck (lib.types.functionTo (aspectSubmodule cnf)) isProviderFn;

  curriedProviderFn =
    cnf:
    lib.types.addCheck (lib.types.functionTo (providerType cnf)) (
      f:
      builtins.isFunction f
      || lib.isAttrs f && lib.subtractLists [ "__functor" "__functionArgs" ] (lib.attrNames f) == [ ]
    );

  providerFn = cnf: lib.types.either (directProviderFn cnf) (curriedProviderFn cnf);

  providerType = cnf: lib.types.either (providerFn cnf) (aspectSubmodule cnf);

  aspectSubmodule =
    cnf:
    lib.types.submodule (
      { name, config, ... }:
      {
        freeformType = lib.types.lazyAttrsOf lib.types.deferredModule;
        config._module.args.aspect = config;
        imports = [ (lib.mkAliasOptionModule [ "_" ] [ "provides" ]) ];

        options = {
          name = lib.mkOption {
            description = "Aspect name";
            default = name;
            type = lib.types.str;
          };

          description = lib.mkOption {
            description = "Aspect description";
            default = "Aspect ${name}";
            type = lib.types.str;
          };

          includes = lib.mkOption {
            description = "Providers to ask aspects from";
            type = lib.types.listOf (providerType cnf);
            default = [ ];
          };

          provides = lib.mkOption {
            description = "Providers of aspect for other aspects";
            default = { };
            type = lib.types.submodule (
              { config, ... }:
              {
                freeformType = lib.types.lazyAttrsOf (providerType cnf);
                config._module.args.aspects = config;
              }
            );
          };

          __functor = lib.mkOption {
            internal = true;
            visible = false;
            description = "Functor to default provider";
            type = functorType;
            default =
              let
                defaultFunctor = aspect: { class, aspect-chain }: if true then aspect else class aspect-chain;
              in
              cnf.defaultFunctor or defaultFunctor;
          };

          modules = mkInternal "resolved modules from this aspect" ignoredType (
            _: lib.mapAttrs (class: _: config.resolve { inherit class; }) config
          );

          resolve = mkInternal "function to resolve a module from this aspect" ignoredType (
            _:
            {
              class,
              aspect-chain ? [ ],
            }:
            resolve class aspect-chain (config {
              inherit class aspect-chain;
            })
          );
        };
      }
    );

  # A tree node is an aspect (a class/meta key, or a submodule function) or a
  # namespace: a plain attrset of further nodes. The recursion is what allows
  # arbitrarily deep namespacing.
  aspectKeys = [
    "darwin"
    "nixos"
    "homeManager"
    "includes"
    "provides"
    "name"
    "description"
  ];
  isAspectShaped = m: lib.any (key: lib.elem key aspectKeys) (lib.attrNames m);

  aspectTreeElem =
    cnf:
    lib.types.either (lib.types.addCheck (aspectSubmodule cnf) (
      m: if builtins.isFunction m then isSubmoduleFn m else isAspectShaped m
    )) (lib.types.either (providerFn cnf) (lib.types.lazyAttrsOf (aspectTreeElem cnf)));

  aspectsType =
    cnf:
    lib.types.submodule (
      { config, ... }:
      {
        freeformType = lib.types.lazyAttrsOf (aspectTreeElem cnf);
        config._module.args.aspects = (import ./aggregate-all.nix lib).augmentFixpoint config;
      }
    );

in
{
  inherit aspectsType aspectSubmodule providerType;
}
