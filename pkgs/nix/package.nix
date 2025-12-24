{
  lib,
  pkgs,
  src ? null,
  ...
}:
let
  # Determine if we're building from local source or upstream
  useLocalSrc = src != null;
  localSrc = src;
  version = if useLocalSrc then "dev" else "1.17.2";

  upstreamSrc = pkgs.fetchFromGitHub {
    owner = "raydak-labs";
    repo = "configarr";
    rev = "v${version}";
    hash = "sha256-fgv6wiK5wh0jAczJWy3Iqs3OK81ckNr3bOZD32bTCQQ=";
  };

  finalSrc = if useLocalSrc then localSrc else upstreamSrc;
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "configarr";
  inherit version;
  src = finalSrc;

  buildPhase = ''
    runHook preBuild
    pnpm build
    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck
    pnpm test
    runHook postCheck
  '';

  CI = "true";

  installPhase = ''
    runHook preInstall
    install -Dm644 -t $out/share bundle.cjs
    makeWrapper ${lib.getExe pkgs.nodejs_24} $out/bin/configarr \
      --add-flags "$out/share/bundle.cjs"
    runHook postInstall
  '';

  meta = {
    description = "Sync TRaSH Guides + custom configs with Sonarr/Radarr";
    homepage = "https://github.com/raydak-labs/configarr";
    license = lib.licenses.agpl3Only;
    mainProgram = "configarr";
    maintainers = with lib.maintainers; [lord-valen];
    platforms = lib.platforms.all;
  };

  nativeBuildInputs = [
    pkgs.makeBinaryWrapper
    pkgs.nodejs_24
    pkgs.pnpm.configHook
  ];

  pnpmDeps = pkgs.pnpm.fetchDeps {
    pname = "configarr";
    inherit version;
    src = finalSrc;
    fetcherVersion = 1;
    hash = "sha256-9530fpvRS3yzfmNlmALAEXvWiOtJeouv0FzEjUv+JLs=";
  };
}
