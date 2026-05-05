- cấu trúc thư mục chung của 1 dự án:

yocto-project/
├── sources/                         # Source/layer clone từ bên ngoài
│   ├── poky/                        # Clone từ Yocto Project
│   ├── meta-openembedded/           # Clone từ OpenEmbedded
│   ├── meta-arm/                    # Layer vendor/phụ thuộc
│   ├── meta-ti/                     # Ví dụ BSP layer của TI
│   ├── meta-st-stm32mp/             # Ví dụ BSP layer STM32MP
│   └── meta-raspberrypi/            # Ví dụ BSP Raspberry Pi
│
├── meta-mycompany/                  # Layer do dev/team tự kiểm soát
│   ├── conf/
│   │   ├── layer.conf
│   │   ├── machine/
│   │   │   └── myboard.conf         # Cấu hình board custom
│   │   └── distro/
│   │       └── mydistro.conf        # Cấu hình distro riêng nếu cần
│   │
│   ├── recipes-bsp/                 # Bootloader, firmware, ATF...
│   │   ├── u-boot/
│   │   │   ├── u-boot_%.bbappend
│   │   │   └── files/
│   │   │       ├── myboard_defconfig
│   │   │       └── u-boot-myboard.patch
│   │   └── trusted-firmware-a/
│   │       └── tf-a_%.bbappend
│   │
│   ├── recipes-kernel/
│   │   └── linux/
│   │       ├── linux-yocto_%.bbappend
│   │       └── files/
│   │           ├── myboard.dts
│   │           ├── myboard.cfg
│   │           └── kernel-myboard.patch
│   │
│   ├── recipes-core/
│   │   ├── images/
│   │   │   └── my-image.bb          # Image riêng của board
│   │   └── packagegroups/
│   │       └── packagegroup-myboard.bb
│   │
│   ├── recipes-apps/
│   │   └── myapp/
│   │       ├── myapp.bb
│   │       └── files/
│   │           └── myapp.service
│   │
│   ├── recipes-connectivity/         # WiFi, Bluetooth, CAN, network...
│   ├── recipes-support/              # Lib, tool phụ trợ
│   └── wic/
│       └── myboard.wks              # Layout phân vùng image
│
├── build-myboard/                   # Thư mục build, KHÔNG commit Git
│   ├── conf/
│   │   ├── local.conf               # Config build local
│   │   └── bblayers.conf            # Danh sách layer đang dùng
│   ├── tmp/                         # Output build rất lớn
│   ├── downloads/                   # Source tải về
│   └── sstate-cache/                # Cache build
│
├── scripts/                         # Script dev/team tự viết
│   ├── setup-env.sh
│   ├── build.sh
│   ├── flash-sd.sh
│   └── clean.sh
│
├── manifests/                       # File quản lý version layer
│   ├── kas.yml                      # Nếu dùng kas
│   └── repo.xml                     # Nếu dùng repo tool
│
├── docs/                            # Tài liệu dự án
│   ├── bringup.md
│   ├── flashing.md
│   ├── board-hardware.md
│   └── release-note.md
│
└── README.md