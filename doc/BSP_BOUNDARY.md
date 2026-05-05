# BSP Boundary

Tài liệu này trả lời câu hỏi:

> Trong repo hiện tại, phần nào đang kế thừa từ `meta-raspberrypi`, phần nào là của project, và khi nào cần tự tách ra thành board support riêng?

Mục tiêu là tránh nhầm giữa:

- `vendor/community BSP`
- `board custom support`
- `product policy / image / app`

## 1. Kết luận ngắn

Hiện tại project đang đi theo mô hình:

- **reuse mạnh** phần `BSP Raspberry Pi`
- **override mỏng** ở lớp `machine`
- **thêm phần project** ở lớp `distro`, `image`, `packagegroup`, `app`, `service`

Điều này hợp lý khi:

- board còn rất gần Raspberry Pi 3 reference design
- mục tiêu hiện tại là build được image ổn định
- chưa muốn gánh chi phí maintain một BSP tách biệt hoàn toàn

Điều này **chưa phải** là mức “board custom owned 100%” nếu phần cứng đã khác đáng kể với Raspberry Pi reference board.

## 2. Những gì hiện đang lấy từ `meta-raspberrypi`

## 2.1. Machine base

File:

- [conf/machine/darkdragon-rpi3.conf](/home/ddragon/yocto/meta-myproject_rpi/conf/machine/darkdragon-rpi3.conf:7)

Hiện tại:

- `require conf/machine/raspberrypi3.conf`

Ý nghĩa:

- nền machine vẫn là machine của Raspberry Pi 3
- project chỉ chồng thêm một số biến riêng

Những gì đang được kế thừa gián tiếp từ BSP:

- boot flow cho Pi
- kernel/provider mặc định
- firmware packaging behavior
- image deploy behavior
- nhiều machine defaults khác của dòng Raspberry Pi

## 2.2. Kernel recipe

File:

- [recipes-kernel/linux/linux-raspberrypi_%.bbappend](/home/ddragon/yocto/meta-myproject_rpi/recipes-kernel/linux/linux-raspberrypi_%.bbappend:1)

Hiện tại:

- project **không có** recipe kernel riêng
- project chỉ `bbappend` lên `linux-raspberrypi`

Ý nghĩa:

- kernel recipe gốc vẫn do `meta-raspberrypi` cung cấp
- project chỉ chèn thêm DTS riêng

Điều này là mô hình rất phổ biến và thực dụng khi board vẫn cùng họ phần cứng với board reference.

## 2.3. Device tree family includes

File:

- [recipes-kernel/linux/files/darkdragon-rpi3.dts](/home/ddragon/yocto/meta-myproject_rpi/recipes-kernel/linux/files/darkdragon-rpi3.dts:11)

Hiện tại DTS custom đang include:

- `bcm2710.dtsi`
- `bcm2709-rpi.dtsi`
- `bcm283x-rpi-smsc9514.dtsi`
- `bcm283x-rpi-csi1-2lane.dtsi`
- `bcm283x-rpi-i2c0mux_0_44.dtsi`
- `bcm271x-rpi-bt.dtsi`

Ý nghĩa:

- project đang reuse gần như toàn bộ board family description của Raspberry Pi
- DTS custom hiện là một lớp wrapper + override nhẹ

Đây là cách làm hợp lý ở giai đoạn đầu, nhưng nó có nghĩa là:

- khi upstream Raspberry Pi DTS thay đổi
- project cũng bị phụ thuộc theo

## 2.4. Firmware-backed board control

File:

- [recipes-kernel/linux/files/darkdragon-rpi3.dts](/home/ddragon/yocto/meta-myproject_rpi/recipes-kernel/linux/files/darkdragon-rpi3.dts:31)

Hiện tại project đang giữ:

- `raspberrypi,firmware-gpio`
- label `expgpio`

Ý nghĩa:

- vẫn đang dựa vào firmware model của Raspberry Pi
- chưa phải là board support độc lập hoàn toàn khỏi firmware assumptions của Pi

## 2.5. Wi-Fi / Bluetooth firmware ecosystem

File:

- [conf/machine/darkdragon-rpi3.conf](/home/ddragon/yocto/meta-myproject_rpi/conf/machine/darkdragon-rpi3.conf:27)

Các package đang dùng:

