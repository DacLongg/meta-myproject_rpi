# Tài Liệu Tổng Hợp `DISTRO_FEATURES`

Tài liệu này tổng hợp các `DISTRO_FEATURES` chuẩn của Yocto/Poky và giải thích:

- feature đó dùng để làm gì
- thường ảnh hưởng tới phần nào của hệ thống
- khi bật/tắt thì image có thể thay đổi ra sao

## 1. Cần hiểu đúng về `DISTRO_FEATURES`

`DISTRO_FEATURES` là tập các cờ mô tả **policy hệ thống ở cấp distro**.

Nó không trực tiếp là danh sách package. Thay vào đó, recipes và classes sẽ kiểm tra:

- feature có tồn tại trong `DISTRO_FEATURES` hay không
- nếu có thì bật/tắt `PACKAGECONFIG`, `configure option`, dependency, service, packagegroup, hoặc file cài theo

Nói ngắn gọn:

- `MACHINE_FEATURES` mô tả phần cứng board
- `DISTRO_FEATURES` mô tả policy phần mềm của distro
- `IMAGE_FEATURES` mô tả các tính năng thêm vào rootfs image

## 2. Một lưu ý quan trọng: không có một danh sách tuyệt đối cho mọi project

Danh sách trong tài liệu này là:

1. `Danh sách chuẩn của Yocto/Poky as shipped`
2. `Các feature backfill quan trọng` mà bạn vẫn gặp trong build thực tế

Tuy nhiên, bất kỳ layer nào cũng có thể:

- kiểm tra một feature riêng
- định nghĩa logic riêng theo tên feature tự đặt

Ví dụ, một BSP vendor hoặc layer nội bộ có thể tự dùng các feature như:

- `gpu`
- `secureboot`
- `vendor-wifi`
- `qt6`

Những feature kiểu đó không phải feature chuẩn của Poky, nhưng vẫn hợp lệ nếu metadata của layer đó dùng tới.

Vì vậy:

- file này là tài liệu nền chuẩn
- không phải “toàn bộ mọi feature trong mọi layer trên đời”

## 3. Cách tự kiểm tra `DISTRO_FEATURES` hiện tại

Xem giá trị cuối cùng mà BitBake đang dùng:

```bash
~/yocto/setup-yocto-env.sh
bitbake -e myproject-rpi-image | rg '^DISTRO_FEATURES='
```

Xem recipe nào phụ thuộc vào `DISTRO_FEATURES`:

```bash
rg -n "contains\\('DISTRO_FEATURES'|contains\\(\"DISTRO_FEATURES\"" ~/yocto/poky ~/yocto/meta-raspberrypi
```

Hoặc rộng hơn:

```bash
rg -n "DISTRO_FEATURES" ~/yocto/poky ~/yocto/meta-raspberrypi
```

## 4. Danh sách `DISTRO_FEATURES` chuẩn của Poky

Theo tài liệu Poky, đây là các distro feature “as shipped”.

### 4.1. `alsa`

Ý nghĩa:

- bật hỗ trợ ALSA audio

Thường ảnh hưởng:

- package audio
- `PACKAGECONFIG` của multimedia stack
- module/utility liên quan âm thanh

Tác động đến image:

- có thể kéo thêm thư viện/utility âm thanh
- nếu tắt, các recipe audio-aware có thể build với ít tính năng hơn

### 4.2. `api-documentation`

Ý nghĩa:

- bật sinh tài liệu API trong quá trình build

Thường ảnh hưởng:

- SDK
- package/doc artifacts

Tác động đến image:

- thường không ảnh hưởng trực tiếp rootfs target nhiều
- nhưng ảnh hưởng artifact build và SDK

### 4.3. `bluetooth`

Ý nghĩa:

- bật hỗ trợ Bluetooth ở cấp distro

Thường ảnh hưởng:

- bluez
- utility quản lý BT
- recipes có `PACKAGECONFIG[bluetooth]`

Tác động đến image:

- có thể thêm package Bluetooth
- có thể bật hỗ trợ BT trong thư viện/framework

### 4.4. `cramfs`

Ý nghĩa:

- bật hỗ trợ CramFS

Thường ảnh hưởng:

- tool và support cho filesystem CramFS

Tác động đến image:

- thường nhỏ, chủ yếu ảnh hưởng khả năng build hoặc dùng filesystem này

### 4.5. `directfb`

Ý nghĩa:

- bật DirectFB

Thường ảnh hưởng:

- graphics stack cũ
- recipes multimedia/graphics có hỗ trợ DirectFB

Tác động đến image:

- có thể thêm thư viện DirectFB
- tăng kích thước image nếu bị kéo thêm dependency

### 4.6. `ext2`

Ý nghĩa:

- bật support công cụ cho thiết bị có storage kiểu HDD/Microdrive hoặc ext filesystem workflow liên quan

Thường ảnh hưởng:

- tool filesystem / storage-related package

Tác động đến image:

- thường gián tiếp, không phải feature UI hay service lớn

### 4.7. `ipsec`

Ý nghĩa:

- bật hỗ trợ IPSec

Thường ảnh hưởng:

- network stack
- VPN / security package

Tác động đến image:

- có thể thêm dependency về crypto/network

### 4.8. `ipv6`

Ý nghĩa:

- bật hỗ trợ IPv6

Thường ảnh hưởng:

- network-enabled recipes
- daemon và utility có lựa chọn IPv6

Tác động đến image:

- thay đổi khả năng network runtime
- có thể thêm hoặc bật cấu hình IPv6 trong một số package

### 4.9. `keyboard`

Ý nghĩa:

- bật hỗ trợ keyboard

Thường ảnh hưởng:

- keymap
- console/input package

Tác động đến image:

- thêm dữ liệu/keymap hoặc utility input liên quan

### 4.10. `ldconfig`

Ý nghĩa:

- bật hỗ trợ `ldconfig` và `ld.so.conf` trên target

Thường ảnh hưởng:

- glibc runtime behavior
- linker cache handling

Tác động đến image:

- thay đổi cách thư viện động được quản lý
- có thể liên quan postinstall/runtime linker behavior

Lưu ý:

- đây cũng là một `backfilled feature`

### 4.11. `nfs`

Ý nghĩa:

- bật NFS client support

Thường ảnh hưởng:

- package mount/NFS client
- network filesystem support

Tác động đến image:

- có thể thêm tool và dependency để mount NFS

### 4.12. `opengl`

Ý nghĩa:

- bật OpenGL support

Thường ảnh hưởng:

- Mesa / GPU stack
- graphics framework
- UI framework có `PACKAGECONFIG[opengl]`

Tác động đến image:

- thường khá lớn
- có thể kéo thêm graphics libraries
- ảnh hưởng build của Qt/SDL/Weston/Mesa và các package đồ hoạ khác

### 4.13. `pci`

Ý nghĩa:

- bật hỗ trợ PCI bus ở cấp distro

Thường ảnh hưởng:

- utility hoặc package phụ thuộc PCI support

Tác động đến image:

- thường chỉ có ý nghĩa khi hardware thực sự có PCI/PCIe và distro muốn support nó

### 4.14. `pcmcia`

Ý nghĩa:

- bật hỗ trợ PCMCIA / CompactFlash

Thường ảnh hưởng:

- legacy hardware support

Tác động đến image:

- ít gặp trên hệ thống embedded hiện đại

### 4.15. `ppp`

Ý nghĩa:

- bật hỗ trợ PPP dialup

Thường ảnh hưởng:

- modem / dialup utilities
- network stack option

Tác động đến image:

- thêm package PPP-related nếu recipe cần

### 4.16. `ptest`

Ý nghĩa:

- bật build package tests cho các recipe hỗ trợ `ptest`

Thường ảnh hưởng:

- build artifacts
- package test packages

Tác động đến image:

- không tự động thêm test vào image
- nhưng làm cho `ptest` packages có sẵn để cài hoặc dùng với `ptest-pkgs`

### 4.17. `smbfs`

Ý nghĩa:

- bật SMB/CIFS client support

Thường ảnh hưởng:

- package mount Samba/Windows share

Tác động đến image:

- thêm capability mount SMB nếu package tương ứng được đưa vào image

### 4.18. `systemd`

Ý nghĩa:

- bật systemd init manager support

Thường ảnh hưởng:

- init system
- service unit packaging
- lựa chọn class/runtime logic giữa `systemd` và `sysvinit`

Tác động đến image:

- ảnh hưởng rất lớn
- thay đổi service management, boot flow userspace, package dependency
- nhiều recipe sẽ cài unit files hoặc bỏ init scripts tuỳ feature này

Lưu ý:

- nếu chọn `systemd`, thường đi kèm:
  - `VIRTUAL-RUNTIME_init_manager = "systemd"`
  - loại bỏ `sysvinit` nếu không muốn song song

### 4.19. `usbgadget`

Ý nghĩa:

- bật USB gadget device support

Thường ảnh hưởng:

- package/config cho USB device mode
- networking/serial/storage over USB

Tác động đến image:

- có thể thêm utility hoặc support package phục vụ gadget mode

### 4.20. `usbhost`

Ý nghĩa:

- bật USB host support

Thường ảnh hưởng:

- package/utility cho thiết bị ngoại vi USB

Tác động đến image:

- gián tiếp; có ý nghĩa hơn khi kết hợp với `MACHINE_FEATURES` tương ứng

### 4.21. `usrmerge`

Ý nghĩa:

- gộp `/bin`, `/sbin`, `/lib`, `/lib64` vào dưới `/usr`

Thường ảnh hưởng:

- layout filesystem
- package compatibility
- runtime path assumptions

Tác động đến image:

- thay đổi cấu trúc rootfs rõ rệt
- cần cẩn thận với script/package cũ giả định layout truyền thống

### 4.22. `wayland`

Ý nghĩa:

- bật Wayland protocol và library liên quan

Thường ảnh hưởng:

- Weston
- graphics/UI stack
- framework có `PACKAGECONFIG[wayland]`

Tác động đến image:

- có thể kéo thêm compositor/library
- ảnh hưởng build option của nhiều package đồ hoạ

### 4.23. `wifi`

Ý nghĩa:

- bật Wi-Fi support ở cấp distro

Thường ảnh hưởng:

- network manager
- wireless tools
- recipe có `PACKAGECONFIG[wifi]`

Tác động đến image:

- có thể kéo thêm package network/wireless
- thường đi cùng `MACHINE_FEATURES` nếu board thật có Wi-Fi

### 4.24. `x11`

Ý nghĩa:

- bật X server và các thư viện liên quan

Thường ảnh hưởng:

- Xorg/X11 libs
- UI framework
- package graphics cũ hoặc desktop-oriented

Tác động đến image:

- thường tăng size khá nhiều
- ảnh hưởng mạnh tới graphics stack

## 5. Các `DISTRO_FEATURES` backfill quan trọng

Ngoài danh sách “as shipped”, Poky còn có:

```conf
DISTRO_FEATURES_BACKFILL = "pulseaudio sysvinit gobject-introspection-data ldconfig"
```

Điều này nghĩa là các feature này có thể tự động được thêm vào nếu bạn không chặn bằng `DISTRO_FEATURES_BACKFILL_CONSIDERED`.

### 5.1. `pulseaudio`

Ý nghĩa:

- bật PulseAudio support trong các package có hỗ trợ

Thường ảnh hưởng:

- SDL
- multimedia stack
- desktop/audio-related package

Tác động đến image:

- có thể kéo thêm `pulseaudio` và client config
- tăng footprint audio stack

Nếu không muốn:

```conf
DISTRO_FEATURES_BACKFILL_CONSIDERED += "pulseaudio"
```

### 5.2. `sysvinit`

Ý nghĩa:

- bật SysV init support

Thường ảnh hưởng:

- init scripts
- recipe hỗ trợ cả `systemd` và `sysvinit`

Tác động đến image:

- nếu không kiểm soát kỹ, bạn có thể vô tình có logic liên quan `sysvinit`

Nếu bạn dùng systemd-only distro, thường sẽ chặn backfill này.

Ví dụ:

```conf
DISTRO_FEATURES:append = " systemd"
DISTRO_FEATURES_BACKFILL_CONSIDERED += "sysvinit"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = ""
```

### 5.3. `gobject-introspection-data`

Ý nghĩa:

- bật dữ liệu hỗ trợ GObject introspection

Thường ảnh hưởng:

- GNOME/GLib ecosystem
- bindings/runtime metadata

Tác động đến image:

- có thể tăng package/data footprint

### 5.4. `ldconfig`

Ý nghĩa:

- như phần ở trên, đây cũng là backfilled feature

Tác động đến image:

- liên quan runtime linker behavior

## 6. Những feature rất hay dùng trong embedded thực tế

Nếu chỉ nhìn từ góc embedded Linux phổ biến, các feature thường gặp nhất là:

- `systemd`
- `wifi`
- `bluetooth`
- `ipv6`
- `opengl`
- `wayland`
- `x11`
- `usrmerge`
- `ptest`
- `alsa`

Không phải project nào cũng nên bật hết. Mỗi feature mở thêm thường có nghĩa là:

- thêm dependency
- tăng thời gian build
- tăng kích thước image
- tăng bề mặt debug

## 7. Ảnh hưởng của `DISTRO_FEATURES` tới image theo cách dễ nhớ

Không phải feature nào cũng tác động giống nhau. Có thể chia thành các nhóm:

### 7.1. Ảnh hưởng đến runtime stack lớn

Ví dụ:

- `systemd`
- `x11`
- `wayland`
- `opengl`
- `pulseaudio`

Các feature này có thể:

- kéo thêm rất nhiều package
- đổi service management
- đổi graphics/audio stack
- tăng mạnh kích thước image

### 7.2. Ảnh hưởng đến networking/security capability

Ví dụ:

- `wifi`
- `bluetooth`
- `ipv6`
- `ipsec`
- `nfs`
- `smbfs`
- `ppp`

Các feature này thường:

- bật support trong package mạng
- thêm utility hoặc dependency liên quan

### 7.3. Ảnh hưởng đến layout hoặc policy hệ thống

Ví dụ:

- `usrmerge`
- `ldconfig`
- `api-documentation`
- `ptest`

Các feature này có thể:

- đổi filesystem layout
- đổi artifact build
- đổi cách package/runtime hoạt động

### 7.4. Ảnh hưởng nhỏ hoặc khá niche

Ví dụ:

- `cramfs`
- `pcmcia`
- `directfb`

Các feature này chỉ có ý nghĩa khi đúng stack phần cứng/phần mềm của bạn dùng tới.

## 8. Cách chọn `DISTRO_FEATURES` cho project mới

Đừng bắt đầu bằng cách bật thật nhiều.

Nên bắt đầu từ tối thiểu:

```conf
DISTRO_FEATURES:append = " systemd"
```

Rồi thêm dần theo nhu cầu:

- cần Wi-Fi: thêm `wifi`
- cần Bluetooth: thêm `bluetooth`
- cần UI modern embedded: thêm `wayland`
- cần desktop/X stack: thêm `x11`
- cần GPU/OpenGL: thêm `opengl`
- cần test package: thêm `ptest`

## 9. Cách biết một `DISTRO_FEATURE` có thực sự ảnh hưởng tới build của bạn không

### 9.1. Xem giá trị cuối cùng

```bash
bitbake -e myproject-rpi-image | rg '^DISTRO_FEATURES='
```

### 9.2. Tìm recipe nào dùng feature đó

Ví dụ với `systemd`:

```bash
rg -n "DISTRO_FEATURES.*systemd|contains\\(.*systemd" ~/yocto/poky ~/yocto/meta-raspberrypi
```

Ví dụ với `wifi`:

```bash
rg -n "DISTRO_FEATURES.*wifi|contains\\(.*wifi" ~/yocto/poky ~/yocto/meta-raspberrypi
```

### 9.3. So sánh image trước và sau

Thay đổi feature rồi build lại, sau đó so:

- danh sách package
- kích thước image
- file boot
- service enable

Nếu muốn kỹ hơn, dùng:

```bash
bitbake -g myproject-rpi-image
```

và so dependency graph, hoặc dùng buildhistory nếu project bật tính năng đó.

## 10. Áp vào repo hiện tại

Trong repo này, distro policy đang nằm ở:

- [conf/distro/darkdragon.conf](/home/ddragon/yocto/meta-myproject_rpi/conf/distro/darkdragon.conf:1)

Hiện đang bật:

```conf
DISTRO_FEATURES:append = " systemd wifi"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = ""
```

Điều đó có nghĩa:

- distro này chọn `systemd`
- distro này bật hỗ trợ Wi-Fi ở cấp policy
- nhưng phần board thật có Wi-Fi hay không vẫn còn phụ thuộc `MACHINE_FEATURES` và phần cứng thật

## 11. Nguồn tham chiếu gốc

Danh sách trong file này được tổng hợp từ:

- [features.rst](/home/ddragon/yocto/poky/documentation/ref-manual/features.rst:1)
- [bitbake.conf](/home/ddragon/yocto/poky/meta/conf/bitbake.conf:906)

Đây là nguồn chuẩn nên đọc khi muốn xác minh:

- feature chuẩn nào được Poky ship sẵn
- feature nào là `backfill`

## 12. Kết luận ngắn gọn

- `DISTRO_FEATURES` là policy switch ở cấp distro
- nó không trực tiếp là package list, nhưng ảnh hưởng mạnh tới cách recipe build
- các feature lớn như `systemd`, `x11`, `wayland`, `opengl`, `pulseaudio` có thể thay đổi image rất nhiều
- danh sách “chuẩn” của Poky có giới hạn; layer ngoài vẫn có thể dùng feature riêng

Khi gặp một feature lạ, cách đúng là:

1. xem nó có trong `DISTRO_FEATURES` hiện tại không
2. `rg` xem metadata nào đang dùng nó
3. kiểm tra package, dependency và image output thay đổi thế nào
