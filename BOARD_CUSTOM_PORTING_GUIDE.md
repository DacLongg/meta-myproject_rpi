# Hướng Dẫn Port Board Custom Sang Yocto

Tài liệu này trả lời câu hỏi thực tế:

> Khi port một board custom sang một SoC bất kỳ thì cần chuẩn bị những file Yocto nào?

Tài liệu được tách theo các nhóm:

- `machine`
- `kernel`
- `u-boot`
- `device tree`
- `image`
- `flash layout`

Ngoài ra có thêm:

- thứ tự triển khai thực tế
- checklist bring-up
- nguyên tắc phân biệt phần nào thuộc vendor BSP, phần nào thuộc board custom

## 1. Tư duy đúng khi port board custom

Khi port một board custom sang Yocto, cần tách rõ 3 lớp:

1. `SoC support`
   - hỗ trợ cho chip / SoC
   - thường do vendor BSP hoặc community layer cung cấp
   - ví dụ: NXP, TI, ST, Rockchip, Raspberry Pi

2. `Board support`
   - mô tả phần cứng cụ thể của board bạn
   - gồm device tree, boot config, kernel fragments, partition layout, GPIO, regulator, PHY, PMIC, LED, button, connector mapping

3. `Product image`
   - root filesystem và package bạn muốn đưa vào sản phẩm
   - app, service, ssh, debug tools, update agent, package set

Sai lầm phổ biến là trộn 3 lớp này vào một chỗ. Làm đúng thì:

- `vendor BSP` lo phần SoC và boot nền
- `board custom` lo phần phần cứng riêng
- `image` lo phần hệ thống chạy trên board

## 2. Bộ file tối thiểu cần chuẩn bị

Với đa số dự án, bạn sẽ cần ít nhất các nhóm file sau:

```text
conf/machine/<machine>.conf

recipes-kernel/linux/linux-<vendor>_%.bbappend
recipes-kernel/linux/files/<board>.dts
recipes-kernel/linux/files/*.dtsi
recipes-kernel/linux/files/*.cfg
recipes-kernel/linux/files/defconfig

recipes-bsp/u-boot/u-boot-<vendor>_%.bbappend
recipes-bsp/u-boot/files/*.cfg
recipes-bsp/u-boot/files/*.patch
recipes-bsp/u-boot/files/*.env

recipes-core/images/<image>.bb

wic/<layout>.wks
```

Không phải dự án nào cũng cần tất cả. Nhưng đây là khung chuẩn để suy nghĩ.

## 3. Phần `machine`

### 3.1. Mục tiêu

`MACHINE` là nơi Yocto biết:

- board này là board nào
- dùng kernel/bootloader/firmware provider nào
- boot kiểu gì
- image boot files là gì
- machine features là gì
- DTB nào cần deploy

### 3.2. File chính

Bạn gần như luôn cần:

```text
conf/machine/<board>.conf
```

Ví dụ:

```text
conf/machine/myproject-rpi.conf
conf/machine/myboard.conf
```

### 3.3. Thường khai báo gì trong machine file

Tuỳ BSP, nhưng thường có:

- `require` hoặc `include` từ machine gần nhất của vendor
- `MACHINEOVERRIDES`
- `KBUILD_DEFCONFIG` hoặc mapping kernel config
- `UBOOT_MACHINE`
- `SERIAL_CONSOLES`
- `KERNEL_IMAGETYPE`
- `KERNEL_DEVICETREE` hoặc biến tương đương
- `MACHINE_FEATURES`
- `WKS_FILE`
- `IMAGE_BOOT_FILES`

Ví dụ tối giản:

```conf
require conf/machine/vendor-reference-board.conf

MACHINEOVERRIDES =. "myboard:vendor-reference-board:"
KBUILD_DEFCONFIG = "vendor_defconfig"
SERIAL_CONSOLES = "115200;ttymxc0"
KERNEL_DEVICETREE = "vendor/myboard.dtb"
UBOOT_MACHINE = "myboard_defconfig"
WKS_FILE = "sdimage-myboard.wks"
```

### 3.4. Khi nào phải sửa machine file

Phải sửa khi board của bạn khác reference board ở một trong các điểm:

- DTB khác
- serial console khác
- bootloader config khác
- loại lưu trữ boot khác
- image boot files khác
- kernel image name khác
- machine features khác

### 3.5. Khi nào có thể kế thừa gần như toàn bộ

Nếu board custom:

- cùng SoC
- cùng boot chain
- cùng loại storage
- chỉ khác GPIO / peripheral routing / LED / connector

