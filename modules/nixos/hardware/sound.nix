# Sound configuration (PipeWire)
{ ... }:

{
  # Disable PulseAudio, it conflicts with pipewire too.
  services.pulseaudio.enable = false;

  # PipeWire (modern audio server)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    jack.enable = true;
  };

  # Realtime privileges for audio group
  security.rtkit.enable = true;
}
