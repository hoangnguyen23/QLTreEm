const express = require("express")
const router = express.Router()
const asyncHandler = require("../../utils/asyncHandler")
const authenticate = require("../../middlewares/auth.middleware")
const validate = require("../../middlewares/validation.middleware")
const { register, login, logout, refreshToken, changePassword, resetPassword, verifyRegisterOtp, verifyLoginOtp } = require("./auth.controller")
const { registerSchema, loginSchema, changePasswordSchema, resetPasswordSchema, verifyRegisterOtpSchema, verifyLoginOtpSchema } = require("./auth.validate")


router.post("/register", validate(registerSchema), asyncHandler(register))
router.post("/register/verify-otp", validate(verifyRegisterOtpSchema), asyncHandler(verifyRegisterOtp))
router.post("/login", validate(loginSchema), asyncHandler(login))
router.post("/login/verify-otp", validate(verifyLoginOtpSchema), asyncHandler(verifyLoginOtp))
router.post("/logout", asyncHandler(logout))
router.post("/refresh-token", asyncHandler(refreshToken))
router.patch("/change-password", authenticate, validate(changePasswordSchema), asyncHandler(changePassword))
router.post("/reset-password", validate(resetPasswordSchema), asyncHandler(resetPassword))

module.exports = router
