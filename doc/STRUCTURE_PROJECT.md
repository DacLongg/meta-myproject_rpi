- cấu trúc thư mục chung của 1 dự án:

+ yocto-project/                     
    + # Source/layer clone từ bên ngoài
    ├── poky/                        # Clone từ Yocto Project
    ├── meta-openembedded/           # Clone từ OpenEmbedded
    ├── meta-arm/                    # Layer vendor/phụ thuộc
    ├── meta-ti/                     # Ví dụ BSP layer của TI
    ├── meta-st-stm32mp/             # Ví dụ BSP layer STM32MP
    └── meta-raspberrypi/            # Ví dụ BSP Raspberry Pi
    + # Layer do dev/team tự kiểm soát
    ├── meta-mycompany/                  
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
    │   ├── scripts/                         # Script dev/team tự viết
    │   │   ├── setup-env.sh
    │   │   ├── build.sh
    │   │   ├── flash-sd.sh
    │   │   └── clean.sh
    │   ├── docs/                            # Tài liệu dự án
    │   │   ├── bringup.md
    │   │   ├── flashing.md
    │   │   ├── board-hardware.md
    │   │   └── release-note.md
    │   │
    │   ├── recipes-connectivity/         # WiFi, Bluetooth, CAN, network...
    │   ├── recipes-support/              # Lib, tool phụ trợ
    │   ├── wic/
    │   │   └── myboard.wks              # Layout phân vùng image
    │   ├── manifests/                       # File quản lý version layer
    │   │   ├── kas.yml                      # Nếu dùng kas
    │   │   └── repo.xml                     # Nếu dùng repo tool
    │   │
    │   └── README.md
    + # Thư mục build, gen ra từ oe-init-build-env
    ├── build-myboard/                   # Thư mục build, KHÔNG commit Git
    │   ├── conf/
    │   │   ├── local.conf               # Config build local
    │   │   └── bblayers.conf            # Danh sách layer đang dùng
    │   ├── tmp/                         # Output build rất lớn
    │   ├── downloads/                   # Source tải về
    │   └── sstate-cache/                # Cache build
    │


Muốn “hoàn toàn không phụ thuộc vào hãng”, cần nói thẳng một điểm trước:

Không có chuyện embedded Linux trên SoC mà 0% phụ thuộc vào vendor/community BSP. Anh luôn phải phụ thuộc ít nhất vào:

hỗ trợ SoC trong kernel
boot chain cho SoC
device tree bindings/driver upstream hoặc vendor
Cái khả thi và đúng mục tiêu là:

không phụ thuộc vào board BSP của hãng
không phụ thuộc vào layout/config/product policy của hãng
chỉ phụ thuộc ở mức SoC enablement tối thiểu
toàn bộ phần board support và product layer do mình own
Nếu đi theo hướng đó, thứ tự custom nên như sau.

Mục tiêu Cuối
Repo nên tách thành 3 lớp rõ:

SoC platform layer
phần tối thiểu để chip boot được
kernel/u-boot/ATF/firmware ở mức SoC family
Board layer
DTS, pinmux, regulator, pmic, storage, wifi/bt, led, button, display, camera
Product layer
distro, image, packagegroup, app, service, update policy
Hiện tại repo của anh mới own tốt phần product layer, còn board/platform vẫn bám Raspberry Pi khá mạnh.

Làm Gì Trước
Thứ tự đúng là:

Tách product policy ra thật sạch khỏi Raspberry Pi
Tự own board DTS hoàn chỉnh
Tự own kernel config/fragment
Tự own WIC layout
Tự own boot config / boot files
Chỉ sau đó mới giảm dần phụ thuộc kernel/u-boot recipe của BSP hiện tại
Nếu làm ngược, sẽ tốn công mà không tăng quyền kiểm soát thật.

Bước 1: Cố Định Product Layer
Phần này anh đã đi đúng hướng, cần giữ ổn định:

conf/distro/
recipes-core/images/
recipes-core/packagegroups/
recipes-myapp/
recipes-support/
manifests/base.yml
Mục tiêu:

đổi SoC nhưng các file này gần như không đổi
mọi policy như systemd, package set, app/service, release identity không phụ thuộc BSP
Đây là phần không nên sửa thêm nhiều khi port chip mới.

Bước 2: Custom DTS Trước Tiên
Đây là chỗ nên custom đầu tiên trong lớp board support.

Hiện tại DTS của anh vẫn include rất nhiều fragment Raspberry Pi. Muốn thoát khỏi BSP board của hãng, phải làm bước này trước.

Nên làm:

tạo DTS board riêng hoàn chỉnh
chỉ giữ include ở mức SoC/family thật cần thiết
bỏ dần các fragment kiểu board reference Pi
Ưu tiên tự own:

chosen
aliases
UART console
GPIO mapping
LED/button
SD/eMMC
Ethernet PHY
Wi-Fi/Bluetooth wiring
I2C/SPI/UART peripheral routing
regulator/PMIC
camera/display nếu có
Nguyên tắc:

