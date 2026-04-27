# Hướng Dẫn Flash Image Ra Thẻ SD

File `flash_rpi_sd.sh` dùng để ghi image `.wic` đã build ra thẻ SD cho Raspberry Pi.

## 1. Build image trước

Trước khi flash, cần có file `.wic` trong thư mục `output` của project:

```bash
./build_rpi_image.sh
```

Sau khi build xong, kiểm tra:

```bash
ls -lh output/*.wic
```

Ví dụ output:

```text
output/myproject-rpi-image-raspberrypi3-20260426153512.rootfs.wic
```

## 2. Cắm thẻ SD và xác định đúng device

Cắm thẻ SD vào máy build, sau đó chạy:

```bash
lsblk -o NAME,TYPE,SIZE,MODEL,TRAN,MOUNTPOINTS
```

Ví dụ:

```text
NAME   TYPE  SIZE MODEL           TRAN MOUNTPOINTS
sda    disk 29.7G USB SD Reader   usb
├─sda1 part  256M
└─sda2 part 29.4G
nvme0n1 disk 477G SSD
```

Trong ví dụ này, device cần flash là:

```text
/dev/sda
```

Chú ý chọn **whole disk**, không chọn partition:

- Đúng: `/dev/sda`, `/dev/sdb`, `/dev/mmcblk0`
- Sai: `/dev/sda1`, `/dev/sdb2`, `/dev/mmcblk0p1`

## 3. Chạy script flash

Chạy từ thư mục project:

```bash
sudo ./flash_rpi_sd.sh
```

Script sẽ:

- Tìm file `.wic` mới nhất trong `output/`.
- Hiển thị danh sách block device.
- Hỏi device cần flash.
- Yêu cầu gõ chính xác `YES`.
- Unmount các partition của thẻ SD.
- Ghi image bằng `dd`.
- Chạy `sync` trước khi kết thúc.

Nếu muốn đổi device mặc định:

```bash
sudo DEFAULT_DEVICE=/dev/sdb ./flash_rpi_sd.sh
```

## 4. Những điểm cần chú ý

- Flash sẽ xóa toàn bộ dữ liệu trên device đã chọn.
- Luôn kiểm tra kỹ output của `lsblk` trước khi nhập device.
- Không nhập partition như `/dev/sda1`; phải nhập whole disk như `/dev/sda`.
- Không rút thẻ SD khi `dd` đang chạy.
- Chỉ rút thẻ SD sau khi script báo flash xong.
- Script tự chọn file `.wic` mới nhất trong `output/`; nếu có nhiều image cũ, hãy xóa file không cần dùng để tránh nhầm.
- Script có kiểm tra để tránh ghi vào ổ hệ thống hiện tại, nhưng vẫn cần tự kiểm tra device bằng `lsblk`.

## 5. Boot Raspberry Pi

Sau khi flash xong:

1. Rút thẻ SD an toàn khỏi máy build.
2. Cắm thẻ SD vào Raspberry Pi.
3. Cấp nguồn cho board.
4. Nếu image bật SSH, tìm IP của board rồi SSH vào thiết bị.

Với cấu hình hiện tại, image project dùng `debug-tweaks` và `ssh-server-openssh`, phù hợp cho môi trường phát triển.
