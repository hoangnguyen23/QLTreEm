const prisma = require("../../lib/prisma")
const AppError = require("../../errors/AppError")

const getDevices = async ({ user }) => {
  const where = {}
  if (user.role === "PARENT") {
    where.childProfile = { parentId: user.id }
  }

  return prisma.device.findMany({
    where,
    orderBy: { updatedAt: "desc" },
    include: {
      childProfile: {
        select: {
          id: true,
          name: true,
          avatarUrl: true,
          parentId: true,
        },
      },
      locations: {
        take: 1,
        orderBy: { recordedAt: "desc" },
      },
    },
  })
}

const getDeviceById = async ({ id, user }) => {
  const device = await prisma.device.findUnique({
    where: { id },
    include: {
      childProfile: {
        select: {
          id: true,
          name: true,
          avatarUrl: true,
          parentId: true,
        },
      },
      locations: {
        take: 10,
        orderBy: { recordedAt: "desc" },
      },
      alerts: {
        take: 5,
        orderBy: { createdAt: "desc" },
      },
    },
  })

  if (!device) {
    throw new AppError("Không tìm thấy thiết bị", 404)
  }

  if (user.role === "PARENT" && device.childProfile.parentId !== user.id) {
    throw new AppError("Bạn không có quyền truy cập thiết bị này", 403)
  }

  return device
}

const updateDevice = async ({ id, user, data }) => {
  const device = await prisma.device.findUnique({
    where: { id },
    include: { childProfile: true },
  })

  if (!device) {
    throw new AppError("Không tìm thấy thiết bị", 404)
  }

  if (user.role === "PARENT" && device.childProfile.parentId !== user.id) {
    throw new AppError("Bạn không có quyền chỉnh sửa thiết bị này", 403)
  }

  const updateData = {}
  if (data.name !== undefined) updateData.name = data.name
  if (data.status !== undefined) updateData.status = data.status
  if (data.isActive !== undefined) updateData.isActive = data.isActive

  return prisma.device.update({
    where: { id },
    data: updateData,
    include: {
      childProfile: {
        select: { id: true, name: true },
      },
    },
  })
}

const deleteDevice = async ({ id, user }) => {
  const device = await prisma.device.findUnique({
    where: { id },
    include: { childProfile: true },
  })

  if (!device) {
    throw new AppError("Không tìm thấy thiết bị", 404)
  }

  if (user.role === "PARENT" && device.childProfile.parentId !== user.id) {
    throw new AppError("Bạn không có quyền xóa thiết bị này", 403)
  }

  await prisma.device.delete({
    where: { id },
  })

  return { message: "Xóa thiết bị thành công" }
}

module.exports = {
  getDevices,
  getDeviceById,
  updateDevice,
  deleteDevice,
}