nếu một fragment mô tả “bo mạch reference” thì nên loại dần
nếu một fragment mô tả “SoC block chung” thì có thể giữ
Đây là bước số 1 vì nó giảm phụ thuộc rõ nhất mà không phải fork nguyên BSP.

Bước 3: Own Kernel Config
Sau DTS, bước tiếp theo là kernel config.

Hiện anh vẫn dùng bcm2709_defconfig. Cái này tiện nhưng phụ thuộc BSP.

Nên chuyển sang:

kernel fragment riêng trước
nếu fragment quá nhiều thì mới lên defconfig riêng
Custom trước:

filesystem cần dùng
network drivers cần dùng
watchdog
I2C/SPI/UART/CAN/USB
debug options cần thiết
Bluetooth/Wi-Fi options
overlay/config không cần thì tắt
Mục tiêu:

board nào bật gì là do mình quyết định
không để defconfig vendor kéo quá nhiều thứ thừa
Bước 4: Own WIC / Partition Layout
Cái này rất quan trọng nếu muốn chuyển SoC sau này mà product flow không đổi nhiều.

Hiện anh chưa own .wks rõ ràng. Nên thêm sớm:

wic/<product>.wks hoặc wic/<board>.wks
Custom:

boot partition
rootfs partition
data partition
log partition nếu cần
A/B update layout nếu có OTA
Mục tiêu:

image layout là của sản phẩm, không phải của BSP
đổi SoC nhưng triết lý storage/update vẫn giữ được
Bước 5: Own Boot Policy
Sau WIC, bắt đầu tách boot policy.

Phần này gồm:

boot files nào copy vào FAT/boot partition
kernel cmdline lấy từ đâu
config.txt / extlinux.conf / boot.scr / uEnv.txt tùy nền tảng
serial console default
rootfs bootargs
overlay policy
Nếu còn bám Raspberry Pi:

vẫn có thể own phần config.txt/boot file policy trước
chưa cần bỏ BSP kernel ngay
Mục tiêu:

boot artifact do mình quyết định
không phụ thuộc layout mặc định của board reference
Bước 6: Own recipes-bsp/
Khi 5 bước trên ổn, mới đáng để đầu tư mạnh vào:

recipes-bsp/u-boot/
recipes-bsp/firmware/
recipes-bsp/trusted-firmware-a/ nếu nền tảng cần
các patch bootloader riêng
Đây là lúc bắt đầu thoát khỏi “board BSP” mạnh nhất.

Nhưng lưu ý:

nếu SoC mới vẫn cần vendor u-boot/kernel tree thì vẫn sẽ có phụ thuộc ở mức SoC
cái anh đang loại bỏ là phụ thuộc vào cấu hình board và sản phẩm của họ
Bước 7: Tách Platform Overlay Theo SoC
Sau khi đã own board/product tốt hơn, structure nên là:

manifests/base.yml
manifests/platforms/raspberrypi3.yml
manifests/platforms/<soc2>.yml
Khi chuyển chip:

thay platform manifest
thêm machine mới
thêm kernel/bsp mới
giữ nguyên distro/image/packagegroup/app càng nhiều càng tốt
Đây là đích của refactor hiện tại.

Cái Gì Nên Custom Trước Trong Repo Này
Theo repo hiện tại, thứ tự thực dụng nhất là:

recipes-kernel/linux/files/darkdragon-rpi3.dts
giảm dần include board fragment Raspberry Pi
recipes-kernel/linux/
thêm kernel fragment/config riêng
wic/
thêm .wks riêng
conf/machine/darkdragon-rpi3.conf
bỏ dần biến đặc thù Raspberry Pi, chỉ giữ abstraction board
recipes-bsp/
thêm boot config/bootloader ownership
manifests/platforms/
sau đó mới nhân bản platform khác
Những Gì Chưa Nên Đụng Trước
Chưa nên làm đầu tiên:

viết lại distro
đổi image nhiều lần
fork toàn bộ kernel recipe
cố bỏ hẳn meta-raspberrypi ngay lập tức
Lý do:

tốn công lớn
lợi ích thấp ở giai đoạn đầu
dễ mất khả năng build ổn định
Definition of Done Thực Tế
Anh có thể coi là “thoát board BSP” khi:

DTS board do anh own gần như hoàn toàn
kernel config chính do anh own
WIC layout do anh own
boot policy do anh own
image/packagegroup/app do anh own
BSP bên ngoài chỉ còn cung cấp SoC support và recipe nền
Khuyến Nghị Rất Cụ Thể
Nếu muốn tôi làm tiếp theo hướng này, bước hợp lý nhất ngay bây giờ là:

tạo wic/darkdragon.wks và nối vào machine
refactor darkdragon-rpi3.dts để bỏ dần các include board-fragment Raspberry Pi
thêm kernel fragment riêng cho board
tạo doc/BOARD_OWNERSHIP_ROADMAP.md với checklist migrate khỏi BSP board

