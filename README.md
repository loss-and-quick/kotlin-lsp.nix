# kotlin-lsp.nix

Nix packaging and flake for the official [JetBrains Kotlin Language Server (`kotlin-lsp`)](https://github.com/Kotlin/kotlin-lsp) with automated CI/CD updates.

## Features

- **Multiplatform support**: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`.
- **Pure & self-contained**: Dynamically patched for NixOS with `autoPatchelfHook` (bundled JetBrains Runtime and JNI libs included).
- **Auto-updating CI/CD**: Daily GitHub Actions check against upstream Kotlin/kotlin-lsp releases with automatic hash verification and tagging.

## Quick Start

### Run directly with Nix

```bash
nix run github:loss-and-quick/kotlin-lsp.nix -- --stdio
```

### Add to Flake Inputs

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    kotlin-lsp = {
      url = "github:loss-and-quick/kotlin-lsp.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, kotlin-lsp, ... }: {
    # In NixOS / Home Manager configuration:
    # environment.systemPackages = [ kotlin-lsp.packages.${pkgs.stdenv.hostPlatform.system}.default ];
    # Or use the overlay:
    # nixpkgs.overlays = [ kotlin-lsp.overlays.default ];
  };
}
```

### Editor Configuration Example

#### Neovim (`nvim-lspconfig`)

```lua
local lspconfig = require('lspconfig')
local configs = require('lspconfig.configs')

if not configs.kotlin_lsp then
  configs.kotlin_lsp = {
    default_config = {
      cmd = { 'kotlin-lsp', '--stdio' },
      filetypes = { 'kotlin' },
      root_dir = lspconfig.util.root_pattern('settings.gradle', 'settings.gradle.kts', 'build.gradle', 'build.gradle.kts', 'pom.xml', '.git'),
    },
  }
end

lspconfig.kotlin_lsp.setup({})
```

#### Helix (`languages.toml`)

```toml
[[language]]
name = "kotlin"
language-servers = [ "kotlin-lsp" ]

[language-server.kotlin-lsp]
command = "kotlin-lsp"
args = [ "--stdio" ]
```

## License

This packaging is licensed under the [Apache-2.0 License](LICENSE).
The bundled Kotlin Language Server is provided by JetBrains s.r.o.
