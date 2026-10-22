const prisma = require("../../lib/prisma")
const AppError = require("../../errors/AppError")

// Công thức Haversine tính khoảng cách giữa 2 tọa độ GPS (mét)
const calculateDistanceMeters = (lat1, lon1, lat2, lon2) => {
  const R = 6371e3 // Bán kính trái đất (mét)
  const phi1 = (lat1 * Math.PI) / 180
  const phi2 = (lat2 * Math.PI) / 180
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180

  const a =
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

  return R * c
}

const reportLocation = async ({ user, data }) => {
  const { deviceId, latitude, longitude, accuracy, altitude, speed, recordedAt } = data

  const device = await prisma.device.findUnique({
    where: { id: deviceId },
    include: {
      childProfile: {
        include: {
          safeZones: {
            where: { isActive: true },
          },
        },
      },
    },
  })

  if (!device) {
    throw new AppError("Không tìm thấy thiết bị", 404)
  }

  // Nếu user là CHILD, kiểm tra thiết bị có thuộc về quyền của mình không
  if (user && user.role === "CHILD" && user.deviceId && user.deviceId !== deviceId) {
    throw new AppError("Bạn không có quyền báo cáo vị trí cho thiết bị này", 403)
  }

  // 1. Lưu bản ghi vị trí GPS
  const recordTime = recordedAt ? new Date(recordedAt) : new Date()
  const locationRecord = await prisma.locationRecord.create({
    data: {
      deviceId,
      latitude,
      longitude,
      accuracy: accuracy || null,
      altitude: altitude || null,
      speed: speed || null,
      recordedAt: recordTime,
    },
  })

  // 2. Cập nhật lastSeenAt và trạng thái thiết bị
  await prisma.device.update({
    where: { id: deviceId },
    data: {
      lastSeenAt: new Date(),
      status: "ACTIVE",
    },
  })

  // 3. Kiểm tra vi phạm vùng an toàn (Safe Zone Geofencing)
  const safeZones = device.childProfile?.safeZones || []
  let alertTriggered = false
  const triggeredZones = []

  for (const zone of safeZones) {
    const distance = calculateDistanceMeters(latitude, longitude, zone.latitude, zone.longitude)

    if (distance > zone.radius) {
      alertTriggered = true
      triggeredZones.push({
        zoneName: zone.name,
        distanceMeters: Math.round(distance),
        radius: zone.radius,
      })

      // Kiểm tra tránh spam cảnh báo: nếu đã có cảnh báo SAFE_ZONE_EXIT trong vòng 10 phút gần đây thì không gửi lại liên tục
      const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000)
      const existingAlert = await prisma.alert.findFirst({
        where: {
          recipientId: device.childProfile.parentId,
          deviceId: device.id,
          type: "SAFE_ZONE_EXIT",
          createdAt: { gte: tenMinutesAgo },
        },
      })

      if (!existingAlert) {
        await prisma.alert.create({
          data: {
            type: "SAFE_ZONE_EXIT",
            status: "UNREAD",
            title: "Cảnh báo rời vùng an toàn",
            message: `Trẻ ${device.childProfile.name} đã ra ngoài vùng an toàn "${zone.name}" (~${Math.round(distance)}m, bán kính cho phép: ${zone.radius}m).`,
            recipientId: device.childProfile.parentId,
            deviceId: device.id,
          },
        })
      }
    }
  }

  return {
    location: locationRecord,
    alertTriggered,
    triggeredZones,
  }
}

const getLatestLocation = async ({ deviceId, user }) => {
  const device = await prisma.device.findUnique({
    where: { id: deviceId },
    include: {
      childProfile: true,
      locations: {
        take: 1,
        orderBy: { recordedAt: "desc" },
      },
    },
  })

  if (!device) {
    throw new AppError("Không tìm thấy thiết bị", 404)
  }

  if (user.role === "PARENT" && device.childProfile.parentId !== user.id) {
    throw new AppError("Bạn không có quyền truy cập vị trí của thiết bị này", 403)
  }

  const latestLocation = device.locations[0] || null

  return {
    device: {
      id: device.id,
      name: device.name,
      platform: device.platform,
      status: device.status,
      lastSeenAt: device.lastSeenAt,
      childName: device.childProfile.name,
    },
    latestLocation,
  }
}

const getLocationHistory = async ({ deviceId, user, query = {} }) => {
  const { limit = 50, startTime, endTime } = query

  const device = await prisma.device.findUnique({
    where: { id: deviceId },
    include: { childProfile: true },
  })

  if (!device) {
    throw new AppError("Không tìm thấy thiết bị", 404)
  }

  if (user.role === "PARENT" && device.childProfile.parentId !== user.id) {
    throw new AppError("Bạn không có quyền truy cập lịch sử vị trí của thiết bị này", 403)
  }

  const where = { deviceId }
  if (startTime || endTime) {
    where.recordedAt = {}
    if (startTime) where.recordedAt.gte = new Date(startTime)
    if (endTime) where.recordedAt.lte = new Date(endTime)
  }

  const history = await prisma.locationRecord.findMany({
    where,
    orderBy: { recordedAt: "desc" },
    take: limit,
  })

  return {
    deviceId,
    totalRecords: history.length,
    history,
  }
}

module.exports = {
  calculateDistanceMeters,
  reportLocation,
  getLatestLocation,
  getLocationHistory,
}
