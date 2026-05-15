
# Wumpus World - Tác tử thông minh bằng Prolog

## 📖 Giới thiệu

Đây là chương trình mô phỏng **thế giới Wumpus** (Wumpus World) – một bài toán kinh điển trong trí tuệ nhân tạo. Tác tử (agent) của chúng ta di chuyển trong hang động 4×4, tìm vàng và quay trở về điểm xuất phát (1,1) một cách an toàn.

Thế giới được **sinh ngẫu nhiên mỗi lần chạy**, bao gồm:
- 1 con **Wumpus** (quái vật)
- 3 cái **hố** (pits)
- 1 thỏi **vàng** (gold)

Tác tử có khả năng:
- Cảm nhận mùi hôi thối (stench) khi ở cạnh Wumpus.
- Cảm nhận gió (breeze) khi ở cạnh hố.
- Phát hiện vàng lấp lánh (glitter) khi đứng trên ô chứa vàng.
- Cầm theo một mũi tên để bắn giết Wumpus.

## 🧠 Chiến lược của tác tử

Chương trình sử dụng kiến trúc **vòng lặp cảm nhận – suy nghĩ – hành động** (sense–think–act loop) kết hợp với các kỹ thuật AI cổ điển:

- **Lập kế hoạch đường đi BFS**: Tìm đường đi tối ưu (ngắn nhất) đến một ô đích an toàn bằng thuật toán tìm kiếm theo chiều rộng trên đồ thị trạng thái (vị trí + hướng).
- **Khám phá có mục tiêu**: Luôn tìm đường đến các ô **an toàn chưa thăm** để mở rộng bản đồ, ưu tiên nhặt vàng khi phát hiện.
- **Quay về tổ**: Sau khi có vàng, tính toán đường về (1,1) nhanh nhất có thể.
- **Tiêu diệt Wumpus**: Nếu còn tên và phát hiện Wumpus ở ô ngay trước mặt, tác tử sẽ bắn.

Toàn bộ hành vi được quyết định bởi hệ thống luật trong `ask_action/1`:
1. Nếu đang ở (1,1) và có vàng → `climb` (thoát hang).
2. Nếu đứng trên vàng → `grab` (nhặt).
3. Nếu đối diện Wumpus và còn tên → `shoot` (bắn).
4. Nếu đã có vàng → tìm đường về (1,1) bằng BFS.
5. Nếu chưa có vàng → tìm đường đến một ô chưa thăm an toàn (có thể đến được) bằng BFS, chọn ngẫu nhiên trong số các đường đi khả thi.
6. Nếu không còn đường nào → thông báo bế tắc và dừng.

## ⚙️ Yêu cầu hệ thống

- **SWI-Prolog** (phiên bản 8.x trở lên).
- Thư viện `random` và `lists` (đã có sẵn trong SWI-Prolog).

## 🚀 Cách chạy

1. Tải file `wumpus.pl` về máy.
2. Mở SWI-Prolog, nạp chương trình:
   ```prolog
   ?- [wumpus].
   ```
3. Bắt đầu một ván mới:
   ```prolog
   ?- run.
   ```
   Chương trình sẽ in ra từng bước đi, vị trí, hướng, và hành động của tác tử cho đến khi thắng, thua hoặc vượt quá 100 bước.

## 📁 Cấu trúc mã nguồn

| Phần | Mô tả |
|------|-------|
| `generate_random_world/0` | Sinh ngẫu nhiên Wumpus, vàng và 3 hố trên bản đồ 4×4. |
| `percept/1` | Tính toán các cảm nhận tại vị trí hiện tại (mùi, gió, lấp lánh). |
| `tell_kb/1` | Cập nhật cơ sở tri thức (`visited`, `sensed_stench`, `sensed_breeze`). |
| `safe/2` | Xác định ô (X,Y) có an toàn không (không hố, không Wumpus). |
| `next_position/5` | Tính toạ độ ô kế tiếp theo hướng hiện tại. |
| `turn_left_dir/2`, `turn_right_dir/2` | Các quan hệ chuyển hướng. |
| `execute/1` | Thực thi hành động (forward, turn_left, turn_right, grab, climb, shoot). |
| `plan_path/3` | Tìm đường BFS từ vị trí/hướng hiện tại đến một ô đích. |
| `bfs_queue/4` | Hàng đợi BFS có kiểm soát trạng thái đã duyệt để tránh lặp vô hạn. |
| `neighbor_state/2` | Tạo trạng thái kế tiếp cho BFS (forward, xoay trái, xoay phải). |
| `ask_action/1` | Quyết định hành động tiếp theo dựa trên chiến lược thông minh. |
| `run/0` và `agent_loop/1` | Vòng lặp chính: cảm nhận → quyết định → hành động → kiểm tra kết thúc. |

## 📊 Ví dụ kết quả chạy

```
Step: 0 | Pos: (1,1) | Facing: east | Action: turn_left
Step: 1 | Pos: (1,1) | Facing: north | Action: forward
Step: 2 | Pos: (1,2) | Facing: north | Action: turn_right
Step: 3 | Pos: (1,2) | Facing: east | Action: forward
...
Step: 19 | Pos: (4,4) | Facing: east | Action: grab
...
Step: 28 | Pos: (1,2) | Facing: south | Action: forward
*** WIN! +1000 ***
```

Tác tử khám phá, bắn chết Wumpus, nhặt vàng và trở về thành công chỉ trong 29 bước.

## 📝 Ghi chú

- Tác tử hiện tại **biết trước toàn bộ vị trí hố và Wumpus** để xác định ô an toàn (phục vụ mục đích minh hoạ). Có thể nâng cấp lên suy luận xác suất để tác tử tự khám phá môi trường.
- BFS được giới hạn trong không gian trạng thái 4×4×4 = 64 trạng thái, đảm bảo hiệu năng.
- Số bước tối đa mặc định là 100, có thể tuỳ chỉnh trong `agent_loop/1`.

## 📚 Tài liệu tham khảo

- Stuart Russell, Peter Norvig. *Artificial Intelligence: A Modern Approach* (Chapter 7 – Logical Agents).
- SWI-Prolog Documentation: https://www.swi-prolog.org/

---
