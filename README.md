# Email Autoconfiguration Module for NixOS

A NixOS module that provides email client autoconfiguration for:

- **Thunderbird** (autoconfig)
- **Outlook** (autodiscover)
- **Apple Mail** (mobileconfig profiles for iOS/macOS)

Can be used as an addon for ![Simple Nixos Mailserver](https://gitlab.com/simple-nixos-mailserver/nixos-mailserver)

## Quick Start

Add this flake as an input to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    email-autoconfig = {
      url = "github:plamper/nixos-email-autoconfig";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, email-autoconfig }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        email-autoconfig.nixosModules.default
        {
          email-autoconfig = {
            enable = true;
            domain = "example.com";
            ...
          };
        }
      ];
    };
  };
}
```

# Alternatives

![automx2](https://github.com/rseichter/automx2) Supports more complex configuration but strictly follows spec and does not work with thunderbird mobile
