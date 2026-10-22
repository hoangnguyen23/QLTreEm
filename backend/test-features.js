const request = require("supertest")
const app = require("./src/app")
const prisma = require("./src/lib/prisma")
const bcrypt = require("bcryptjs")
const jwt = require("jsonwebtoken")

async function runTests() {
  console.log("=== BẮT ĐẦU KIỂM THỬ HỆ THỐNG QUẢN LÝ ĐIỆN THOẠI TRẺ EM ===")

  try {
    // 0. Chuẩn bị dữ liệu mẫu cho kiểm thử
    const testAdminEmail = `admin_test_${Date.now()}@test.com`
    const testParent1Email = `parent1_${Date.now()}@test.com`
    const testParent2Email = `parent2_${Date.now()}@test.com`
    const defaultPassword = await bcrypt.hash("Password123@", 10)

    // Tạo ADMIN
    const adminUser = await prisma.user.create({
      data: {
        name: "Admin Quản Trị",
        email: testAdminEmail,
        password: defaultPassword,
        role: "ADMIN",
        emailVerified: true,
        isActive: true,
      },
    })
    const adminToken = jwt.sign(
      { id: adminUser.id, name: adminUser.name, role: adminUser.role },
      process.env.ACCESS_TOKEN_SECRET,
      { expiresIn: "1h" }
    )

    // Tạo PARENT 1
    const parent1 = await prisma.user.create({
      data: {
        name: "Phụ Huynh 1",
        email: testParent1Email,
        password: defaultPassword,
        role: "PARENT",
        emailVerified: true,
        isActive: true,
      },
    })
    const parent1Token = jwt.sign(
      { id: parent1.id, name: parent1.name, role: parent1.role },
      process.env.ACCESS_TOKEN_SECRET,
      { expiresIn: "1h" }
    )

    // Tạo PARENT 2 (để kiểm tra phân quyền sở hữu dữ liệu chéo)
    const parent2 = await prisma.user.create({
      data: {
        name: "Phụ Huynh 2",
        email: testParent2Email,
        password: defaultPassword,
        role: "PARENT",
        emailVerified: true,
        isActive: true,
      },
    })
    const parent2Token = jwt.sign(
      { id: parent2.id, name: parent2.name, role: parent2.role },
      process.env.ACCESS_TOKEN_SECRET,
      { expiresIn: "1h" }
    )

    console.log("✓ Tạo tài khoản test thành công (Admin, Parent 1, Parent 2)")

    // 1. KIỂM THỬ ADMIN: Quản lý người dùng
    console.log("\n--- [TEST 1] ADMIN QUẢN LÝ NGƯỜI DÙNG ---")
    const listUsersRes = await request(app)
      .get("/api/users")
      .set("Authorization", `Bearer ${adminToken}`)
    if (listUsersRes.status !== 200 || !listUsersRes.body.data.users) {
      throw new Error(`Admin list users thất bại: ${JSON.stringify(listUsersRes.body)}`)
    }
    console.log(`✓ Admin lấy danh sách người dùng thành công (Tổng: ${listUsersRes.body.data.users.length})`)

    // Kiểm tra PARENT không được vào API Admin
    const parentForbiddenRes = await request(app)
      .get("/api/users")
      .set("Authorization", `Bearer ${parent1Token}`)
    if (parentForbiddenRes.status !== 403) {
      throw new Error(`Bảo mật thất bại: Parent truy cập được API Admin (status ${parentForbiddenRes.status})`)
    }
    console.log("✓ Kiểm tra phân quyền: Parent bị chặn 403 Forbidden khi vào API Admin")

    // 2. KIỂM THỬ PARENT 1: CRUD Hồ sơ trẻ (Child Profile)
    console.log("\n--- [TEST 2] PARENT CRUD HỒ SƠ TRẺ & KIỂM TRA QUYỀN SỞ HỮU ---")
    const createChildRes = await request(app)
      .post("/api/children")
      .set("Authorization", `Bearer ${parent1Token}`)
      .send({
        name: "Bé An",
        dateOfBirth: "2016-05-15",
        notes: "Lớp 3A trường tiểu học",
      })
    if (createChildRes.status !== 201) {
      throw new Error(`Tạo hồ sơ trẻ thất bại: ${JSON.stringify(createChildRes.body)}`)
    }
    const childId = createChildRes.body.data.id
    console.log(`✓ Parent 1 tạo hồ sơ trẻ thành công: ${createChildRes.body.data.name} (ID: ${childId})`)

    // Parent 2 cố tình truy cập hồ sơ của Parent 1 -> Phải nhận 403
    const crossAccessRes = await request(app)
      .get(`/api/children/${childId}`)
      .set("Authorization", `Bearer ${parent2Token}`)
    if (crossAccessRes.status !== 403) {
      throw new Error(`Lỗi quyền sở hữu: Parent 2 truy cập trái phép được trẻ của Parent 1 (status ${crossAccessRes.status})`)
    }
    console.log("✓ Kiểm tra quyền sở hữu: Parent 2 bị chặn 403 khi xem hồ sơ trẻ của Parent 1")

    // 3. KIỂM THỬ QR PAIRING (Ghép nối thiết bị)
    console.log("\n--- [TEST 3] GHÉP NỐI THIẾT BỊ BẰNG QR CODE ---")
    const genPairingRes = await request(app)
      .post("/api/pairings/generate")
      .set("Authorization", `Bearer ${parent1Token}`)
      .send({ childProfileId: childId })
    if (genPairingRes.status !== 201) {
      throw new Error(`Tạo mã QR ghép nối thất bại: ${JSON.stringify(genPairingRes.body)}`)
    }
    const pairingData = genPairingRes.body.data
    console.log(`✓ Parent 1 tạo mã ghép nối QR thành công (Token: ${pairingData.token.substring(0, 10)}...)`)

    // Thiết bị trẻ quét mã QR và gửi confirm
    const deviceIdentifier = `DEV_TEST_${Date.now()}`
    const confirmRes = await request(app)
      .post("/api/pairings/confirm")
      .send({
        token: pairingData.token,
        deviceIdentifier,
        name: "Samsung Galaxy A15 của Bé An",
        platform: "ANDROID",
      })
    if (confirmRes.status !== 200 || !confirmRes.body.data.device) {
      throw new Error(`Ghép nối thiết bị thất bại: ${JSON.stringify(confirmRes.body)}`)
    }
    const deviceId = confirmRes.body.data.device.id
    const childAccessToken = confirmRes.body.data.accessToken
    console.log(`✓ Thiết bị trẻ quét QR ghép nối thành công: ${confirmRes.body.data.device.name} (Device ID: ${deviceId})`)

    // Kiểm tra trạng thái pairing đã chuyển thành COMPLETED
    const checkPairingRes = await request(app)
      .get(`/api/pairings/${pairingData.pairingId}/status`)
      .set("Authorization", `Bearer ${parent1Token}`)
    if (checkPairingRes.body.data.status !== "COMPLETED") {
      throw new Error(`Trạng thái ghép nối không phải COMPLETED: ${checkPairingRes.body.data.status}`)
    }
    console.log("✓ Trạng thái ghép nối tự động cập nhật: COMPLETED")

    // 4. KIỂM THỬ VÙNG AN TOÀN (SafeZone) & GPS TRACKING & TỰ ĐỘNG CẢNH BÁO
    console.log("\n--- [TEST 4] VÙNG AN TOÀN, ĐỊNH VỊ GPS VÀ TỰ ĐỘNG BẮT CẢNH BÁO ---")
    // Tạo vùng an toàn: Trường tiểu học (tọa độ: 10.7769, 106.7009), bán kính 500 mét
    const createSafeZoneRes = await request(app)
      .post("/api/safezones")
      .set("Authorization", `Bearer ${parent1Token}`)
      .send({
        name: "Trường Tiểu Học",
        latitude: 10.7769,
        longitude: 106.7009,
        radius: 500, // 500 mét
        childProfileId: childId,
      })
    if (createSafeZoneRes.status !== 201) {
      throw new Error(`Tạo vùng an toàn thất bại: ${JSON.stringify(createSafeZoneRes.body)}`)
    }
    const safeZoneId = createSafeZoneRes.body.data.id
    console.log(`✓ Parent 1 tạo vùng an toàn thành công: ${createSafeZoneRes.body.data.name} (Bán kính: 500m)`)

    // Tọa độ 1: Trẻ ở trong trường (cách tâm 50 mét)
    const reportInsideRes = await request(app)
      .post("/api/locations")
      .set("Authorization", `Bearer ${childAccessToken}`)
      .send({
        deviceId,
        latitude: 10.7772,
        longitude: 106.7011,
        accuracy: 10,
        speed: 0,
      })
    if (reportInsideRes.status !== 201 || reportInsideRes.body.data.alertTriggered !== false) {
      throw new Error(`Lỗi định vị trong vùng an toàn: ${JSON.stringify(reportInsideRes.body)}`)
    }
    console.log("✓ Trẻ gửi vị trí GPS trong vùng an toàn -> Không kích hoạt cảnh báo")

    // Tọa độ 2: Trẻ đi ra ngoài trường (cách tâm ~3000 mét)
    const reportOutsideRes = await request(app)
      .post("/api/locations")
      .set("Authorization", `Bearer ${childAccessToken}`)
      .send({
        deviceId,
        latitude: 10.7500,
        longitude: 106.6800,
        accuracy: 15,
        speed: 12.5,
      })
    if (reportOutsideRes.status !== 201 || reportOutsideRes.body.data.alertTriggered !== true) {
      throw new Error(`Lỗi: Không phát hiện vi phạm vùng an toàn: ${JSON.stringify(reportOutsideRes.body)}`)
    }
    console.log(`✓ Trẻ đi ra khỏi vùng an toàn (~${reportOutsideRes.body.data.triggeredZones[0]?.distanceMeters}m) -> Tự động kích hoạt CẢNH BÁO!`)

    // Parent xem vị trí mới nhất
    const latestLocRes = await request(app)
      .get(`/api/locations/device/${deviceId}/latest`)
      .set("Authorization", `Bearer ${parent1Token}`)
    if (latestLocRes.status !== 200 || !latestLocRes.body.data.latestLocation) {
      throw new Error(`Lỗi lấy vị trí mới nhất: ${JSON.stringify(latestLocRes.body)}`)
    }
    console.log(`✓ Parent 1 xem vị trí mới nhất của thiết bị thành công (Lat: ${latestLocRes.body.data.latestLocation.latitude}, Lng: ${latestLocRes.body.data.latestLocation.longitude})`)

    // 5. KIỂM THỬ CẢNH BÁO (Alerts)
    console.log("\n--- [TEST 5] QUẢN LÝ CẢNH BÁO ---")
    const alertsRes = await request(app)
      .get("/api/alerts")
      .set("Authorization", `Bearer ${parent1Token}`)
    if (alertsRes.status !== 200 || alertsRes.body.data.alerts.length === 0) {
      throw new Error(`Không tìm thấy cảnh báo vừa tạo: ${JSON.stringify(alertsRes.body)}`)
    }
    const alertItem = alertsRes.body.data.alerts[0]
    console.log(`✓ Parent 1 nhận được cảnh báo: "${alertItem.title}" - Trạng thái: ${alertItem.status}`)

    // Đánh dấu cảnh báo đã đọc
    const readAlertRes = await request(app)
      .patch(`/api/alerts/${alertItem.id}/read`)
      .set("Authorization", `Bearer ${parent1Token}`)
    if (readAlertRes.body.data.status !== "READ") {
      throw new Error("Lỗi cập nhật cảnh báo READ")
    }
    console.log("✓ Parent 1 đánh dấu cảnh báo ĐÃ ĐỌC (READ) thành công")

    // 6. KIỂM THỬ ĐĂNG NHẬP VÂN TAY (Biometric Login)
    console.log("\n--- [TEST 6] ĐĂNG NHẬP VÂN TAY / SINH TRẮC HỌC ---")
    // Bật xác thực sinh trắc học
    const enableBioRes = await request(app)
      .post("/api/biometric/enable")
      .set("Authorization", `Bearer ${parent1Token}`)
    if (enableBioRes.status !== 200 || !enableBioRes.body.biometricToken) {
      throw new Error(`Bật sinh trắc học thất bại: ${JSON.stringify(enableBioRes.body)}`)
    }
    const bioToken = enableBioRes.body.biometricToken
    console.log("✓ Kích hoạt xác thực sinh trắc học thành công")

    // Kiểm tra trạng thái
    const bioStatusRes = await request(app)
      .get("/api/biometric/status")
      .set("Authorization", `Bearer ${parent1Token}`)
    if (bioStatusRes.body.data.enabled !== true) {
      throw new Error("Trạng thái sinh trắc học không phải true")
    }
    console.log("✓ Kiểm tra trạng thái vân tay: ĐÃ BẬT (enabled = true)")

    // Đăng nhập bằng vân tay (sử dụng biometric token từ thiết bị)
    const bioLoginRes = await request(app)
      .post("/api/biometric/login")
      .send({ biometricToken: bioToken })
    if (bioLoginRes.status !== 200 || !bioLoginRes.body.data.accessToken) {
      throw new Error(`Đăng nhập vân tay thất bại: ${JSON.stringify(bioLoginRes.body)}`)
    }
    console.log(`✓ Đăng nhập bằng vân tay thành công! Nhận Access Token cho user: ${bioLoginRes.body.data.user.name} (Role: ${bioLoginRes.body.data.user.role})`)

    // Dọn dẹp dữ liệu test
    await prisma.user.deleteMany({
      where: {
        id: { in: [adminUser.id, parent1.id, parent2.id] },
      },
    })
    console.log("\n✓ Đã dọn dẹp dữ liệu kiểm thử sạch sẽ.")

    console.log("\n=======================================================")
    console.log(" TẤT CẢ CÁC KIỂM THỬ ĐÃ VƯỢT QUA XUẤT SẮC 100%!")
    console.log("=======================================================")
    process.exit(0)
  } catch (error) {
    console.error("\n❌ KIỂM THỬ THẤT BẠI:", error)
    process.exit(1)
  }
}

runTests()
