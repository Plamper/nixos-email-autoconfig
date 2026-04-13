{
  description = "NixOS module for email autoconfiguration (Thunderbird, Outlook, Apple Mail)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }: {
    nixosModules.email-autoconfig = import ./email-autoconfig.nix;

    nixosModules.default = self.nixosModules.email-autoconfig;
  };
}
