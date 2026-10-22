const prisma = require("../../lib/prisma")
const jwt = require("jsonwebtoken")
const bcrypt = require("bcryptjs")
const crypto = require("crypto")
const AppError = require("../../errors/AppError")
const { sendOtpEmail } = require("../../utils/email")

const register = async ({ name, email, phone, password }) => {
  const normalizedEmail = email.trim().toLowerCase()

  const existingUser = await prisma.user.findUnique({
    where: { email: normalizedEmail },
  })

  if (existingUser?.emailVerified) {
    throw new AppError("Email đã được đăng ký", 409)
  }

  const hashPassword = await bcrypt.hash(password, 10)

  // Tài khoản chưa được xác minh email
  const user = existingUser
    ? await prisma.user.update({
        where: { id: existingUser.id },
        data: {
          name,
          phone,
          password: hashPassword,
          isActive: true,
        },
      })
    : await prisma.user.create({
        data: {
          name,
          email: normalizedEmail,
          phone,
          password: hashPassword,
          emailVerified: false,
        },
      })

  await createAndSendOtp({
    email: normalizedEmail,
    purpose: "REGISTER",
    userId: user.id,
  })

  return {
    message: "OTP xác minh đã được gửi đến email",
    email: normalizedEmail,
  }
}

const login = async ({ email, password }) => {
  const normalizedEmail = email.trim().toLowerCase()

  const user = await prisma.user.findUnique({
    where: { email: normalizedEmail },
  })

  if (!user || !(await bcrypt.compare(password, user.password))) {
    throw new AppError("Email hoặc password không hợp lệ", 401)
  }

  if (!user.emailVerified) {
    throw new AppError("Vui lòng xác minh email trước khi đăng nhập", 403)
  }

  if (!user.isActive) {
    throw new AppError("Tài khoản đã bị vô hiệu hóa", 403)
  }

  await createAndSendOtp({
    email: normalizedEmail,
    purpose: "LOGIN",
    userId: user.id,
  })

  return {
    message: "OTP đăng nhập đã được gửi đến email",
    email: normalizedEmail,
  }
}

const refreshToken = async (refreshToken) => {
  let decoded

  try {
    decoded = jwt.verify(refreshToken, process.env.REFRESH_TOKEN_SECRET)
  } catch {
    throw new AppError("Refresh token không hợp lệ", 401)
  }

  const storedToken = await prisma.refreshToken.findUnique({
    where: {
      refreshToken,
    },
  })

  if (!storedToken) {
    throw new AppError("Refresh token không hợp lệ", 401)
  }

  if (storedToken.expiresAt < new Date()) {
    await prisma.refreshToken.delete({
      where: {
        refreshToken,
      },
    })
    throw new AppError("Refresh token không hợp lệ", 401)
  }

  const user = await prisma.user.findUnique({
    where: {
      id: decoded.id,
    },
  })
  if (!user) {
    throw new AppError("Refresh token không hợp lệ", 401)
  }
  return generateAccessToken(user)
}
const logout = async (refreshToken) => {
  return prisma.refreshToken.delete({
    where: {
      refreshToken,
    },
  })
}
const changePassword = async ({ userId, oldPassword, newPassword }) => {
  const user = await prisma.user.findUnique({
    where: {
      id: userId,
    },
  })
  if (!user) {
    throw new AppError("User không tồn tại", 404)
  }

  const isMatch = await bcrypt.compare(oldPassword, user.password)
  if (!isMatch) {
    throw new AppError("Mật khẩu cũ không đúng", 400)
  }
  const isSame = await bcrypt.compare(newPassword, user.password)
  if (isSame) {
    throw new AppError("Mật khẩu mới phải khác mật khẩu cũ", 400)
  }
  const hashPassword = await bcrypt.hash(newPassword, 10)

  await prisma.$transaction([
    prisma.refreshToken.deleteMany({
      where: {
        userId,
      },
    }),
    prisma.user.update({
      data: {
        password: hashPassword,
      },
      where: {
        id: userId,
      },
    }),
  ])
}

const generateAccessToken = (user) => {
  return jwt.sign(
    {
      id: user.id,
      name: user.name,
      role: user.role,
    },
    process.env.ACCESS_TOKEN_SECRET,
    {
      expiresIn: "1d",
    },
  )
}