thì thường chỉ cần:

- machine mới
- DTS mới
- một ít kernel/u-boot patch

## 4. Phần `kernel`

### 4.1. Mục tiêu

Kernel layer xử lý:

- source kernel nào
- config kernel nào
- patch kernel nào
- DTS nào cần build
- module nào cần bật

### 4.2. File thường cần

Thường dùng:

```text
recipes-kernel/linux/linux-<vendor>_%.bbappend
recipes-kernel/linux/files/<board>.dts
recipes-kernel/linux/files/<shared>.dtsi
recipes-kernel/linux/files/*.cfg
recipes-kernel/linux/files/*.patch
recipes-kernel/linux/files/defconfig
```

### 4.3. `bbappend` làm gì

`linux-<vendor>_%.bbappend` thường dùng để:

- thêm DTS/DTSI riêng
- thêm patch kernel
- thêm config fragments
- thay `defconfig`
- sửa `SRC_URI`

Ví dụ:

```conf
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://myboard.dts \
    file://myboard-extra.cfg \
    file://0001-add-myboard-support.patch \
"
```

### 4.4. Khi nào cần `defconfig`

Cần `defconfig` hoặc config fragments khi:

- BSP vendor không có mapping cho machine của bạn
- bạn cần bật driver chưa có sẵn
- cần tắt driver xung đột
- board cần config kernel khác reference board

Nếu vendor BSP đã làm tốt, nhiều trường hợp chỉ cần:

- reuse `defconfig` của board reference
- thêm vài `.cfg` fragment nhỏ

### 4.5. Những nội dung kernel thường phải chuẩn bị

- driver cho PMIC
- driver cho regulator
- Ethernet MAC/PHY
- MMC/SD/eMMC
- USB host/device
- Wi-Fi/Bluetooth
- display/MIPI/DSI/CSI
- touchscreen
- codec audio
- RTC
- watchdog
- thermal
- CAN/SPI/I2C/UART expansion

## 5. Phần `u-boot`

### 5.1. Khi nào cần quan tâm

Không phải mọi board đều bắt buộc chỉnh U-Boot, nhưng rất nhiều board custom phải sửa phần này nếu:

- boot qua U-Boot
- dùng SPL/TPL
- có DDR init riêng
- cần environment riêng
- cần bootcmd khác
- cần khác partition boot

Với một số nền tảng như Raspberry Pi, có thể U-Boot không phải bootloader bắt buộc trong luồng mặc định. Nhưng với NXP, TI, ST, Rockchip, Allwinner, AM335x, i.MX, Zynq... thì U-Boot rất hay là phần bắt buộc phải chỉnh.

### 5.2. File thường cần

```text
recipes-bsp/u-boot/u-boot-<vendor>_%.bbappend
recipes-bsp/u-boot/files/*.patch
recipes-bsp/u-boot/files/*.cfg
recipes-bsp/u-boot/files/*.env
recipes-bsp/u-boot/files/defconfig
```

### 5.3. Bạn có thể phải sửa gì

- `UBOOT_MACHINE`
- patch thêm board support
- đổi `defconfig`
- thêm boot environment
- sửa bootargs mặc định
- sửa thứ tự boot: SD, eMMC, SPI NOR, NAND, network
- thêm load addresses
- thêm support secure boot nếu có

### 5.4. Những phần dễ bị quên

- console UART trong U-Boot khác với Linux
- partition boot mà U-Boot load file từ đó
- tên kernel image, dtb, extlinux.conf, boot.scr
- DDR training / PMIC init / pinmux sớm

Nếu boot còn chưa qua được U-Boot prompt, chưa nên nhảy sang debug rootfs.

## 6. Phần `device tree`

### 6.1. Mục tiêu

Device tree mô tả phần cứng thực tế của board:

- CPU/SoC
- memory
- pinmux
- GPIO
- regulator
- PMIC
- buses: I2C/SPI/UART/PCIe/USB/MMC
- PHY
- display
- audio
- sensor
- LED/button

### 6.2. File thường cần

```text
recipes-kernel/linux/files/<board>.dts
recipes-kernel/linux/files/<shared>.dtsi
```

Hoặc nếu đang ở giai đoạn nghiên cứu:

```text
Dts/<reference>.dts
Dts/<reference>.dtsi
```

### 6.3. Cách làm đúng

Không viết từ đầu nếu chưa cần. Luồng đúng thường là:

1. tìm board reference gần nhất
2. copy file `.dts` của board đó
3. đổi tên thành board của bạn
4. sửa dần theo schematic

Ví dụ:

- board dùng cùng SoC với EVK vendor
- copy DTS của EVK
- đổi Ethernet PHY, PMIC, LED, button, SDIO, PCIe, USB hub, codec, GPIO mapping

### 6.4. Thông tin bạn bắt buộc phải có

Không có những thứ này thì sửa DTS chỉ là mò:

- schematic
- datasheet SoC
- datasheet PMIC
- datasheet PHY / Wi-Fi / codec / bridge chip
- pinmux table
- power tree
- memory map nếu đặc biệt

### 6.5. Những chỗ phải kiểm tra kỹ trong DTS

- `compatible`
- `model`
- `memory`
- `chosen` / bootargs
- `aliases`
- pinctrl
- regulator chain
- `status = "okay"` / `"disabled"`
- MMC/SD/eMMC bus width và card-detect/write-protect
- Ethernet PHY address/reset GPIO
- USB role host/device/otg
- console UART
- interrupt lines
- clock source

### 6.6. Sai lầm phổ biến

- sửa `.dtb` thay vì `.dts`
- copy quá nhiều file include nhưng không biết file nào là source chính
- sửa trong `tmp/work` thay vì đưa file vào layer
- giữ nguyên node của reference board dù PCB custom không có phần cứng đó

## 7. Phần `image`

### 7.1. Mục tiêu

Image recipe quyết định:

- rootfs có package nào
- service nào được cài
- debug hay production
- ssh có bật không
- package group nào được thêm

### 7.2. File thường cần

```text
recipes-core/images/<image>.bb
```

Ví dụ:

```text
recipes-core/images/myproject-rpi-image.bb
```

### 7.3. Nên để gì trong image

Phần image chỉ nên chứa:

- package
- feature
- service phụ thuộc package
- user-facing filesystem content

Không nên nhét vào image:

- cấu hình SoC/board
- pinmux
- boot chain logic
- kernel provider logic

### 7.4. Giai đoạn bring-up nên có gì

Thường nên bật:

- `ssh-server-openssh`
- `debug-tweaks`
- serial console
- công cụ debug cơ bản
- package test phần cứng nếu có

### 7.5. Giai đoạn production nên xem lại

- bỏ `debug-tweaks`
- khóa password / SSH key đúng chuẩn
- read-only rootfs nếu cần
- watchdog
- update agent
- logging policy
- package cleanup

## 8. Phần `flash layout`

### 8.1. Mục tiêu

Flash layout quyết định:

- image được chia partition thế nào
- partition boot ở đâu
- rootfs ở đâu
- bootloader được đặt thế nào
- file gì đi vào partition nào

### 8.2. File thường cần

```text
wic/<layout>.wks
```

Ví dụ:

```text
wic/sdimage-myboard.wks
wic/emmc-myboard.wks
```

Hoặc có thể reuse layout từ BSP vendor nếu phù hợp.

### 8.3. Khi nào phải tự tạo `.wks`

Khi board custom:

- boot từ eMMC thay vì SD
- cần nhiều partition hơn
- có A/B update scheme
- cần partition data riêng
- dùng SPI NOR + rootfs ở eMMC/NAND
- cần alignment đặc biệt

### 8.4. Những gì thường có trong `.wks`

- partition boot FAT
- rootfs ext4/squashfs
- partition data
- bootloader raw region nếu cần
- UUID / label
- size / alignment

Ví dụ khái niệm:

```text
boot partition
rootfs partition
data partition
```

### 8.5. Flash layout còn liên quan tới

- `IMAGE_BOOT_FILES`
- bootloader config
- firmware file names
- kernel image name
- dtb path
- `fstab`
- update strategy

Nhiều lỗi boot không phải do kernel, mà do file được đặt sai partition hoặc sai tên trong boot partition.

## 9. Phần firmware và binary blobs

Tuy câu hỏi không tách riêng phần này, nhưng trên nhiều nền tảng đây là phần bắt buộc.

Bạn có thể phải chuẩn bị thêm:

- Wi-Fi firmware
- Bluetooth firmware
- DDR training firmware
- Trusted Firmware-A
- OP-TEE
- GPU/VPU firmware
- SoC boot blobs

Các file này có thể đến từ:

- vendor BSP layer
- package riêng
- recipe riêng trong layer của bạn

Nếu thiếu đúng blob, board có thể:

- không boot
- không lên Wi-Fi/BT
- treo ở boot chain sớm