- `linux-firmware-rpidistro-bcm43430`
- `linux-firmware-rpidistro-bcm43455`
- `bluez-firmware-rpidistro-bcm43430a1-hcd`
- `bluez-firmware-rpidistro-bcm4345c0-hcd`

Ý nghĩa:

- naming và packaging của firmware vẫn theo hệ sinh thái Raspberry Pi

## 2.6. Layer source trong kas

File:

- [manifests/kas.yml](/home/ddragon/yocto/meta-myproject_rpi/manifests/kas.yml:26)

Hiện tại:

- `meta-raspberrypi` là một layer dependency chính trong manifest

Điều này xác nhận rõ:

- project hiện không phải một BSP độc lập
- project là một product layer nằm trên BSP Raspberry Pi

## 3. Những gì hiện project đang tự sở hữu

## 3.1. Distro policy

File:

- [conf/distro/darkdragon.conf](/home/ddragon/yocto/meta-myproject_rpi/conf/distro/darkdragon.conf:1)

Project đang own:

- `DISTRO_NAME`
- `DISTRO_VERSION`
- `INIT_MANAGER`
- `DISTRO_FEATURES`
- package format

Đây là lớp `product policy`, không phải lớp `BSP`.

## 3.2. Machine override mỏng

File:

- [conf/machine/darkdragon-rpi3.conf](/home/ddragon/yocto/meta-myproject_rpi/conf/machine/darkdragon-rpi3.conf:1)

Project đang own:

- machine name của project
- `MACHINEOVERRIDES`
- `ENABLE_UART`
- `SERIAL_CONSOLES`
- `RPI_KERNEL_DEVICETREE`
- `IMAGE_FSTYPES`
- machine firmware recommendations

Đây là “board identity layer” của project, nhưng vẫn chưa phải full BSP ownership.

## 3.3. Custom DTS wrapper

Files:

- [recipes-kernel/linux/linux-raspberrypi_%.bbappend](/home/ddragon/yocto/meta-myproject_rpi/recipes-kernel/linux/linux-raspberrypi_%.bbappend:1)
- [recipes-kernel/linux/files/darkdragon-rpi3.dts](/home/ddragon/yocto/meta-myproject_rpi/recipes-kernel/linux/files/darkdragon-rpi3.dts:1)

Project đang own:

- tên DTB riêng
- lớp board DTS cuối cùng
- những override phần cứng riêng của board

Nhưng project vẫn chưa own toàn bộ chuỗi DTS phía dưới.

## 3.4. Image / packagegroup / app / service

Files:

- [recipes-core/images/darkdragon-image.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-core/images/darkdragon-image.bb:1)
- [recipes-core/images/darkdragon-dev-image.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-core/images/darkdragon-dev-image.bb:1)
- [recipes-core/packagegroups/packagegroup-darkdragon-base.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-core/packagegroups/packagegroup-darkdragon-base.bb:1)
- [recipes-core/packagegroups/packagegroup-darkdragon-dev.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-core/packagegroups/packagegroup-darkdragon-dev.bb:1)
- [recipes-myapp/myproject-app/myproject-app.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-myapp/myproject-app/myproject-app.bb:1)
- [recipes-myapp/myproject-app/files/myproject-app.service](/home/ddragon/yocto/meta-myproject_rpi/recipes-myapp/myproject-app/files/myproject-app.service:1)
- [recipes-support/darkdragon-release/darkdragon-release.bb](/home/ddragon/yocto/meta-myproject_rpi/recipes-support/darkdragon-release/darkdragon-release.bb:1)

Đây là phần project đang own hoàn toàn.

## 4. Những gì chưa có, nhưng sẽ cần nếu board custom đi xa hơn

Nếu board thực tế khác Raspberry Pi 3 reference board ở mức đáng kể, project nên dần own thêm các phần sau:

## 4.1. Board DTS không phụ thuộc mạnh vào Pi board DTS

Hiện tại:

- DTS đang include nhiều fragment rất đặc thù Raspberry Pi board

Về lâu dài nên:

- chỉ reuse SoC-level include cần thiết
- tách board wiring riêng của project vào DTS/DTSI của chính project

Ví dụ:

- nếu Ethernet, Wi-Fi, Bluetooth, camera, LED, power rail, GPIO expander khác
- thì không nên tiếp tục include nguyên fragment từ board reference cũ

## 4.2. Kernel config hoặc fragment riêng