const generateRefreshToken = (user) => {
  return jwt.sign(
    {
      id: user.id,
    },
    process.env.REFRESH_TOKEN_SECRET,
    {
      expiresIn: "7d",
    },
  )
}
const verifyAccessToken = (token) => {
  try {
    return jwt.verify(token, process.env.ACCESS_TOKEN_SECRET)
  } catch {
    throw new AppError("Unauthorized", 401)
  }
}

const resetPassword = async ({ resetToken, newPassword }) => {
  let decoded
  try {
    decoded = jwt.verify(resetToken, process.env.ACCESS_TOKEN_SECRET)
  } catch {
    throw new AppError("Reset token không hợp lệ hoặc hết hạn", 401)
  }

  if (!decoded.reset) {
    throw new AppError("Token không hợp lệ", 401)
  }

  const hashPassword = await bcrypt.hash(newPassword, 10)
  await prisma.user.update({
    where: { id: decoded.id },
    data: { password: hashPassword },
  })
}

const generateOtp = () => crypto.randomInt(100000, 1000000).toString()

const createAndSendOtp = async ({ email, purpose, userId }) => {
  const otp = generateOtp()
  const codeHash = await bcrypt.hash(otp, 10)

  // Vô hiệu hóa OTP cũ chưa sử dụng cùng mục đích
  await prisma.otpVerification.updateMany({
    where: {
      email,
      purpose,
      consumedAt: null,
    },
    data: {
      consumedAt: new Date(),
    },
  })

  await prisma.otpVerification.create({
    data: {
      email,
      purpose,
      codeHash,
      expiresAt: new Date(Date.now() + 5 * 60 * 1000),
      userId: userId || null,
    },
  })

  // Chỉ trả thành công khi email được gửi
  await sendOtpEmail(email, otp, purpose)
}

const verifyOtpRecord = async ({ email, otp, purpose }) => {
  const record = await prisma.otpVerification.findFirst({
    where: {
      email,
      purpose,
      consumedAt: null,
    },
    orderBy: {
      createdAt: "desc",
    },
  })

  if (!record) {
    throw new AppError("OTP không tồn tại hoặc đã được sử dụng", 400)
  }

  if (record.expiresAt <= new Date()) {
    throw new AppError("OTP đã hết hạn", 400)
  }

  if (record.attempts >= 5) {
    throw new AppError("Bạn đã nhập sai OTP quá số lần cho phép", 429)
  }

  const isMatch = await bcrypt.compare(otp, record.codeHash)

  if (!isMatch) {
    await prisma.otpVerification.update({
      where: { id: record.id },
      data: { attempts: { increment: 1 } },
    })

    throw new AppError("OTP không chính xác", 400)
  }

  return record
}

const verifyRegisterOtp = async ({ email, otp }) => {
  const normalizedEmail = email.trim().toLowerCase()

  const record = await verifyOtpRecord({
    email: normalizedEmail,
    otp,
    purpose: "REGISTER",
  })

  if (!record.userId) {
    throw new AppError("OTP không hợp lệ", 400)
  }

  const user = await prisma.user.findUnique({
    where: { id: record.userId },
  })

  if (!user) {
    throw new AppError("Tài khoản không tồn tại", 404)
  }

  await prisma.$transaction([
    prisma.otpVerification.update({
      where: { id: record.id },
      data: { consumedAt: new Date() },
    }),
    prisma.user.update({
      where: { id: user.id },
      data: { emailVerified: true },
    }),
  ])

  return {
    message: "Xác minh email thành công",
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
    },
  }
}

const verifyLoginOtp = async ({ email, otp }) => {
  const normalizedEmail = email.trim().toLowerCase()

  const record = await verifyOtpRecord({
    email: normalizedEmail,
    otp,
    purpose: "LOGIN",
  })

  if (!record.userId) {
    throw new AppError("OTP không hợp lệ", 400)
  }

  const user = await prisma.user.findUnique({
    where: { id: record.userId },
  })

  if (!user || !user.isActive || !user.emailVerified) {
    throw new AppError("Tài khoản không hợp lệ", 401)
  }

  // Đánh dấu OTP đã sử dụng trước khi trả token
  await prisma.otpVerification.update({
    where: { id: record.id },
    data: { consumedAt: new Date() },
  })

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
  register,
  verifyRegisterOtp,
  login,
  verifyLoginOtp,
  logout,
  refreshToken,
  changePassword,
  generateAccessToken,
  generateRefreshToken,
  verifyAccessToken,
  resetPassword,
}
