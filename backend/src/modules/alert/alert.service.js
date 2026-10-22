const prisma = require("../../lib/prisma")
const AppError = require("../../errors/AppError")

const getAlerts = async ({ user, query = {} }) => {
  const { status, type, page = 1, limit = 50, childId } = query

  const where = {}
  if (user.role === "PARENT") {
    where.recipientId = user.id
  } else if (user.role === "CHILD") {
    const childProfile = await prisma.childProfile.findFirst({
      where: { childUserId: user.id },
      include: { devices: { select: { id: true } } },
    })
    const devIds = childProfile?.devices?.map((d) => d.id) || []
    where.OR = [
      { recipientId: user.id },
      ...(childProfile ? [{ recipientId: childProfile.parentId }] : []),
      ...(devIds.length > 0 ? [{ deviceId: { in: devIds } }] : []),
    ]
  }

  if (status) {
    where.status = status
  }
  if (type) {
    where.type = type
  }
  if (childId) {
    where.device = { childProfileId: childId }
  }

  const [alerts, total, unreadCount] = await Promise.all([
    prisma.alert.findMany({
      where,
      orderBy: { createdAt: "desc" },
      skip: (page - 1) * limit,
      take: limit,
      include: {
        device: {
          select: {
            id: true,
            name: true,
            childProfile: {
              select: { id: true, name: true },
            },
          },
        },
      },
    }),
    prisma.alert.count({ where }),
    prisma.alert.count({
      where: {
        ...where,
        status: "UNREAD",
      },
    }),
  ])

  return {
    alerts,
    unreadCount,
    pagination: {
      total,
      page: Number(page),
      limit: Number(limit),
      totalPages: Math.ceil(total / limit),
    },
  }
}

const triggerSos = async ({ user, data = {} }) => {
  let childProfile = await prisma.childProfile.findFirst({
    where: { childUserId: user.id },
    include: { parent: true, devices: true },
  })

  if (!childProfile && user.childProfileId) {
    childProfile = await prisma.childProfile.findUnique({
      where: { id: user.childProfileId },
      include: { parent: true, devices: true },
    })
  }

  let parentId = childProfile?.parentId
  if (!parentId) {
    const defaultParent = await prisma.user.findFirst({ where: { role: "PARENT" } })
    parentId = defaultParent?.id
  }

  if (!parentId) {
    throw new AppError("Chưa có phụ huynh nào trong hệ thống để nhận tín hiệu SOS", 400)
  }

  const childName = childProfile?.name || user.name || "Bé"
  const deviceId = data.deviceId || user.deviceId || childProfile?.devices?.[0]?.id || null

  const alert = await prisma.alert.create({
    data: {
      type: "OTHER",
      status: "UNREAD",
      title: "🆘 CẢNH BÁO SOS KHẨN CẤP",
      message: `Bé "${childName}" đã nhấn nút báo động SOS khẩn cấp! Vui lòng liên hệ hoặc kiểm tra vị trí của con ngay.`,
      recipientId: parentId,
      deviceId,
    },
  })

  return alert
}

const markAlertRead = async ({ id, user }) => {
  const alert = await prisma.alert.findUnique({
    where: { id },
  })

  if (!alert) {
    throw new AppError("Không tìm thấy cảnh báo", 404)
  }

  if (user.role === "PARENT" && alert.recipientId !== user.id) {
    throw new AppError("Bạn không có quyền truy cập cảnh báo này", 403)
  }

  return prisma.alert.update({
    where: { id },
    data: {
      status: "READ",
      readAt: new Date(),
    },
  })
}

const markAlertResolved = async ({ id, user }) => {
  const alert = await prisma.alert.findUnique({
    where: { id },
  })

  if (!alert) {
    throw new AppError("Không tìm thấy cảnh báo", 404)
  }

  if (user.role === "PARENT" && alert.recipientId !== user.id) {
    throw new AppError("Bạn không có quyền truy cập cảnh báo này", 403)
  }

  return prisma.alert.update({
    where: { id },
    data: {
      status: "RESOLVED",
      resolvedAt: new Date(),
    },
  })
}

const deleteAlert = async ({ id, user }) => {
  const alert = await prisma.alert.findUnique({
    where: { id },
  })

  if (!alert) {
    throw new AppError("Không tìm thấy cảnh báo", 404)
  }

  if (user.role === "PARENT" && alert.recipientId !== user.id) {
    throw new AppError("Bạn không có quyền xóa cảnh báo này", 403)
  }

  await prisma.alert.delete({
    where: { id },
  })

  return { message: "Xóa cảnh báo thành công" }
}

module.exports = {
  getAlerts,
  triggerSos,
  markAlertRead,
  markAlertResolved,
  deleteAlert,
}
