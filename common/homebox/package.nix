{ lib
, buildGoModule
, fetchFromGitHub
, stdenvNoCC
, jq
, moreutils
, nodePackages
, stdenv
, esbuild
, cacert
}:
let
  pname = "homebox";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "sysadminsmedia";
    repo = "homebox";
    rev = "v${version}";
    hash = "sha256-Xbhk9zbtuYLxToiLcgZm0DPBma5KeLOH3Fi3va9oAAU=";
  };

  pnpm-deps = stdenvNoCC.mkDerivation {
    pname = "${pname}-pnpm-deps";
    src = "${src}/frontend";
    inherit version;

    nativeBuildInputs = [
      jq
      moreutils
      nodePackages.pnpm
      cacert
    ];

    installPhase = ''
      export HOME=$(mktemp -d)
      pnpm config set store-dir $out
      # use --ignore-script and --no-optional to avoid downloading binaries
      # use --frozen-lockfile to avoid checking git deps
      pnpm install --frozen-lockfile --no-optional --ignore-script

      # Remove timestamp and sort the json files
      rm -rf $out/v3/tmp
      for f in $(find $out -name "*.json"); do
        sed -i -E -e 's/"checkedAt":[0-9]+,//g' $f
        jq --sort-keys . $f | sponge $f
      done
    '';

    dontFixup = true;
    outputHashMode = "recursive";
    outputHash = "sha256-CZP3rGLTHgFErskllqV2KEt3qEIN17cA8P+XSWBps44=";
  };

  frontend = stdenv.mkDerivation {
    pname = "${pname}-frontend";
    src = "${src}/frontend";
    inherit version;

    nativeBuildInputs = [
      nodePackages.pnpm
    ];

    ESBUILD_BINARY_PATH = "${lib.getExe (esbuild.override {
      buildGoModule = args: buildGoModule (args // rec {
        version = "0.17.19";
        src = fetchFromGitHub {
          owner = "evanw";
          repo = "esbuild";
          rev = "v${version}";
          hash = "sha256-PLC7OJLSOiDq4OjvrdfCawZPfbfuZix4Waopzrj8qsU=";
        };
        vendorHash = "sha256-+BfxCyg0KkDQpHt/wycy/8CTG6YBA/VJvJFhhzUnSiQ=";
      });
    })}";

    preBuild = ''
      export HOME=$(mktemp -d)
      pnpm config set store-dir ${pnpm-deps}
      pnpm install --offline --frozen-lockfile --no-optional --ignore-script --shamefully-hoist

      chmod -R +w ./node_modules
      patchShebangs node_modules
      NUXT_TELEMETRY_DISABLED=1 pnpm build
    '';

    installPhase = ''
      runHook preInstall

      mv .output $out

      runHook postInstall
    '';
  };
in
buildGoModule {
  inherit pname version;
  src = "${src}/backend";

  vendorHash = "sha256-Ju4w7Q4xeh7zRLPfhjemEbt/6EOdnaBT3VtCnUCv+D0=";

  passthru = { inherit frontend; };

  preBuild = ''
    mkdir -p app/api/static
    cp -R ${frontend}/public app/api/static
  '';

  meta = with lib; {
    description = "A inventory and organization system built for the Home User";
    homepage = "https://homebox.sysadminsmedia.com";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ janik ];
    mainProgram = "api";
    platforms = platforms.all;
  };
}
