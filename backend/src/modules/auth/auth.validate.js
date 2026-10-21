
const { z } = require("zod");

const registerBodySchema = z.object({
  name: z.string().trim().min(2).max(50),
  email: z.email().trim().toLowerCase(),
  phone: z.string().min(10).optional(),
  password: z.string().min(6),
});

const loginBodySchema = z.object({
  email: z.email().trim().toLowerCase(),
  password: z.string().min(6),
});

const verifyOtpBodySchema = z.object({
  email: z.email().trim().toLowerCase(),
  otp: z.string().regex(/^\d{6}$/, "OTP phải gồm 6 chữ số"),
});

const changePasswordBodySchema = z.object({
  oldPassword: z.string().min(6),
  newPassword: z.string().min(6, "Mật khẩu phải có ít nhất 6 ký tự"),
});

const resetPasswordBodySchema = z.object({
  resetToken: z.string().min(1),
  newPassword: z.string().min(6, "Mật khẩu phải có ít nhất 6 ký tự"),
});

const registerSchema = z.object({
  body: registerBodySchema,
});

const loginSchema = z.object({
  body: loginBodySchema,
});

const verifyRegisterOtpSchema = z.object({
  body: verifyOtpBodySchema,
});

const verifyLoginOtpSchema = z.object({
  body: verifyOtpBodySchema,
});

const changePasswordSchema = z.object({
  body: changePasswordBodySchema,
});

const resetPasswordSchema = z.object({
  body: resetPasswordBodySchema,
});

module.exports = {
  registerSchema,
  loginSchema,
  verifyRegisterOtpSchema,
  verifyLoginOtpSchema,
  changePasswordSchema,
  resetPasswordSchema,
};
