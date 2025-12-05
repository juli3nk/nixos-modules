{ pkgs, pkgs-unstable, ... }:

{
  home.packages = with pkgs; [
    # Development and Build Tools
    gnumake          # GNU Make build automation
    direnv           # Environment switcher for shell
    nodePackages.node2nix # Generate Nix expressions from NPM packages
    delta            # Viewer for git and diff output
    ast-grep         # Fast code searching and rewriting tool
    yq-go            # YAML processor
    diff-so-fancy    # Good-looking diffs filter for git
    tokei            # Count your code, quickly

    # Version Management
    asdf-vm          # Multi-language version manager

    # Networking tools
    ldns             # replacement of `dig`, it provide the command `drill`
    nmap             # A utility for network discovery and security auditing
    ipcalc           # it is a calculator for the IPv4/v6 addresses
    whois

    rclone
    glow             # markdown previewer in terminal
  ] ++ (with pkgs-unstable; [
    vscode
    code-cursor
  ]);
}