Hiện tại:

- [conf/machine/darkdragon-rpi3.conf](/home/ddragon/yocto/meta-myproject_rpi/conf/machine/darkdragon-rpi3.conf:19) vẫn dùng `bcm2709_defconfig`

Nếu board custom cần:

- driver riêng
- policy module khác
- debug feature khác

thì nên thêm:

- kernel fragment
- hoặc defconfig riêng

## 4.3. Bootloader / firmware / boot files riêng

Hiện tại:

- project chưa own phần bootloader recipe
- chưa own phần firmware config riêng kiểu board product

Nếu board thay đổi ở:

- boot chain
- boot medium
- firmware config
- secure boot
- boot partition contents

thì cần thêm:

- `recipes-bsp/`
- `u-boot` bbappend hoặc recipe riêng
- file boot config tương ứng

## 4.4. WIC layout riêng

Hiện tại:

- machine chỉ giữ `IMAGE_FSTYPES = "wic.bz2"`
- project chưa own một `.wks` riêng

Nếu sản phẩm cần:

- layout phân vùng cố định
- boot partition riêng
- data partition riêng
- A/B update

thì nên thêm:

- `wic/<board>.wks`
- mapping `WKS_FILE` ở machine

## 4.5. Connectivity / support recipes riêng

Hiện tại:

- `recipes-connectivity/` và `recipes-support/` gần như còn trống

Nếu sản phẩm thực tế cần:

- Wi-Fi provisioning
- Bluetooth policy
- network manager config
- health monitor
- watchdog
- update agent

thì nên đưa vào đúng nhóm recipe tương ứng thay vì để dồn hết trong image/packagegroup.

## 5. Khi nào mô hình hiện tại là đủ tốt

Mô hình hiện tại là đủ tốt nếu:

- board gần giống Raspberry Pi 3 Model B
- vẫn dùng kernel/BSP Raspberry Pi mà không phải patch lớn
- mục tiêu là có image ổn định, maintainable, dễ bring-up
- muốn tập trung vào product software trước

Trong trường hợp này, reuse `meta-raspberrypi` là quyết định đúng.

## 6. Khi nào cần tách mạnh hơn khỏi Raspberry Pi BSP

Nên tách mạnh hơn nếu:

- DTB khác nhiều so với Pi 3 reference
- Wi-Fi/Bluetooth wiring khác
- PMIC / regulator / LEDs / buttons / GPIO mapping khác nhiều
- không còn dùng firmware assumptions kiểu `expgpio`
- cần boot flow khác
- cần kernel config và patch set riêng dài hạn
- cần kiểm soát chặt artifact boot/image cho sản phẩm

Lúc đó project nên tiến dần đến mô hình:

- BSP layer vendor/community lo SoC
- project layer own board support thật sự
- distro/image layer own product policy

## 7. Áp vào repo hiện tại

### Phần đang là “Raspberry Pi BSP”

- machine base `raspberrypi3.conf`
- kernel recipe `linux-raspberrypi`
- nhiều DTS family include
- firmware-backed GPIO model
- firmware package naming cho Wi-Fi/Bluetooth

### Phần đang là “Project-owned”

- distro `darkdragon`
- machine name `darkdragon-rpi3`
- DTS wrapper `darkdragon-rpi3.dts`
- image `darkdragon-image`, `darkdragon-dev-image`
- packagegroups
- app/service
- release identity

### Đánh giá thực tế

Repo hiện tại đang ở trạng thái:

- **tốt cho project product layer**
- **ổn cho bring-up / dev**
- **chưa phải full custom BSP ownership**

Đây là trạng thái hợp lý cho giai đoạn hiện tại.

## 8. Hướng tiến hóa khuyến nghị

Thứ tự thực dụng nên là:

1. giữ reuse `meta-raspberrypi` để build ổn định
2. hoàn thiện DTS riêng của project
3. thêm kernel fragment nếu cần
4. thêm WIC layout riêng nếu sản phẩm cần
5. tách dần các phần boot/config/firmware riêng
6. chỉ tách sâu khỏi BSP Raspberry Pi khi thật sự có khác biệt phần cứng hoặc yêu cầu maintain dài hạn

Nói ngắn gọn:

- **đừng tách quá sớm chỉ vì “muốn sạch”**
- **chỉ own phần nào khi project thực sự phải own phần đó**
