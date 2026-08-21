{ username, inputs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    # Point to your single secrets file
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    # This automatically converts the host's SSH key to an age key for decryption
    #age.sshKeyPaths = null;

    # Root-owned key file location (managed by sops-nix)
    #age.keyFile = "/var/lib/sops-nix/key.txt";
    age.keyFile = "/home/${username}/.config/sops/age/keys.txt";

    # This prevents the system from failing to boot if secrets are missing
    # during initial installation
    gnupg.sshKeyPaths = [ ];
  };
}
