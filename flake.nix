{
  description = "helios nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
    ...
  }: let
    configuration = {
      pkgs,
      config,
      ...
    }: {
      #############################################################
      # CORE (leave these on)
      #############################################################

      #  used the determinate installer, which manages nix itself.
      # leaving this false prevents nix-darwin from fighting it.
      nix.enable = false;
      nixpkgs.config.allowUnfree = true;
      nixpkgs.config.allowUnsupported = true;

      # Required by Nix when using flakes. (Harmless with nix.enable=false;
      # remove if Determinate complains about duplicate settings.)
      nix.settings.experimental-features = "nix-command flakes";

      # Records the git commit of this flake into darwin-version output.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Do not change casually. Read: $ darwin-rebuild changelog
      system.stateVersion = 6;

      # Apple Silicon.
      nixpkgs.hostPlatform = "aarch64-darwin";
      system.primaryUser = "jftx";

      users.users.jftx = {
        name = "jftx";
        home = "/Users/jftx";
      };

      #############################################################
      # PACKAGES  (system-wide, from nixpkgs)
      # Search names: https://search.nixos.org/packages
      #############################################################
      environment.systemPackages = with pkgs; [
        vim
        git
        curl
        wget
        eza
        bat
        btop
        gh
        neovim
        alejandra
        fastfetch
        claude-code
      ];

      # Extra $PATH-visible env vars.
      # environment.variables = {
      #   EDITOR = "vim";
      # };

      # Extra shell aliases (applies to interactive shells nix-darwin manages).
      environment.shellAliases = {
        ll = "eza -la";
        gs = "git status";
        gp = "git push -u origin main";
        ndcfg = "cd ~/nix-darwin-config && code .";
        rb = "sudo darwin-rebuild switch --flake ~/nix-darwin-config";
        trb = "sudo darwin-rebuild build --flake ~/nix-darwin-config";
      };

      #############################################################
      # SHELLS
      #############################################################
      # Creates /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;
      # programs.bash.enable = true;
      # programs.fish.enable = true;

      #############################################################
      # FONTS
      #############################################################
      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        #   nerd-fonts.fira-code
      ];

      #############################################################
      # SECURITY / Touch ID for sudo
      # Needs a reboot the first time you enable it.
      #############################################################
      # security.pam.services.sudo_local.touchIdAuth = true;

      #############################################################
      # HOMEBREW  (for GUI apps / casks nix can't provide, and Mac App Store)
      # nix-darwin manages the Brewfile; brew itself must be installed already.
      # Requires system.primaryUser to be set (above).
      #############################################################
      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = false; # only update when you run `brew update`
          upgrade = false;
          cleanup = "none"; # remove anything not listed here
        };
        casks = [
          "zen"
          "raycast"
          "vesktop"
          "visual-studio-code"
        ];
      };

      #############################################################
      # NETWORKING
      #############################################################
      networking.hostName = "helios";
      networking.computerName = "helios";
      networking.knownNetworkServices = ["Wi-Fi"];
      # networking.dns = [ "1.1.1.1" "9.9.9.9" ];

      #############################################################
      # macOS SYSTEM DEFAULTS
      # These write the same prefs you'd set in System Settings / `defaults`.
      # Most require system.primaryUser set. Some need a logout or reboot.
      # Full list (181 options): mynixos.com/nix-darwin/options/system.defaults
      #############################################################

      # ── Dock ──────────────────────────────────────────────
      system.defaults.dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.5;
        orientation = "right";
        tilesize = 40;
        magnification = true;
        mru-spaces = false;
        show-recents = false;
        static-only = true;
        # persistent-apps = [];
      };

      # ── Finder ────────────────────────────────────────────
      # system.defaults.finder = {
      #   AppleShowAllExtensions = true;
      #   AppleShowAllFiles = true;       # show hidden files
      #   FXPreferredViewStyle = "Nlsv";  # "clmv" columns | "Nlsv" list | "icnv" icon | "glyv" gallery
      #   ShowPathbar = true;
      #   ShowStatusBar = true;
      #   _FXShowPosixPathInTitle = true;
      #   FXEnableExtensionChangeWarning = false;
      #   QuitMenuItem = true;
      # };

      # ── Global (NSGlobalDomain): keyboard, UI, text ───────
      # system.defaults.NSGlobalDomain = {
      #   AppleInterfaceStyle = "Dark";        # remove line for Light
      #   KeyRepeat = 2;                       # lower = faster
      #   InitialKeyRepeat = 15;               # lower = shorter delay
      #   ApplePressAndHoldEnabled = false;    # key repeat instead of accent popup
      #   NSAutomaticCapitalizationEnabled = false;
      #   NSAutomaticSpellingCorrectionEnabled = false;
      #   NSAutomaticDashSubstitutionEnabled = false;
      #   NSAutomaticQuoteSubstitutionEnabled = false;
      #   NSAutomaticPeriodSubstitutionEnabled = false;
      #   AppleShowAllExtensions = true;
      #   "com.apple.swipescrolldirection" = false;  # disable natural scroll
      #   "com.apple.sound.beep.feedback" = 0;
      # };

      # ── Trackpad ──────────────────────────────────────────
      # system.defaults.trackpad = {
      #   Clicking = true;                 # tap to click
      #   TrackpadThreeFingerDrag = true;
      #   TrackpadRightClick = true;
      # };

      # ── Screenshots ───────────────────────────────────────
      # system.defaults.screencapture = {
      #   location = "~/Pictures/screenshots";
      #   type = "png";
      #   disable-shadow = true;
      # };

      # ── Login window ──────────────────────────────────────
      # system.defaults.loginwindow = {
      #   GuestEnabled = false;
      #   LoginwindowText = "helios";
      #   SHOWFULLNAME = false;
      # };

      # ── Software Update ───────────────────────────────────
      # system.defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;

      # ── Menu bar clock ────────────────────────────────────
      # system.defaults.menuExtraClock.Show24Hour = true;

      # ── Spaces ────────────────────────────────────────────
      # system.defaults.spaces.spans-displays = false;

      # ── Escape hatch: ANY preference not exposed above ────
      # Write raw defaults domains directly:
      # system.defaults.CustomUserPreferences = {
      #   "com.apple.desktopservices" = {
      #     DSDontWriteNetworkStores = true;
      #     DSDontWriteUSBStores = true;
      #   };
      # };

      #############################################################
      # KEYBOARD remapping (system level)
      #############################################################
      # system.keyboard = {
      #   enableKeyMapping = true;
      #   remapCapsLockToEscape = true;
      # };

      #############################################################
      # POWER
      #############################################################
      # power.sleep.computer = "never";   # be careful on a laptop
      # power.sleep.display = 15;

      #############################################################
      # LINUX BUILDER (run a NixOS VM to build Linux binaries locally)
      #############################################################
      # nix.linux-builder.enable = true;
    };
  in {
    darwinConfigurations."helios" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration

        inputs.home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.jftx = import ./home.nix;
        }
      ];
    };
  };
}
