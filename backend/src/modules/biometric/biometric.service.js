const jwt = require("jsonwebtoken")
const prisma = require("../../lib/prisma")
const AppError = require("../../errors/AppError")
const { generateAccessToken, generateRefreshToken } = require("../auth/auth.service")

const getBiometricStatus = async (userId) => {
  const setting = await prisma.biometricSetting.findUnique({
    where: { userId },
  })

  return {
    enabled: setting ? setting.enabled : false,
    method: setting?.method || "BIOMETRIC",
  }
}

const enableBiometric = async (user) => {
  await prisma.biometricSetting.upsert({
    where: { userId: user.id },
    create: {
      userId: user.id,
      enabled: true,
      method: "BIOMETRIC",
    },
    update: {
      enabled: true,
      method: "BIOMETRIC",
    },
  })

  const biometricToken = jwt.sign(
    {
      id: user.id,
      type: "biometric_auth",
    },
    process.env.ACCESS_TOKEN_SECRET,
    {
      expiresIn: "180d",
    }
  )

  return {
    enabled: true,
    biometricToken,
    message: "Kích hoạt xác thực sinh trắc học/vân tay thành công",
  }
}

const disableBiometric = async (userId) => {
  await prisma.biometricSetting.updateMany({
    where: { userId },
    data: { enabled: false },
  })

  return {
    enabled: false,
    message: "Hủy kích hoạt xác thực sinh trắc học thành công",
  }
}

const biometricLogin = async ({ biometricToken }) => {
  let decoded
  try {
    decoded = jwt.verify(biometricToken, process.env.ACCESS_TOKEN_SECRET)
  } catch {
    throw new AppError("Mã xác thực sinh trắc học không hợp lệ hoặc đã hết hạn", 401)
  }

  if (decoded.type !== "biometric_auth") {
    throw new AppError("Token không hợp lệ cho xác thực sinh trắc học", 401)
  }

  const setting = await prisma.biometricSetting.findUnique({
    where: { userId: decoded.id },
  })

  if (!setting || !setting.enabled) {
    throw new AppError("Xác thực sinh trắc học chưa được bật trên tài khoản này", 401)
  }

  const user = await prisma.user.findUnique({
    where: { id: decoded.id },
  })

  if (!user || !user.isActive || !user.emailVerified) {
    throw new AppError("Tài khoản không hợp lệ hoặc đã bị khóa", 401)
  }

  const accessToken = generateAccessToken(user)
  const refreshTokenValue = generateRefreshToken(user)

  await prisma.refreshToken.create({
    data: {
      refreshToken: refreshTokenValue,
      userId: user.id,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    },
  })

  return {
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
    },
    accessToken,
    refreshToken: refreshTokenValue,
  }
}

module.exports = {
  getBiometricStatus,
  enableBiometric,
  disableBiometric,
  biometricLogin,
}
