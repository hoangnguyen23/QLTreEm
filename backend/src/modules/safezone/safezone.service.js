const prisma = require("../../lib/prisma")
const AppError = require("../../errors/AppError")

const createSafeZone = async ({ parentId, data }) => {
  const child = await prisma.childProfile.findUnique({
    where: { id: data.childProfileId },
  })

  if (!child) {
    throw new AppError("Không tìm thấy hồ sơ trẻ", 404)
  }

  if (child.parentId !== parentId) {
    throw new AppError("Bạn không có quyền thêm vùng an toàn cho hồ sơ này", 403)
  }

  return prisma.safeZone.create({
    data: {
      name: data.name,
      latitude: data.latitude,
      longitude: data.longitude,
      radius: data.radius,
      childProfileId: data.childProfileId,
    },
    include: {
      childProfile: {
        select: { id: true, name: true },
      },
    },
  })
}

const getSafeZones = async ({ user, query = {} }) => {
  const where = {}

  if (user.role === "PARENT") {
    where.childProfile = { parentId: user.id }
  }

  if (query.childProfileId) {
    where.childProfileId = query.childProfileId
  }

  return prisma.safeZone.findMany({
    where,
    orderBy: { createdAt: "desc" },
    include: {
      childProfile: {
        select: { id: true, name: true, parentId: true },
      },
    },
  })
}

const getSafeZoneById = async ({ id, user }) => {
  const safeZone = await prisma.safeZone.findUnique({
    where: { id },
    include: {
      childProfile: {
        select: { id: true, name: true, parentId: true },
      },
    },
  })

  if (!safeZone) {
    throw new AppError("Không tìm thấy vùng an toàn", 404)
  }

  if (user.role === "PARENT" && safeZone.childProfile.parentId !== user.id) {
    throw new AppError("Bạn không có quyền truy cập vùng an toàn này", 403)
  }

  return safeZone
}

const updateSafeZone = async ({ id, user, data }) => {
  const safeZone = await prisma.safeZone.findUnique({
    where: { id },
    include: { childProfile: true },
  })

  if (!safeZone) {
    throw new AppError("Không tìm thấy vùng an toàn", 404)
  }

  if (user.role === "PARENT" && safeZone.childProfile.parentId !== user.id) {
    throw new AppError("Bạn không có quyền chỉnh sửa vùng an toàn này", 403)
  }

  const updateData = {}
  if (data.name !== undefined) updateData.name = data.name
  if (data.latitude !== undefined) updateData.latitude = data.latitude
  if (data.longitude !== undefined) updateData.longitude = data.longitude
  if (data.radius !== undefined) updateData.radius = data.radius
  if (data.isActive !== undefined) updateData.isActive = data.isActive

  return prisma.safeZone.update({
    where: { id },
    data: updateData,
    include: {
      childProfile: {
        select: { id: true, name: true },
      },
    },
  })
}

const deleteSafeZone = async ({ id, user }) => {
  const safeZone = await prisma.safeZone.findUnique({
    where: { id },
    include: { childProfile: true },
  })

  if (!safeZone) {
    throw new AppError("Không tìm thấy vùng an toàn", 404)
  }

  if (user.role === "PARENT" && safeZone.childProfile.parentId !== user.id) {
    throw new AppError("Bạn không có quyền xóa vùng an toàn này", 403)
  }

  await prisma.safeZone.delete({
    where: { id },
  })

  return { message: "Xóa vùng an toàn thành công" }
}

module.exports = {
  createSafeZone,
  getSafeZones,
  getSafeZoneById,
  updateSafeZone,
  deleteSafeZone,
}
