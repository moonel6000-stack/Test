# GlitchPulse — iOS 17.2.1 / Dopamine rootless

GlitchPulse is a Theos source project for an iPhone 15 Pro running iOS 17.2.1 with a rootless jailbreak.

## Included in this source package

- A SpringBoard-injected temporary overlay with randomized magenta/cyan/purple/green scanline fragments.
- Randomized placement, width, height, opacity and flicker visibility.
- A low-probability, low-alpha color bloom.
- A Darwin-notification interface intended for a Control Center toggle.
- GitHub Actions workflow that attempts to compile a rootless `.deb`.

## Important truth about the effect

This implementation is a **visual overlay simulation**. It does not capture or post-process the actual framebuffer, so it cannot physically shift every pixel of the underlying interface. True whole-screen chromatic aberration/distortion requires more invasive, version-specific rendering hooks that must be researched and tested on the exact OS build.

The overlay is transparent and non-interactive, and it does not alter persistent display settings. Turning the toggle off removes the overlay; restarting SpringBoard also starts with the effect off.

## Control Center tile

The SpringBoard side listens for Darwin notification `com.glitchpulse.toggle` and reads state 1 (on) or 0 (off). A Control Center module should set the state and post the notification. The module registration is not shipped as a compiled bundle because the exact ControlCenterUIKit/CCSupport headers and module template need to match your build environment. See `control/README.md`.

On iOS 17.2.1, use Theos NIC template `iphone/control_center_module-11up`, then register it through CCSupport. Official references:
- Theos NIC: https://theos.dev/docs/nic
- CCSupport: https://github.com/opa334/CCSupport
- Example custom CC module: https://github.com/Muirey03/PowerModule

## Build

1. Upload these files to a GitHub repository.
2. Enable GitHub Actions.
3. Run **Build GlitchPulse**.
4. Download `GlitchPulse-deb` from the workflow artifact if the build succeeds.
5. Review logs and test on-device; a successful build does not prove runtime compatibility.

## Safety and recovery

The effect is temporary and does not change persistent display settings. If it misbehaves, disable or remove the package using your jailbreak package manager and respring. Flashing is deliberately low-alpha and infrequent.
