{ inputs, ... }:
{
  flake.nixosModules.sops =
    { ... }:
    {
      # Import sops-nix NixOS module globally
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      # 1. Point to your default secrets file or repository root
      # (Relative to this nix file or path to repository root)
      sops.defaultSopsFile = ../../secrets/secrets.yaml;

      # 2. Key format and decryption key location on the host
      sops.defaultSopsFormat = "yaml";

      # If you're using host SSH keys converted to age:
      sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

      # Or if you're using an age key file:
      # sops.age.keyFile = "/home/earn/.config/sops/age/keys.txt";

      # Generates key from ssh host key if needed
      sops.age.generateKey = false;
    };
}
