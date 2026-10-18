{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  testers,
  # Runtime dependencies for autoPatchelfHook on Linux
  alsa-lib,
  freetype,
  libx11,
  libxext,
  libxi,
  libxrender,
  libxtst,
  wayland,
  libxkbcommon,
  zlib,
}:

let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  inherit (stdenv.hostPlatform) system;
  source = sources.${system} or (throw "Unsupported platform for kotlin-lsp: ${system}");
in
stdenv.mkDerivation (finalAttrs: {
  pname = "kotlin-lsp";
  version = sources.version;

  src = fetchurl {
    inherit (source) url hash;
  };

  # Darwin sit files are zip archives
  sourceRoot = ".";

  nativeBuildInputs = [
    makeWrapper
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    alsa-lib
    freetype
    libx11
    libxext
    libxi
    libxrender
    libxtst
    wayland
    libxkbcommon
    zlib
    stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/kotlin-lsp $out/bin
    if [ -d "kotlin-server-${finalAttrs.version}" ]; then
      cp -r kotlin-server-${finalAttrs.version}/* $out/lib/kotlin-lsp/
    else
      cp -r * $out/lib/kotlin-lsp/
    fi

    makeWrapper $out/lib/kotlin-lsp/bin/intellij-server $out/bin/kotlin-lsp \
      --set-default JAVA_HOME "$out/lib/kotlin-lsp/jbr"

    ln -s $out/bin/kotlin-lsp $out/bin/kotlin-language-server

    runHook postInstall
  '';

  passthru = {
    updateScript = [ ./scripts/update.py ];
    tests = {
      version = testers.testVersion {
        package = finalAttrs.finalPackage;
        command = "kotlin-lsp --version";
        version = finalAttrs.version;
      };
    };
  };

  meta = {
    description = "Official Kotlin Language Server by JetBrains";
    longDescription = ''
      Official Kotlin support for Visual Studio Code and other editors implementing
      the Language Server Protocol (LSP). The server is based on IntelliJ IDEA
      and the IntelliJ IDEA Kotlin Plugin implementation.
    '';
    homepage = "https://github.com/Kotlin/kotlin-lsp";
    changelog = "https://github.com/Kotlin/kotlin-lsp/releases/tag/kotlin-lsp/v${finalAttrs.version}";
    license = lib.licenses.unfree;
    mainProgram = "kotlin-lsp";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    sourceProvenance = with lib.sourceTypes; [
      binaryBytecode
      binaryNativeCode
    ];
  };
})
