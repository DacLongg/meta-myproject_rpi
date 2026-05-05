# Image Contents

Tài liệu này mô tả rõ các image hiện có trong project, mỗi image được dùng khi nào, và nội dung chính của chúng đến từ đâu.

## 1. Các image hiện có

### `darkdragon-image`

File:

- [recipes-core/images/darkdragon-image.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-core/images/darkdragon-image.bb:1)

Mục đích:

- image nền theo hướng sản phẩm thực tế
- dùng cho board `darkdragon-rpi3`
- chỉ chứa package runtime cần thiết để hệ thống chạy

### `darkdragon-dev-image`

File:

- [recipes-core/images/darkdragon-dev-image.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-core/images/darkdragon-dev-image.bb:1)

Mục đích:

- image dành cho phát triển và bring-up
- kế thừa từ `darkdragon-image`
- thêm các feature và tool phục vụ debug/test

### `myproject-rpi-image`

File:

- [recipes-core/images/myproject-rpi-image.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-core/images/myproject-rpi-image.bb:1)

Mục đích:

- alias tương thích ngược
- hiện tại chỉ `require` sang `darkdragon-dev-image`
- giữ lại để không làm gãy script cũ hoặc thói quen đặt tên cũ của developer

## 2. Image mặc định của project

Image mặc định hiện tại là:

- `darkdragon-dev-image`

Được khai báo trong:

- [manifests/kas.yml](/home/ddragon/yocto/meta-myproject_rpi/manifests/kas.yml:6)
- [scripts/build_rpi_image.sh](/home/ddragon/yocto/meta-myproject_rpi/scripts/build_rpi_image.sh:6)

Điều này có nghĩa:

- khi chạy `./scripts/build_rpi_image.sh` mà không truyền `IMAGE_NAME=...`
- project sẽ build `darkdragon-dev-image`

## 3. Nội dung của `darkdragon-image`

### Image feature

`darkdragon-image` bật:

- `ssh-server-openssh`

Nguồn khai báo:

- [recipes-core/images/darkdragon-image.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-core/images/darkdragon-image.bb:7)

### Package cài vào image

`darkdragon-image` kéo vào:

- `packagegroup-darkdragon-base`

Nguồn khai báo:

- [recipes-core/images/darkdragon-image.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-core/images/darkdragon-image.bb:9)

### Nội dung của `packagegroup-darkdragon-base`

File:

- [recipes-core/packagegroups/packagegroup-darkdragon-base.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-core/packagegroups/packagegroup-darkdragon-base.bb:1)

Các package chính:

- `bash`
- `bluez5`
- `ca-certificates`
- `darkdragon-release`
- `ethtool`
- `i2c-tools`
- `iproute2`
- `iputils`
- `kernel-modules`
- `myproject-app`
- `openssh-sftp-server`
- `tzdata`
- `iw`
- `wpa-supplicant`

Ý nghĩa thực tế:

- có shell và bộ công cụ runtime cơ bản
- có SSH/SFTP để remote vào board
- có Wi-Fi và Bluetooth userspace nền
- có toàn bộ kernel modules
- có app chính của dự án
- có file nhận diện bản build qua `darkdragon-release`

## 4. Nội dung của `darkdragon-dev-image`

### Kế thừa

`darkdragon-dev-image` kế thừa:

- `darkdragon-image`

Nguồn khai báo:

- [recipes-core/images/darkdragon-dev-image.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-core/images/darkdragon-dev-image.bb:5)

### Image feature thêm vào

`darkdragon-dev-image` thêm:

- `debug-tweaks`
- `package-management`

Nguồn khai báo:

- [recipes-core/images/darkdragon-dev-image.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-core/images/darkdragon-dev-image.bb:7)

Ý nghĩa thực tế:

- dễ login và debug hơn trong giai đoạn bring-up/dev
- có package manager trên target nếu backend package hỗ trợ

### Package cài thêm vào image

`darkdragon-dev-image` kéo thêm:

- `packagegroup-darkdragon-dev`

