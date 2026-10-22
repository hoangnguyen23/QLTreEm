const crypto = require("crypto")
const jwt = require("jsonwebtoken")
const prisma = require("../../lib/prisma")
const AppError = require("../../errors/AppError")

const hashToken = (token) => {
  return crypto.createHash("sha256").update(token).digest("hex")
}

const generatePairing = async ({ parentId, childProfileId }) => {
  const child = await prisma.childProfile.findUnique({
    where: { id: childProfileId },
  })

  if (!child) {
    throw new AppError("Không tìm thấy hồ sơ trẻ", 404)
  }

  if (child.parentId !== parentId) {
    throw new AppError("Bạn không có quyền tạo ghép nối cho hồ sơ này", 403)
  }

  // Hủy các mã ghép nối PENDING trước đó của trẻ này
  await prisma.devicePairing.updateMany({
    where: {
      childProfileId,
      status: "PENDING",
    },
    data: {
      status: "CANCELLED",
    },
  })

  const rawToken = crypto.randomBytes(24).toString("hex")
  const tokenHash = hashToken(rawToken)
  const expiresAt = new Date(Date.now() + 15 * 60 * 1000) // 15 phút

  const pairing = await prisma.devicePairing.create({
    data: {
      tokenHash,
      status: "PENDING",
      expiresAt,
      parentId,
      childProfileId,
    },
  })

  return {
    pairingId: pairing.id,
    token: rawToken,
    expiresAt,
    qrPayload: JSON.stringify({
      pairingId: pairing.id,
      token: rawToken,
      parentId,
      childProfileId,
      childName: child.name,
    }),
  }
}

const getPairingStatus = async ({ id, user }) => {
  const pairing = await prisma.devicePairing.findUnique({
    where: { id },
    include: {
      childProfile: {
        select: { id: true, name: true, parentId: true },
      },
      device: true,
    },
  })

  if (!pairing) {
    throw new AppError("Không tìm thấy phiên ghép nối", 404)
  }

  if (user.role === "PARENT" && pairing.parentId !== user.id) {
    throw new AppError("Bạn không có quyền truy cập phiên ghép nối này", 403)
  }

  // Tự động đánh dấu EXPIRED nếu quá hạn
  if (pairing.status === "PENDING" && pairing.expiresAt <= new Date()) {
    const updated = await prisma.devicePairing.update({
      where: { id },
      data: { status: "EXPIRED" },
      include: {
        childProfile: {
          select: { id: true, name: true },
        },
        device: true,
      },
    })
    return updated
  }

  return pairing
}

const confirmPairing = async ({ token, deviceIdentifier, name, platform, childUserId }) => {
  const tokenHash = hashToken(token)

  const pairing = await prisma.devicePairing.findUnique({
    where: { tokenHash },
    include: {
      childProfile: true,
    },
  })

  if (!pairing) {
    throw new AppError("Mã ghép nối không hợp lệ", 400)
  }

  if (pairing.status !== "PENDING") {
    throw new AppError(`Mã ghép nối đã ở trạng thái ${pairing.status}`, 400)
  }

  if (pairing.expiresAt <= new Date()) {
    await prisma.devicePairing.update({
      where: { id: pairing.id },
      data: { status: "EXPIRED" },
    })
    throw new AppError("Mã ghép nối đã hết hạn", 400)
  }

  if (childUserId) {
    await prisma.childProfile.update({
      where: { id: pairing.childProfileId },
      data: { childUserId },
    })
  }

  // Upsert thiết bị
  let device = await prisma.device.findUnique({
    where: { deviceIdentifier },
  })

  if (device) {
    device = await prisma.device.update({
      where: { id: device.id },
      data: {
        name,
        platform,
        status: "ACTIVE",
        childProfileId: pairing.childProfileId,
        lastSeenAt: new Date(),
      },
    })
  } else {
    device = await prisma.device.create({
      data: {
        name,
        deviceIdentifier,
        platform,
        status: "ACTIVE",
        childProfileId: pairing.childProfileId,
        lastSeenAt: new Date(),
      },
    })
  }

  // Đánh dấu pairing COMPLETED
  await prisma.devicePairing.update({
    where: { id: pairing.id },
    data: {
      status: "COMPLETED",
      usedAt: new Date(),
      deviceId: device.id,
    },
  })

  // Cấp token định danh thiết bị cho thiết bị trẻ
  const accessToken = jwt.sign(
    {
      id: device.id,
      deviceId: device.id,
      childProfileId: pairing.childProfileId,
      name: device.name,
      role: "CHILD",
    },
    process.env.ACCESS_TOKEN_SECRET,
    { expiresIn: "90d" }
  )

  return {
    message: "Ghép nối thiết bị thành công",
    device,
    childProfile: {
      id: pairing.childProfile.id,
      name: pairing.childProfile.name,
    },
    accessToken,
  }
}

module.exports = {
  generatePairing,
  getPairingStatus,
  confirmPairing,
}
