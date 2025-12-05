final: prev: {
  # Modify neovim
  neovim = prev.neovim.override {
    vimAlias = true;
    viAlias = true;
  };

  # Add plugins to a package
  vscode = prev.vscode-with-extensions.override {
    vscodeExtensions = with prev.vscode-extensions; [
      bbenoist.nix
      ms-python.python
    ];
  };
}