Nguồn khai báo:

- [recipes-core/images/darkdragon-dev-image.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-core/images/darkdragon-dev-image.bb:9)

### Nội dung của `packagegroup-darkdragon-dev`

File:

- [recipes-core/packagegroups/packagegroup-darkdragon-dev.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-core/packagegroups/packagegroup-darkdragon-dev.bb:1)

Các package chính:

- `hello`
- `less`
- `procps`
- `rsync`
- `strace`
- `tcpdump`
- `vim`

Ý nghĩa thực tế:

- có app mẫu `hello`
- có tool kiểm tra process/runtime
- có tool network sniffing/debug
- có editor và tool sync/log/debug cơ bản

## 5. Recipe chính xuất hiện trong image

### `myproject-app`

Recipe:

- [recipes-myapp/myproject-app/myproject-app.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-myapp/myproject-app/myproject-app.bb:1)

Service:

- [recipes-myapp/myproject-app/files/myproject-app.service](/home/ddragon/yocto/meta-myproject_rpi/recipes-myapp/myproject-app/files/myproject-app.service:1)

Vai trò:

- app/runtime entry point chính của project
- chạy dưới `systemd`
- được restart tự động nếu chết

### `hello`

Recipe:

- [recipes-myapp/hello/hello.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-myapp/hello/hello.bb:1)

Vai trò:

- app mẫu phục vụ bring-up/dev
- không nên coi là thành phần sản phẩm bắt buộc
- hiện chỉ có trong `darkdragon-dev-image`

### `darkdragon-release`

Recipe:

- [recipes-support/darkdragon-release/darkdragon-release.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-support/darkdragon-release/darkdragon-release.bb:1)

Vai trò:

- cung cấp `/etc/os-release`
- cung cấp `/etc/issue`
- cung cấp `/etc/motd`
- giúp nhận diện image trên target nhanh hơn

## 6. Quan hệ giữa distro, machine và image

### `machine`

File:

- [conf/machine/darkdragon-rpi3.conf](/home/ddragon/yocto/meta-myproject_rpi/conf/machine/darkdragon-rpi3.conf:1)

Quyết định:

- board nào đang build
- DTB nào dùng
- artifact type nào tạo ra
- feature phần cứng nào được khai báo

### `distro`

File:

- [conf/distro/darkdragon.conf](/home/ddragon/yocto/meta-myproject_rpi/conf/distro/darkdragon.conf:1)

Quyết định:

- policy hệ thống
- `systemd`
- `DISTRO_FEATURES`
- package format

### `image`

File:

- [recipes-core/images/darkdragon-image.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-core/images/darkdragon-image.bb:1)
- [recipes-core/images/darkdragon-dev-image.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-core/images/darkdragon-dev-image.bb:1)

Quyết định:

- root filesystem cuối cùng chứa package gì
- image này là bản production hay development

## 7. Khi nào nên sửa file nào

Nếu muốn:

- thêm tool cho mọi image: sửa `packagegroup-darkdragon-base.bb`
- thêm tool chỉ cho dev image: sửa `packagegroup-darkdragon-dev.bb`
- đổi feature của production image: sửa `darkdragon-image.bb`
- đổi feature của dev image: sửa `darkdragon-dev-image.bb`
- đổi app/service chính của sản phẩm: sửa recipe trong `recipes-myapp/`
- đổi policy hệ thống như init manager, distro features: sửa `conf/distro/darkdragon.conf`
- đổi board/DTB/kernel wiring: sửa `conf/machine/` và `recipes-kernel/`

## 8. Lệnh build thường dùng

Build image mặc định:

```bash
./scripts/build_rpi_image.sh
```

Build production image:

```bash
IMAGE_NAME=darkdragon-image ./scripts/build_rpi_image.sh
```

Build dev image:

```bash
IMAGE_NAME=darkdragon-dev-image ./scripts/build_rpi_image.sh
```

Build alias cũ:

```bash
IMAGE_NAME=myproject-rpi-image ./scripts/build_rpi_image.sh
```
