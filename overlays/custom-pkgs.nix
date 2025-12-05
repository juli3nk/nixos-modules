final: prev: {
  # Package custom
  mon-script = prev.writeShellScriptBin "mon-script" ''
    #!/usr/bin/env bash
    echo "Script personnalisé pour ${final.system}"
  '';

  # Wrapper pour un package existant
  firefox-custom = prev.firefox.override {
    extraPolicies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
    };
  };
}
