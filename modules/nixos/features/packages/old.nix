  # Base system packages
  environment.systemPackages = with pkgs; [
    # System Information and Release
    lsb-release      # Linux Standard Base release information

    # Hardware Information
    pciutils         # PCI bus and device utilities (lspci)
    usbutils         # USB device utilities (lsusb)
    hdparm           # Hard disk drive parameters and performance tuning
    dmidecode        # DMI/SMBIOS table decoder for hardware information
    ethtool          # Ethernet device configuration and statistics
    nvme-cli         # NVMe storage management and monitoring tools
    lshw             # Hardware information listing tool
    smartmontools    # SMART disk health monitoring and self-test utilities

    # Partitioning & Filesystem
    parted           # Disk partition manipulation tool
    gptfdisk         # GPT disk partitioning tools (gdisk, sgdisk, cgdisk)
    lvm2             # Logical Volume Manager for flexible disk management
    ntfs3g           # NTFS filesystem driver with read/write support
    exfat            # exFAT filesystem driver
    dosfstools       # DOS filesystem utilities for FAT (mkfs.fat, fsck.fat)
    e2fsprogs        # ext2/ext3/ext4 filesystem utilities (mkfs, fsck, tune2fs)
    btrfs-progs      # Btrfs filesystem utilities (mkfs, fsck, subvolume management)
    xfsprogs         # XFS filesystem utilities (mkfs, fsck, xfs_admin)
    f2fs-tools       # F2FS (Flash-Friendly File System) utilities

    # Shell and Completion
    bash             # Bourne Again SHell
    bash-completion  # Programmable completion for bash

    # System Utilities
    bc               # Arbitrary precision calculator language
    proot            # User-space chroot implementation for unprivileged containers
    which            # Locate command executable in PATH
    tldr             # Simplified and community-driven command documentation
    tealdeer         # Fast tldr client implementation written in Rust
    tmux             # Terminal multiplexer for managing multiple sessions
    moreutils        # Collection of additional Unix utilities (sponge, vidir, etc.)
    hyperfine        # Command-line benchmarking tool for performance measurement
    rsync            # Fast and versatile file copying and synchronization tool
    less             # Terminal pager for viewing file contents
    man              # Manual page viewer and documentation system
    watch            # Execute a program periodically and display output
    parallel         # GNU parallel for parallel execution of jobs
    patch            # Apply patch files to source code
    time             # Command execution time measurement utility

    # File System Utilities
    fd               # Fast and user-friendly alternative to find
    tree             # Recursive directory tree visualization
    file             # File type identification using magic numbers
    pv               # Pipe viewer for monitoring data progress through pipes
    duf              # Disk usage utility with better formatting than df
    ncdu             # Interactive disk usage analyzer with ncurses interface
    bat              # Cat clone with syntax highlighting and Git integration

    # System Monitoring
    procps           # Process and system utilities (ps, top, free, vmstat)
    btop             # Modern resource monitor with GPU and network stats
    htop             # Interactive process viewer and system monitor
    sysstat          # System performance monitoring tools (sar, iostat, mpstat)
    iotop            # I/O usage monitor showing per-process disk I/O
    lm_sensors       # Hardware monitoring tools for temperature, voltage, fans
    procs            # Modern process viewer replacement for ps (written in Rust)
    glances          # Cross-platform system monitoring tool with web interface

    # System Tracing and Debugging
    strace           # System call tracer for debugging and monitoring
    ltrace           # Library call tracer for dynamic library functions
    bpftrace         # High-level tracing language for Linux eBPF
    lsof             # List open files and network connections by process

    # Networking Tools
    iproute2         # Modern network configuration utilities (ip, ss, tc)
    inetutils        # Network utilities (telnet, ftp, rsh, rlogin, etc.)
    mtr              # Network diagnostic tool combining traceroute and ping
    iperf3           # Network bandwidth measurement and testing tool
    socat            # Multipurpose relay and socket utility (netcat++ replacement)
    tcpdump          # Network packet analyzer and protocol analyzer
    gping            # Interactive ping tool with real-time graph visualization
    speedtest-cli    # Command-line interface for internet speed testing
    bmon             # Bandwidth utilization monitor with rate calculation
    iftop            # Interactive network bandwidth monitor showing per-connection traffic
    dnsutils         # DNS utilities (dig, nslookup, host)
    netcat           # Network utility for reading/writing network connections
    wavemon          # Real-time WiFi monitoring

    # Download Utilities
    curl             # Command-line tool for transferring data with URLs
    wget             # Non-interactive network downloader supporting HTTP/HTTPS/FTP
    aria2            # Lightweight multi-protocol and multi-source download utility

    # Text Processing and Search
    gnugrep          # GNU grep for pattern matching in text files
    gnused           # GNU sed for stream editing and text transformation
    gawk             # GNU awk for pattern scanning and data extraction
    ripgrep          # Fast recursive regex search tool (faster than grep)
    sad              # CLI search and replace tool with diff preview
    sd               # Intuitive find & replace CLI tool (modern sed alternative)
    most             # Terminal pager with improved features over more/less
    jq               # Lightweight and flexible command-line JSON processor

    # Archives and Compression
    gnutar           # GNU tar archiving utility for creating and extracting archives
    zip              # ZIP archive creation and compression tool
    xz               # XZ compression utilities (xz, unxz, xzcat)
    unzip            # Extract and list contents of ZIP archives
    p7zip            # 7-Zip file archiver supporting multiple formats
    zlib             # Compression library (used by many applications)
    lzip             # LZMA-based compression tool with error recovery
    zstd             # Zstandard fast compression algorithm and tool

    # Text Editors
    vim              # Vi IMproved text editor
    neovim           # Hyperextensible Vim-based text editor

    # Security and Cryptography
    pwgen            # Automatic password generation tool

    # Version Control
    git              # Distributed version control system
    gitAndTools.git-extras # Additional git utilities and commands
    git-lfs          # Git Large File Storage for versioning large files

    # Power
    # tlp              # Already included by services.tlp.enable
    # powertop         # Already included by powerManagement.powertop.enable

    # nix related
    # it provides the command `nom` works just like `nix
    # with more details log output
    nix-output-monitor
  ];