## 10. Cấu trúc thư mục khuyến nghị trong layer

Một cấu trúc dễ maintain:

```text
conf/
  machine/
    myboard.conf

recipes-kernel/
  linux/
    linux-vendor_%.bbappend
    files/
      myboard.dts
      myboard-common.dtsi
      0001-add-myboard-support.patch
      myboard-extra.cfg

recipes-bsp/
  u-boot/
    u-boot-vendor_%.bbappend
    files/
      0001-add-myboard-support.patch
      myboard_defconfig
      myboard.env

recipes-core/
  images/
    myboard-image.bb

wic/
  sdimage-myboard.wks
```

## 11. Thứ tự làm việc thực tế

Đây là thứ tự thực dụng nhất khi bring-up board mới:

1. Xác nhận có BSP vendor/community usable
2. Chọn reference board gần nhất
3. Tạo `conf/machine/<board>.conf`
4. Reuse kernel/U-Boot config từ reference board trước
5. Copy DTS reference thành DTS riêng
6. Tích hợp DTS vào layer bằng `bbappend`
7. Build kernel và boot tới serial console
8. Chỉ sau khi boot được mới sửa image/app/service
9. Sau khi Linux lên mới tối ưu flash layout và production hardening

Nếu làm ngược, bạn sẽ mất thời gian debug rootfs trong khi boot chain còn sai.

## 12. Checklist bring-up theo mức tối thiểu

### 12.1. Mốc 1: bootloader sống

- có tín hiệu nguồn đúng
- có serial output
- boot ROM chạy
- bootloader lên được prompt hoặc log

### 12.2. Mốc 2: kernel sống

- kernel được load
- DTB đúng
- console đúng
- không panic quá sớm

### 12.3. Mốc 3: rootfs sống

- mount rootfs thành công
- init/systemd chạy
- login được qua serial

### 12.4. Mốc 4: peripheral sống

- MMC/eMMC/SD
- Ethernet
- USB
- I2C/SPI/UART
- Wi-Fi/BT
- audio/display/camera

### 12.5. Mốc 5: product image sống

- app tự start
- log đúng
- watchdog / update / security policy đúng

## 13. Câu hỏi nên trả lời trước khi bắt đầu

Trước khi viết file Yocto, nên có câu trả lời cho các câu sau:

1. SoC cụ thể là gì?
2. Có BSP vendor/community nào đang support tốt không?
3. Board reference gần nhất là board nào?
4. Boot chain là gì?
5. Storage boot là gì: SD, eMMC, NAND, NOR?
6. Console debug nằm ở UART nào?
7. PMIC / DDR / PHY / Wi-Fi / codec dùng chip gì?
8. Board khác reference board ở đâu?
9. Có cần U-Boot riêng không?
10. Có cần partition layout riêng không?

Không trả lời được các câu này mà bắt đầu sửa DTS thường sẽ đi rất chậm.

## 14. Quy tắc ngắn gọn để nhớ

- `machine` mô tả board cho Yocto biết
- `kernel` lo source, config, patch, DTS build
- `u-boot` lo boot chain sớm
- `device tree` mô tả phần cứng thật
- `image` lo package và rootfs
- `flash layout` lo partition và vị trí file boot

Và quy tắc quan trọng nhất:

- nếu vendor BSP đã có khung tốt, hãy kế thừa
- chỉ custom phần board của bạn
- đừng viết BSP từ đầu nếu chưa bị bắt buộc

## 15. Áp vào repo hiện tại

Trong repo này:

- `machine`: [conf/machine/myproject-rpi.conf](/home/ddragon/yocto/meta-myproject_rpi/conf/machine/myproject-rpi.conf:1)
- `image`: [recipes-core/images/myproject-rpi-image.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-core/images/myproject-rpi-image.bb:1)
- `DTS tham khảo`: thư mục [Dts](/home/ddragon/yocto/meta-myproject_rpi/Dts)

Các phần chưa scaffold đầy đủ:

- `recipes-kernel/linux/linux-raspberrypi_%.bbappend`
- `recipes-kernel/linux/files/myproject-rpi.dts`
- `wic/*.wks` riêng của project
- `u-boot` customization nếu sau này cần

Thứ tự tiếp theo hợp lý cho repo này là:

1. tạo `myproject-rpi.dts`
2. tích hợp DTS đó vào kernel bằng `bbappend`
3. đổi `RPI_KERNEL_DEVICETREE` sang DTB riêng
4. boot tới serial shell
5. sau đó mới tối ưu peripheral và image
