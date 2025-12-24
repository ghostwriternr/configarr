{
  lib,
  pkgs,
  src ? null,
  ...
}:
pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
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

  pname = "configarr";

  pnpmDeps = pkgs.pnpm.fetchDeps {
    fetcherVersion = 1;
    hash = "sha256-9530fpvRS3yzfmNlmALAEXvWiOtJeouv0FzEjUv+JLs=";
    inherit (finalAttrs) pname version;
    src = finalAttrs.src;
  };

  # Use provided src (from flake's self) or fall back to fetching from GitHub
  src = if src != null then src else pkgs.fetchFromGitHub {
    owner = "raydak-labs";
    repo = "configarr";
    rev = "v${finalAttrs.version}";
    hash = "sha256-fgv6wiK5wh0jAczJWy3Iqs3OK81ckNr3bOZD32bTCQQ=";
  };

  version = if src != null then "dev" else "1.17.2";
})
