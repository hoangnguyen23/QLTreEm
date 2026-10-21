const AppError = require("../../errors/AppError")
const authService = require("./auth.service")

const register = async (req, res) => {
  const result = await authService.register(req.body)
  res.status(200).json({
    success: true,
    data: result,
  })
}
const login = async (req, res) => {
  const result = await authService.login(req.body)
  const { refreshToken, ...data } = result
  res.cookie("refreshToken", refreshToken, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: process.env.NODE_ENV === "production" ? "none" : "lax",
    maxAge: 7 * 24 * 60 * 60 * 1000,
  })
  res.status(200).json({
    success: true,
    data,
  })
}
const logout = async (req, res) => {
  const refreshToken = req.cookies.refreshToken
  if (!refreshToken) {
    throw new AppError("RefreshToken is required", 400)
  }
  await authService.logout(refreshToken)
  res.clearCookie("refreshToken", {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: process.env.NODE_ENV === "production" ? "none" : "lax",
  })
  res.status(200).json({
    success: true,
    message: "Đăng xuất thành công",
  })
}
const refreshToken = async (req, res) => {
  const refreshToken = req.cookies.refreshToken
  if (!refreshToken) {
    throw new AppError("RefreshToken is required", 400)
  }
  const result = await authService.refreshToken(refreshToken)
  res.status(200).json({
    success: true,
    data: result,
  })
}
const changePassword = async (req, res) => {
  await authService.changePassword({
    userId: req.user.id,
    oldPassword: req.body.oldPassword,
    newPassword: req.body.newPassword,
  })
  res.status(200).json({
    success: true,
    message: "Thay đổi password thành công",
  })
}

const resetPassword = async (req, res) => {
  await authService.resetPassword(req.body)
  res.status(200).json({
    success: true,
    message: "Đặt lại mật khẩu thành công",
  })
}

const verifyRegisterOtp = async (req, res, next) => {
    const result = await authService.verifyRegisterOtp(req.body);
    res.status(200).json({ success: true, data: result });
};

const verifyLoginOtp = async (req, res, next) => {
    const result = await authService.verifyLoginOtp(req.body);
    res.status(200).json({ success: true, data: result });
};
module.exports = {
  register,
  login,
  logout,
  refreshToken,
  changePassword,
  resetPassword,
  verifyRegisterOtp,
  verifyLoginOtp,
}
