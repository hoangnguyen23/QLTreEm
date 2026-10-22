const prisma = require("../../lib/prisma")
const AppError = require("../../errors/AppError")

const createChild = async ({ parentId, data }) => {
  let childUserId = null
  if (data.childEmail && data.childEmail.trim().length > 0) {
    const childUser = await prisma.user.findUnique({
      where: { email: data.childEmail.trim().toLowerCase() },
    })
    if (!childUser) {
      throw new AppError("Không tìm thấy tài khoản con với email này", 404)
    }
    childUserId = childUser.id
  }

  return prisma.childProfile.create({
    data: {
      name: data.name,
      dateOfBirth: data.dateOfBirth ? new Date(data.dateOfBirth) : null,
      avatarUrl: data.avatarUrl || null,
      notes: data.notes || null,
      parentId,
      childUserId,
    },
    include: {
      devices: true,
      safeZones: true,
      childUser: {
        select: { id: true, name: true, email: true },
      },
    },
  })
}

const getChildren = async ({ user }) => {
  const where = {}
  if (user.role === "PARENT") {
    where.parentId = user.id
  } else if (user.role === "CHILD") {
    where.childUserId = user.id
  }
  // ADMIN can view all

  return prisma.childProfile.findMany({
    where,
    orderBy: { createdAt: "desc" },
    include: {
      childUser: {
        select: { id: true, name: true, email: true },
      },
      devices: {
        select: {
          id: true,
          name: true,
          deviceIdentifier: true,
          platform: true,
          status: true,
          lastSeenAt: true,
        },
      },
      safeZones: {
        where: { isActive: true },
      },
      _count: {
        select: {
          devices: true,
          safeZones: true,
        },
      },
    },
  })
}

const getChildById = async ({ id, user }) => {
  const child = await prisma.childProfile.findUnique({
    where: { id },
    include: {
      childUser: {
        select: { id: true, name: true, email: true },
      },
      devices: {
        include: {
          locations: {
            take: 1,
            orderBy: { recordedAt: "desc" },
          },
        },
      },
      safeZones: true,
      pairings: {
        where: { status: "PENDING" },
        take: 1,
        orderBy: { createdAt: "desc" },
      },
    },
  })

  if (!child) {
    throw new AppError("Không tìm thấy hồ sơ trẻ", 404)
  }

  // Ownership verification
  if (user.role === "PARENT" && child.parentId !== user.id) {
    throw new AppError("Bạn không có quyền truy cập hồ sơ này", 403)
  }
  if (user.role === "CHILD" && child.childUserId !== user.id) {
    throw new AppError("Bạn không có quyền truy cập hồ sơ này", 403)
  }

  return child
}

const updateChild = async ({ id, user, data }) => {
  const child = await prisma.childProfile.findUnique({ where: { id } })
  if (!child) {
    throw new AppError("Không tìm thấy hồ sơ trẻ", 404)
  }

  if (user.role === "PARENT" && child.parentId !== user.id) {
    throw new AppError("Bạn không có quyền chỉnh sửa hồ sơ này", 403)
  }

  const updateData = {}
  if (data.name !== undefined) updateData.name = data.name
  if (data.dateOfBirth !== undefined) {
    updateData.dateOfBirth = data.dateOfBirth ? new Date(data.dateOfBirth) : null
  }
  if (data.avatarUrl !== undefined) updateData.avatarUrl = data.avatarUrl || null
  if (data.notes !== undefined) updateData.notes = data.notes || null
  if (data.isActive !== undefined) updateData.isActive = data.isActive

  if (data.childEmail !== undefined) {
    if (data.childEmail && data.childEmail.trim().length > 0) {
      const childUser = await prisma.user.findUnique({
        where: { email: data.childEmail.trim().toLowerCase() },
      })
      if (!childUser) {
        throw new AppError("Không tìm thấy tài khoản con với email này", 404)
      }
      updateData.childUserId = childUser.id
    } else {
      updateData.childUserId = null
    }
  }

  return prisma.childProfile.update({
    where: { id },
    data: updateData,
    include: {
      childUser: {
        select: { id: true, name: true, email: true },
      },
      devices: true,
      safeZones: true,
    },
  })
}

const deleteChild = async ({ id, user }) => {
  const child = await prisma.childProfile.findUnique({ where: { id } })
  if (!child) {
    throw new AppError("Không tìm thấy hồ sơ trẻ", 404)
  }

  if (user.role === "PARENT" && child.parentId !== user.id) {
    throw new AppError("Bạn không có quyền xóa hồ sơ này", 403)
  }

  await prisma.childProfile.delete({
    where: { id },
  })

  return { message: "Xóa hồ sơ trẻ thành công" }
}

module.exports = {
  createChild,
  getChildren,
  getChildById,
  updateChild,
  deleteChild,
}
